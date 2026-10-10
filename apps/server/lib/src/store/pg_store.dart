/// Postgres 实现（03 文档 §4.4 表结构）。
///
/// - `sync_ops`：全局 BIGSERIAL 序号的追加日志，payload 为 op JSON
///   （明文 PoC 模式；E2EE 时改 BYTEA 密文，S08 落地）。
/// - `entity_lamport`：字段裁决表，用 ON CONFLICT ... WHERE 的原子
///   行比较实现"高 (lamport, origin) 胜出"，多实例安全。
///
/// 表结构由本类幂等创建（PoC 便捷）；正式迁移走 dbmate（S05）。
library;

import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';

import 'sync_store.dart';

final class PgSyncStore implements SyncStore {
  PgSyncStore._(this._conn);

  final Connection _conn;

  /// 从 `postgres://user:pass@host:port/db` 打开并确保表存在。
  /// 本地开发（localhost/127.0.0.1）自动关闭 SSL；生产必须 TLS。
  static Future<PgSyncStore> open(String databaseUrl) async {
    final uri = Uri.parse(databaseUrl);
    final userInfo = uri.userInfo.split(':');
    final isLocal = uri.host == 'localhost' || uri.host == '127.0.0.1';
    final conn = await Connection.open(
      Endpoint(
        host: uri.host,
        port: uri.port == 0 ? 5432 : uri.port,
        database: uri.path.replaceFirst('/', ''),
        username: userInfo.first,
        password: userInfo.length > 1 ? userInfo[1] : null,
      ),
      settings: ConnectionSettings(
        sslMode: isLocal ? SslMode.disable : SslMode.require,
      ),
    );
    await _migrate(conn);
    return PgSyncStore._(conn);
  }

  static Future<void> _migrate(Connection c) async {
    await c.execute('''
      CREATE TABLE IF NOT EXISTS sync_ops (
        seq BIGSERIAL PRIMARY KEY,
        device_id TEXT NOT NULL,
        lamport BIGINT NOT NULL,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        field TEXT NOT NULL,
        op TEXT NOT NULL,
        payload JSONB NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    ''');
    await c.execute('''
      CREATE TABLE IF NOT EXISTS entity_lamport (
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        field TEXT NOT NULL,
        lamport BIGINT NOT NULL,
        origin TEXT NOT NULL,
        PRIMARY KEY (entity, entity_id, field)
      )
    ''');
  }

  @override
  Future<PushResponse> push(PushRequest req) async {
    final results = <PushOpResult>[];
    var lastSeq = 0;
    if (req.ops.isEmpty) {
      // 空批量返回当前全局序号(与 MemorySyncStore 语义一致,
      // 调用方不会把游标重置回 0 触发全量重拉)。
      final rows = await _conn.execute(
        Sql.named('SELECT COALESCE(MAX(seq), 0) FROM sync_ops'),
      );
      return PushResponse(serverSeq: rows[0][0] as int, results: results);
    }
    await _conn.runTx((session) async {
      for (final op in req.ops) {
        final ins = await session.execute(
          Sql.named(
            'INSERT INTO sync_ops (device_id, lamport, entity, entity_id, field, op, payload) '
            'VALUES (@d, @l, @e, @eid, @f, @o, @p:jsonb) RETURNING seq',
          ),
          parameters: {
            'd': op.deviceId,
            'l': op.lamport,
            'e': op.entity,
            'eid': op.entityId,
            'f': op.field,
            'o': syncOpTypeToJson(op.type),
            'p': jsonEncode(op.toJson()),
          },
        );
        lastSeq = ins[0][0] as int;
        final adj = await session.execute(
          Sql.named(
            'INSERT INTO entity_lamport (entity, entity_id, field, lamport, origin) '
            'VALUES (@e, @eid, @f, @l, @d) '
            'ON CONFLICT (entity, entity_id, field) DO UPDATE '
            'SET lamport = EXCLUDED.lamport, origin = EXCLUDED.origin '
            'WHERE (EXCLUDED.lamport, EXCLUDED.origin) '
            '      >= (entity_lamport.lamport, entity_lamport.origin) '
            'RETURNING lamport, origin',
          ),
          parameters: {
            'e': op.entity,
            'eid': op.entityId,
            'f': op.field,
            'l': op.lamport,
            'd': op.deviceId,
          },
        );
        // 空结果 = 与既有更高裁决值冲突（stale）→ 拒绝；否则返回行即为本 op。
        results.add(
          PushOpResult(index: results.length, accepted: adj.isNotEmpty),
        );
      }
    });
    return PushResponse(serverSeq: lastSeq, results: results);
  }

  @override
  Future<PullResponse> pull({required int since, required int limit}) async {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', '≥1');
    }
    final rows = await _conn.execute(
      Sql.named(
        'SELECT seq, payload FROM sync_ops WHERE seq > @s ORDER BY seq LIMIT @l',
      ),
      parameters: {'s': since, 'l': limit + 1},
    );
    final hasMore = rows.length > limit;
    var cursor = since;
    final ops = <SyncOp>[];
    for (final row in rows.take(limit)) {
      final seq = row[0] as int;
      cursor = seq;
      // postgres 包默认把 JSONB 作为 text 返回，兼容两种形态。
      final payload = row[1];
      final json = payload is Map
          ? payload.cast<String, Object?>()
          : (jsonDecode(payload as String) as Map).cast<String, Object?>();
      ops.add(SyncOp.fromJson(json));
    }
    return PullResponse(cursor: cursor, ops: ops, hasMore: hasMore);
  }

  @override
  Future<void> close() => _conn.close();

  /// 清空 PoC 表（仅测试用：共享开发库上保证用例可重复）。
  @visibleForTesting
  Future<void> resetForTest() async {
    await _conn.execute('DELETE FROM sync_ops');
    await _conn.execute('DELETE FROM entity_lamport');
  }
}
