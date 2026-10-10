/// 设备鉴权消息与常量（R1 §2/§3/§4）：
/// 挑战 `GET /v1/auth/challenge?device_id=X`、鉴权头 `X-Agendum-Auth`。
///
/// 流程：客户端先取一次性 nonce（服务端挑战表随部署形态：单实例内存表 /
/// PG 共享表，≤5 分钟 TTL，ADR-016 §1），
/// 之后 push/pull/envelope 一律携带
/// `X-Agendum-Auth: v1 <device_id> <nonce_b64> <sig_b64>`，sig 为设备
/// Ed25519 私钥对 [authSignatureMessage] 的签名。服务端校验 nonce 未用过 +
/// 用注册公钥验签 + 请求 uid 与注册 uid 一致，任一不满足 401；验证通过后
/// nonce 立即作废。
library;

import 'dart:convert';

/// 鉴权头名（R1 §4，push/pull/envelope 一律要求）。
const String authHeaderName = 'X-Agendum-Auth';

/// 鉴权头 scheme（R1 §4 首段，当前固定 v1）。
const String authHeaderScheme = 'v1';

/// 注册签名原文前缀（R1 §3）。
const String registerSignaturePrefix = 'agendum/register:';

/// 鉴权签名原文前缀（R1 §4）。
const String authSignaturePrefix = 'agendum/auth:';

/// 注册验签原文（R1 §3）：`agendum/register:` + fingerprint。
String registerSignatureMessage(String fingerprint) =>
    '$registerSignaturePrefix$fingerprint';

/// 鉴权验签原文（R1 §4）：`agendum/auth:` + device_id + ':' + nonce_b64。
String authSignatureMessage(String deviceId, String nonceB64) =>
    '$authSignaturePrefix$deviceId:$nonceB64';

/// 组装鉴权头：`v1 <device_id> <nonce_b64> <sig_b64>`（R1 §4）。
String buildAuthHeader({
  required String deviceId,
  required String nonceB64,
  required String sigB64,
}) => '$authHeaderScheme $deviceId $nonceB64 $sigB64';

/// 鉴权头解析结果（三段凭证，scheme 校验通过后返回）。
class AuthCredentials {
  const AuthCredentials({
    required this.deviceId,
    required this.nonceB64,
    required this.sigB64,
  });

  final String deviceId;

  /// 一次性挑战 nonce（base64），验证通过即作废。
  final String nonceB64;

  /// Ed25519 签名（base64），原文见 [authSignatureMessage]。
  final String sigB64;
}

/// 解析鉴权头；scheme 非 [authHeaderScheme] 或段数不对抛 FormatException。
AuthCredentials parseAuthHeader(String header) {
  final parts = header.trim().split(RegExp(r'\s+'));
  if (parts.length != 4 || parts[0] != authHeaderScheme) {
    throw const FormatException('鉴权头格式非法');
  }
  final (deviceId, nonceB64, sigB64) = (parts[1], parts[2], parts[3]);
  if (deviceId.isEmpty || nonceB64.isEmpty || sigB64.isEmpty) {
    throw const FormatException('鉴权头格式非法');
  }
  return AuthCredentials(
    deviceId: deviceId,
    nonceB64: nonceB64,
    sigB64: sigB64,
  );
}

/// 挑战响应（R1 §2）：`GET /v1/auth/challenge?device_id=X`。
class AuthChallenge {
  const AuthChallenge({required this.nonceB64, required this.expiresAtMs});

  /// 一次性 nonce（32 字节的 base64，R1 §2），验证通过即作废。
  final String nonceB64;

  /// 过期时间（epoch ms）：服务端 TTL ≤5 分钟。
  final int expiresAtMs;

  Map<String, Object?> toJson() => {
    'nonce': nonceB64,
    'expires_at_ms': expiresAtMs,
  };

  factory AuthChallenge.fromJson(Map<String, Object?> json) {
    final nonce = json['nonce'];
    final expiresAt = json['expires_at_ms'];
    if (nonce is! String || nonce.isEmpty) {
      throw const FormatException('challenge.nonce 缺失或非法');
    }
    if (expiresAt is! int) {
      throw const FormatException('challenge.expires_at_ms 缺失或非法');
    }
    final bytes = base64Decode(nonce); // 非法 base64 直接抛 FormatException
    if (bytes.length != 32) {
      throw const FormatException('challenge.nonce 必须是 32 字节的 base64');
    }
    return AuthChallenge(nonceB64: nonce, expiresAtMs: expiresAt);
  }
}
