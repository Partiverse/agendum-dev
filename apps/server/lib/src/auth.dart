/// 设备鉴权（R1 §2/§4）：单次 nonce 挑战与 Ed25519 验签。
///
/// 威胁模型：服务端不可信中继之上的请求级身份证明——deviceId 不再是
/// 客户端自报的裸字符串，而是「持有注册私钥」的可验证声明（蓝图 R1-3）。
///
/// nonce 决策（ADR-016 §1）：单次有效，≤5 分钟 TTL；存储随部署形态——
/// 内存 [NonceTable]（单实例/开发）或 [PgNonceStore]（DATABASE_URL 多实例，
/// nonce 落共享表带唯一约束与 TTL，负载均衡下跨实例单次有效）。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:cryptography/cryptography.dart';

/// nonce 有效期（R1 §2：≤5 分钟）。
const Duration nonceTtl = Duration(minutes: 5);

/// nonce 字节数（R1 §2：32 字节）。
const int nonceBytes = 32;

final Ed25519 _ed25519 = Ed25519();

/// nonce 存储抽象（ADR-016 §1）：签发 → 单次消费。
///
/// 挑战/消费语义与部署无关；单次有效（红线 2「不可重放」）要求所有
/// 服务实例共享同一份 nonce 状态——单实例用内存表，多实例（PG 部署）
/// 必须用 [PgNonceStore]。
abstract interface class NonceStore {
  /// 签发一个一次性 nonce（32 字节 base64 + 过期时间）。
  Future<AuthChallenge> issue();

  /// 消费 nonce：存在、未过期且未用过返回 true，并立即作废。
  Future<bool> consume(String nonceB64);

  Future<void> close();
}

/// 内存 nonce 表（单实例/开发部署）：签发 → 单次消费。
/// 过期条目在签发时惰性清扫；重启即失效，客户端重新取挑战即可。
///
/// 仅挑战通过（验签成功）才消费 nonce——签名验证失败的请求不动表，
/// 不影响合法设备的待用挑战。
final class NonceTable implements NonceStore {
  NonceTable({DateTime Function()? now, Random? random})
    : _now = now ?? DateTime.now,
      _random = random ?? Random.secure();

  final DateTime Function() _now;
  final Random _random;

  /// nonce(b64) → 过期时刻。
  final Map<String, DateTime> _nonces = {};

  @override
  Future<AuthChallenge> issue() async {
    _sweep();
    final bytes = Uint8List(nonceBytes);
    for (var i = 0; i < nonceBytes; i++) {
      bytes[i] = _random.nextInt(256);
    }
    final nonceB64 = base64Encode(bytes);
    final expiresAt = _now().add(nonceTtl);
    _nonces[nonceB64] = expiresAt;
    return AuthChallenge(
      nonceB64: nonceB64,
      expiresAtMs: expiresAt.millisecondsSinceEpoch,
    );
  }

  @override
  Future<bool> consume(String nonceB64) async {
    final expiresAt = _nonces.remove(nonceB64);
    if (expiresAt == null) return false;
    return !_now().isAfter(expiresAt);
  }

  @override
  Future<void> close() async {}

  void _sweep() {
    final now = _now();
    _nonces.removeWhere((_, expiresAt) => now.isAfter(expiresAt));
  }
}

/// 用 [publicKeyB64]（Ed25519 公钥，base64）验证 [sigB64] 对 [message] 的签名。
Future<bool> verifyEd25519({
  required List<int> message,
  required String publicKeyB64,
  required String sigB64,
}) async {
  final Uint8List pubBytes;
  final Uint8List sigBytes;
  try {
    pubBytes = base64Decode(publicKeyB64);
    sigBytes = base64Decode(sigB64);
  } on FormatException {
    return false;
  }
  return _ed25519.verify(
    message,
    signature: Signature(
      sigBytes,
      publicKey: SimplePublicKey(pubBytes, type: KeyPairType.ed25519),
    ),
  );
}

/// uid 派生 info（与 packages/e2ee 的 `uidInfo` 同值：ADR-016 §6）。
const String uidDeriveInfo = 'agendum/uid';

final Hkdf _uidHkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 16);

/// 注册准入（ADR-016 §6）：校验 [uidProof]（uid 归属证明，32 字节）对 [uid]
/// 的派生关系——uid 必须等于 hex(HKDF(uid_proof, info: 'agendum/uid', 16 字节))。
///
/// uid 由 MK 两跳派生（proof = HKDF(MK)，uid = HKDF(proof)）：持 MK 者必能
/// 出示 proof；只知 uid（如从服务端 DB 读到）无法反推 proof（HKDF 单向），
/// 注册即被拒——关闭「知悉 uid 即可入租户」的缺口。
/// 本实现与 packages/e2ee 的 `hkdfSha256` 独立同构（互证，同指纹做法）。
Future<bool> verifyUidOwnership({
  required String uid,
  required List<int> uidProof,
}) async {
  if (uid.isEmpty || uidProof.isEmpty) return false;
  final bytes = await (await _uidHkdf.deriveKey(
    secretKey: SecretKey(uidProof),
    info: utf8.encode(uidDeriveInfo),
  )).extractBytes();
  final hex = [
    for (final b in bytes) b.toRadixString(16).padLeft(2, '0'),
  ].join();
  return hex == uid;
}

/// 已通过鉴权的设备上下文（由鉴权中间件写入 `Request.context`），
/// 路由处理器据此做租户一致性校验（请求 uid 必须等于注册 uid）。
class AuthedDevice {
  const AuthedDevice({required this.deviceId, required this.uid});

  final String deviceId;
  final String uid;
}

/// [Request.context] 中存放 [AuthedDevice] 的键。
const String authedDeviceContextKey = 'agendum.auth.device';

/// 从请求上下文取已鉴权设备；未经鉴权中间件的路由返回 null。
AuthedDevice? authedDeviceOf(Map<Object?, Object?> context) =>
    context[authedDeviceContextKey] as AuthedDevice?;
