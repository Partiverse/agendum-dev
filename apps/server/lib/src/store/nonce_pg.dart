/// nonce 的 Postgres 共享存储（ADR-016 §1）：PG 部署（DATABASE_URL，多实例）
/// 下的一次性挑战表。
///
/// 内存 [NonceTable](../auth.dart) 的单次有效只在单进程成立；负载均衡把
/// 挑战与鉴权请求分散到多个实例时，重放可在「没见过该 nonce」的实例上
/// 得逞。本实现把 nonce 落共享表：
/// - 唯一约束：`nonce TEXT PRIMARY KEY`（32 字节随机，冲突即拒绝）；
/// - TTL：`expires_at` 由 **DB 时钟**计算与校验（免实例间时钟漂移），
///   签发时惰性清扫过期行（与内存表同策略）；
/// - 单次消费：`DELETE … RETURNING` 一条语句原子完成——两实例并发消费
///   同一 nonce 至多一行删除成功，红线 2「不可重放」在多实例部署成立。
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';

import '../auth.dart';

/// auth_nonces 共享表的 nonce 存储（ADR-016 §1）。
final class PgNonceStore implements NonceStore {
  PgNonceStore._(this._conn, this._random);

  final Connection _conn;
  final Random _random;

  /// 从 `postgres://user:pass@host:port/db` 打开并确保表存在。
  /// 本地开发（localhost/127.0.0.1）自动关闭 SSL；生产必须 TLS。
  static Future<PgNonceStore> open(String databaseUrl, {Random? random}) async {
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
    return PgNonceStore._(conn, random ?? Random.secure());
  }

  static Future<void> _migrate(Connection c) async {
    await c.execute('''
      CREATE TABLE IF NOT EXISTS auth_nonces (
        nonce TEXT PRIMARY KEY,
        expires_at TIMESTAMPTZ NOT NULL
      )
    ''');
  }

  @override
  Future<AuthChallenge> issue() async {
    // 惰性清扫过期项（与内存表同策略：签发时顺带清）。
    await _conn.execute('DELETE FROM auth_nonces WHERE expires_at < now()');
    final bytes = Uint8List(nonceBytes);
    for (var i = 0; i < nonceBytes; i++) {
      bytes[i] = _random.nextInt(256);
    }
    final nonceB64 = base64Encode(bytes);
    final rows = await _conn.execute(
      Sql.named(
        'INSERT INTO auth_nonces (nonce, expires_at) '
        "VALUES (@n, now() + @ttl * interval '1 second') "
        'ON CONFLICT (nonce) DO NOTHING '
        'RETURNING expires_at',
      ),
      parameters: {'n': nonceB64, 'ttl': nonceTtl.inSeconds},
    );
    if (rows.isEmpty) {
      // 32 字节随机 nonce 撞上存活 nonce：概率 ~2^-256，工程上即故障。
      throw StateError('auth_nonces 主键冲突（nonce 撞车）');
    }
    final expiresAt = rows[0][0] as DateTime;
    return AuthChallenge(
      nonceB64: nonceB64,
      expiresAtMs: expiresAt.millisecondsSinceEpoch,
    );
  }

  @override
  Future<bool> consume(String nonceB64) async {
    final rows = await _conn.execute(
      Sql.named(
        'DELETE FROM auth_nonces '
        'WHERE nonce = @n AND expires_at >= now() '
        'RETURNING nonce',
      ),
      parameters: {'n': nonceB64},
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> close() => _conn.close();

  /// 把 nonce 的过期时刻拨到过去（仅测试用：确定性验证 TTL 拒绝路径）。
  @visibleForTesting
  Future<void> expireForTest(String nonceB64) async {
    await _conn.execute(
      Sql.named(
        "UPDATE auth_nonces SET expires_at = now() - interval '1 second' "
        'WHERE nonce = @n',
      ),
      parameters: {'n': nonceB64},
    );
  }

  /// 清空 PoC 表（仅测试用：共享开发库上保证用例可重复）。
  @visibleForTesting
  Future<void> resetForTest() async {
    await _conn.execute('DELETE FROM auth_nonces');
  }
}
