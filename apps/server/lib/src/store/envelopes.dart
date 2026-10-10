/// 多设备信封存储（R1 §6）：`/v1/vault/envelope` 的不透明后端。
///
/// 服务端只存 KEK 加密后的 MK 信封（base64 密文,不可解）——每个 uid 保留
/// 最新一条,第二台设备凭恢复短语解锁后经此接密钥（蓝图 R1-5）。
/// 读写都经鉴权中间件限定在本 uid 设备（handler 层校验）。
library;

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';

abstract interface class VaultEnvelopeStore {
  /// 覆盖写：同 uid 每次上传替换为最新一条。
  Future<void> put(VaultEnvelope envelope);

  /// 返回该 uid 当前最新一条；从未上传过返回 null。
  Future<VaultEnvelope?> latest(String uid);

  Future<void> close();
}

final class MemoryVaultEnvelopeStore implements VaultEnvelopeStore {
  final Map<String, VaultEnvelope> _byUid = {};

  @override
  Future<void> put(VaultEnvelope envelope) async =>
      _byUid[envelope.uid] = envelope;

  @override
  Future<VaultEnvelope?> latest(String uid) async => _byUid[uid];

  @override
  Future<void> close() async {}
}

/// Postgres 实现：`vault_envelopes` 追加式存储,按 (uid, seq) 取最新。
final class PgVaultEnvelopeStore implements VaultEnvelopeStore {
  PgVaultEnvelopeStore._(this._conn);

  final Connection _conn;

  static Future<PgVaultEnvelopeStore> open(String databaseUrl) async {
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
    return PgVaultEnvelopeStore._(conn);
  }

  static Future<void> _migrate(Connection c) async {
    await c.execute('''
      CREATE TABLE IF NOT EXISTS vault_envelopes (
        seq BIGSERIAL PRIMARY KEY,
        uid TEXT NOT NULL,
        device_id TEXT NOT NULL,
        envelope_b64 TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    ''');
    await c.execute(
      'CREATE INDEX IF NOT EXISTS vault_envelopes_uid_seq_idx '
      'ON vault_envelopes (uid, seq)',
    );
  }

  @override
  Future<void> put(VaultEnvelope envelope) async {
    await _conn.execute(
      Sql.named(
        'INSERT INTO vault_envelopes (uid, device_id, envelope_b64) '
        'VALUES (@u, @d, @e)',
      ),
      parameters: {
        'u': envelope.uid,
        'd': envelope.deviceId,
        'e': envelope.envelopeB64,
      },
    );
  }

  @override
  Future<VaultEnvelope?> latest(String uid) async {
    final rows = await _conn.execute(
      Sql.named(
        'SELECT uid, device_id, envelope_b64 FROM vault_envelopes '
        'WHERE uid = @u ORDER BY seq DESC LIMIT 1',
      ),
      parameters: {'u': uid},
    );
    if (rows.isEmpty) return null;
    return VaultEnvelope(
      uid: rows[0][0] as String,
      deviceId: rows[0][1] as String,
      envelopeB64: rows[0][2] as String,
    );
  }

  @override
  Future<void> close() => _conn.close();

  /// 清空 PoC 表（仅测试用：共享开发库上保证用例可重复）。
  @visibleForTesting
  Future<void> resetForTest() async {
    await _conn.execute('DELETE FROM vault_envelopes');
  }
}
