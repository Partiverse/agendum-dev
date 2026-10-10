/// 设备注册消息（03 文档 §6.1；S07「设备注册带密钥指纹」；R1 §3 扩展）：
/// `POST /v1/devices/register`。
///
/// 服务端只存 deviceId ↔ 公钥/指纹/uid 的绑定与首见时间，用于：
/// - 多设备指纹核对（用户肉眼比对，防中间替换）；
/// - 后续设备轮换/吊销的锚点（Phase 2 账号体系接管）；
/// - R1 租户隔离：device 绑定到 uid，鉴权时请求 uid 必须与注册 uid 一致。
/// 密钥材料之外的一切（口令、MK、信封）不经此端点 —— 信封走
/// `/v1/vault/envelope`（R1 §6）。
library;

import 'dart:convert';

/// 设备密钥算法标识（当前仅 ed25519）。
const String deviceKeyAlgorithm = 'ed25519';

/// 注册归属证明 `uid_proof` 的字节数（ADR-016 §6：HKDF 输出 32 字节）。
const int uidProofBytes = 32;

class DeviceRegistrationRequest {
  const DeviceRegistrationRequest({
    required this.deviceId,
    required this.algorithm,
    required this.publicKeyB64,
    required this.fingerprint,
    required this.uid,
    required this.pubkeyB64,
    required this.sigB64,
    this.uidProofB64,
  });

  final String deviceId;
  final String algorithm;

  /// Ed25519 公钥原始字节（32B）的 base64（03 文档 §6.1 既有字段，语义不变）。
  final String publicKeyB64;

  /// 密钥指纹（客户端按 SHA-256(公钥) 前 16 字节 8 组 × 4 hex 展示）。
  final String fingerprint;

  /// 租户标识（R1 §3）：由 Vault 主密钥派生，明文开发模式固定 'dev-plain'；
  /// 服务端绑 device→uid。对协议层是不透明非空字符串，不校验内部格式。
  final String uid;

  /// R1 §3 验签公钥（Ed25519，32B base64，wire `pubkey_b64`）：服务端用它
  /// 验证 [sigB64]，不过 400。
  final String pubkeyB64;

  /// R1 §3 注册签名（Ed25519 设备私钥对 `agendum/register:` + fingerprint
  /// 的签名，base64，wire `sig_b64`）。
  final String sigB64;

  /// 注册归属证明（ADR-016 §6，wire `uid_proof`）：proof = HKDF(MK,
  /// info: 'agendum/uid-proof', 32 字节) 的 base64。服务端验证
  /// uid == hex(HKDF(proof, 'agendum/uid', 16 字节))，不符/缺失 400 ——
  /// 只知 uid 无 proof 无法把设备注册进该租户。明文开发租户
  /// 'dev-plain' 无 Vault，豁免（可为 null）。
  final String? uidProofB64;

  Map<String, Object?> toJson() => {
    'device_id': deviceId,
    'algorithm': algorithm,
    'public_key': publicKeyB64,
    'fingerprint': fingerprint,
    'uid': uid,
    'pubkey_b64': pubkeyB64,
    'sig_b64': sigB64,
    if (uidProofB64 != null) 'uid_proof': uidProofB64,
  };

  factory DeviceRegistrationRequest.fromJson(Map<String, Object?> json) {
    final deviceId = json['device_id'];
    final algorithm = json['algorithm'];
    final publicKey = json['public_key'];
    final fingerprint = json['fingerprint'];
    final uid = json['uid'];
    final pubkey = json['pubkey_b64'];
    final sig = json['sig_b64'];
    if (deviceId is! String || deviceId.isEmpty) {
      throw const FormatException('device_id 缺失或非法');
    }
    if (algorithm is! String || algorithm.isEmpty) {
      throw const FormatException('algorithm 缺失');
    }
    if (publicKey is! String || publicKey.isEmpty) {
      throw const FormatException('public_key 缺失');
    }
    // base64 可解且非空长度
    final keyBytes = base64Decode(publicKey);
    if (keyBytes.isEmpty) {
      throw const FormatException('public_key 不是合法 base64');
    }
    if (fingerprint is! String || fingerprint.isEmpty) {
      throw const FormatException('fingerprint 缺失');
    }
    if (uid is! String || uid.isEmpty) {
      throw const FormatException('uid 缺失');
    }
    if (pubkey is! String || pubkey.isEmpty) {
      throw const FormatException('pubkey_b64 缺失');
    }
    if (base64Decode(pubkey).isEmpty) {
      throw const FormatException('pubkey_b64 不是合法 base64');
    }
    if (sig is! String || sig.isEmpty) {
      throw const FormatException('sig_b64 缺失');
    }
    if (base64Decode(sig).isEmpty) {
      throw const FormatException('sig_b64 不是合法 base64');
    }
    // uid_proof 可选（明文租户豁免）；出现时必须是 32 字节的 base64。
    final uidProof = json['uid_proof'];
    if (uidProof != null) {
      if (uidProof is! String || uidProof.isEmpty) {
        throw const FormatException('uid_proof 不是合法 base64');
      }
      if (base64Decode(uidProof).length != uidProofBytes) {
        throw const FormatException('uid_proof 必须是 32 字节的 base64');
      }
    }
    return DeviceRegistrationRequest(
      deviceId: deviceId,
      algorithm: algorithm,
      publicKeyB64: publicKey,
      fingerprint: fingerprint,
      uid: uid,
      pubkeyB64: pubkey,
      sigB64: sig,
      uidProofB64: uidProof as String?,
    );
  }
}

class DeviceRegistrationResponse {
  const DeviceRegistrationResponse({
    required this.ok,
    required this.deviceId,
    required this.fingerprint,
    required this.created,
    required this.registeredAt,
  });

  final bool ok;
  final String deviceId;
  final String fingerprint;

  /// 是否首次注册（重复注册幂等，返回 created=false）。
  final bool created;

  /// 首见时间（epoch ms，服务端时钟）。
  final int registeredAt;

  Map<String, Object?> toJson() => {
    'ok': ok,
    'device_id': deviceId,
    'fingerprint': fingerprint,
    'created': created,
    'registered_at': registeredAt,
  };
}
