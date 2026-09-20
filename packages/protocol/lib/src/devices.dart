/// 设备注册消息（03 文档 §6.1；S07「设备注册带密钥指纹」）：
/// `POST /v1/devices/register`。
///
/// 服务端只存 deviceId ↔ 公钥/指纹的绑定与首见时间，用于：
/// - 多设备指纹核对（用户肉眼比对，防中间替换）；
/// - 后续设备轮换/吊销的锚点（Phase 2 账号体系接管）。
/// 密钥材料之外的一切（口令、MK、信封）不经此端点 —— 信封上送
/// 属账号体系 v1（S10，ADR-013）。
library;

import 'dart:convert';

/// 设备密钥算法标识（当前仅 ed25519）。
const String deviceKeyAlgorithm = 'ed25519';

class DeviceRegistrationRequest {
  const DeviceRegistrationRequest({
    required this.deviceId,
    required this.algorithm,
    required this.publicKeyB64,
    required this.fingerprint,
  });

  final String deviceId;
  final String algorithm;

  /// Ed25519 公钥原始字节（32B）的 base64。
  final String publicKeyB64;

  /// 密钥指纹（客户端按 SHA-256(公钥) 前 16 字节 8 组 × 4 hex 展示）。
  final String fingerprint;

  Map<String, Object?> toJson() => {
    'device_id': deviceId,
    'algorithm': algorithm,
    'public_key': publicKeyB64,
    'fingerprint': fingerprint,
  };

  factory DeviceRegistrationRequest.fromJson(Map<String, Object?> json) {
    final deviceId = json['device_id'];
    final algorithm = json['algorithm'];
    final publicKey = json['public_key'];
    final fingerprint = json['fingerprint'];
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
    return DeviceRegistrationRequest(
      deviceId: deviceId,
      algorithm: algorithm,
      publicKeyB64: publicKey,
      fingerprint: fingerprint,
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
