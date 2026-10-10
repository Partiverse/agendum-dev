/// 设备目录（S07「设备注册带密钥指纹」；R1 §3 扩展 uid 绑定）：
/// deviceId ↔ 公钥/指纹/uid 绑定。
///
/// 服务端校验指纹一致性（SHA-256(公钥) 前 16 字节,与客户端同构）——
/// 不匹配即拒绝,防注册通道上的公钥替换。注册签名验签在 handler 层
/// （见 handler.dart,400 语义）；本目录负责绑定与幂等语义。
/// 默认内存实现(重启即失,持久化随账号体系 v1/S10 落 Postgres)。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:crypto/crypto.dart' show sha256;

/// 注册记录。
class DeviceRecord {
  const DeviceRecord({
    required this.deviceId,
    required this.algorithm,
    required this.publicKeyB64,
    required this.fingerprint,
    required this.uid,
    required this.registeredAt,
  });

  final String deviceId;
  final String algorithm;
  final String publicKeyB64;
  final String fingerprint;

  /// 租户标识（R1 §3/§5）：注册时绑定，鉴权时请求 uid 必须与此一致。
  final String uid;
  final int registeredAt;
}

/// 指纹与公钥不符（可能被替换,拒绝注册）。
class FingerprintMismatch implements Exception {
  const FingerprintMismatch(this.expected, this.actual);

  final String expected;
  final String actual;

  @override
  String toString() => 'FingerprintMismatch: 声明 $expected ≠ 计算 $actual';
}

/// 明文开发模式的保留 uid（与 packages/e2ee 的 `devPlaintextUid` 同构）：
/// 无 Vault 的开发链路共用一个租户，注册豁免 uid 归属证明（ADR-016 §6）。
const String devPlaintextUid = 'dev-plain';

abstract interface class DeviceDirectory {
  /// 注册/刷新设备密钥。幂等:同设备重复注册返回 created=false，
  /// 且**不换绑**公钥与 uid（首绑为准,防注册通道改挂到别的租户）。
  Future<DeviceRegistrationResponse> register(DeviceRegistrationRequest req);

  Future<DeviceRecord?> byId(String deviceId);
}

class MemoryDeviceDirectory implements DeviceDirectory {
  final Map<String, DeviceRecord> _devices = {};

  @override
  Future<DeviceRegistrationResponse> register(
    DeviceRegistrationRequest req,
  ) async {
    final keyBytes = base64Decode(req.publicKeyB64);
    final expected = fingerprintFromKeyBytes(keyBytes);
    if (expected != req.fingerprint) {
      throw FingerprintMismatch(req.fingerprint, expected);
    }
    final existing = _devices[req.deviceId];
    if (existing != null) {
      // 既有语义保持：同设备重复注册不换绑公钥；R1 起同样不换绑 uid。
      return DeviceRegistrationResponse(
        ok: true,
        deviceId: req.deviceId,
        fingerprint: existing.fingerprint,
        created: false,
        registeredAt: existing.registeredAt,
      );
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    _devices[req.deviceId] = DeviceRecord(
      deviceId: req.deviceId,
      algorithm: req.algorithm,
      publicKeyB64: req.publicKeyB64,
      fingerprint: req.fingerprint,
      uid: req.uid,
      registeredAt: now,
    );
    return DeviceRegistrationResponse(
      ok: true,
      deviceId: req.deviceId,
      fingerprint: req.fingerprint,
      created: true,
      registeredAt: now,
    );
  }

  @override
  Future<DeviceRecord?> byId(String deviceId) async => _devices[deviceId];
}

/// SHA-256(公钥) 前 16 字节 → 8 组 × 4 hex 大写、`-` 相连
/// （与 packages/e2ee 的 DeviceKeys.fingerprint 同构;服务端不依赖 e2ee 包）。
String fingerprintFromKeyBytes(List<int> publicKey) {
  final digest = sha256.convert(publicKey).bytes;
  final hex = Uint8List.fromList(
    digest.sublist(0, 16),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return [
    for (var g = 0; g < 8; g++) hex.substring(g * 4, g * 4 + 4).toUpperCase(),
  ].join('-');
}
