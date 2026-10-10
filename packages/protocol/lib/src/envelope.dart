/// 多设备信封消息（R1 §6）：`POST /v1/vault/envelope` 上传，
/// `GET /v1/vault/envelope?uid=` 取回最新一条。
///
/// 服务端不透明存储（内存 + PG 表 vault_envelopes），密文不可解，仅限本 uid
/// 设备读写。契约只约定 uid/device_id/envelope_b64 三键，上传请求体与 GET
/// 响应体同形，故共用 [VaultEnvelope]；服务端内部元数据（写入时间等）不上
/// wire。
library;

import 'dart:convert';

class VaultEnvelope {
  const VaultEnvelope({
    required this.uid,
    required this.deviceId,
    required this.envelopeB64,
  });

  final String uid;
  final String deviceId;

  /// KEK 加密后的 MK 信封（不透明 base64，服务端不可解）。
  final String envelopeB64;

  Map<String, Object?> toJson() => {
    'uid': uid,
    'device_id': deviceId,
    'envelope_b64': envelopeB64,
  };

  factory VaultEnvelope.fromJson(Map<String, Object?> json) {
    final uid = json['uid'];
    final deviceId = json['device_id'];
    final envelope = json['envelope_b64'];
    if (uid is! String || uid.isEmpty) {
      throw const FormatException('envelope.uid 缺失或非法');
    }
    if (deviceId is! String || deviceId.isEmpty) {
      throw const FormatException('envelope.device_id 缺失或非法');
    }
    if (envelope is! String || envelope.isEmpty) {
      throw const FormatException('envelope.envelope_b64 缺失或非法');
    }
    // base64 可解且非空长度（对协议层不校验内部格式）
    if (base64Decode(envelope).isEmpty) {
      throw const FormatException('envelope.envelope_b64 不是合法 base64');
    }
    return VaultEnvelope(uid: uid, deviceId: deviceId, envelopeB64: envelope);
  }
}
