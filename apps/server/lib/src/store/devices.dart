/// 设备目录（S07「设备注册带密钥指纹」）：deviceId ↔ 公钥/指纹绑定。
///
/// 服务端校验指纹一致性（SHA-256(公钥) 前 16 字节,与客户端同构）——
/// 不匹配即拒绝,防注册通道上的公钥替换。默认内存实现(重启即失,
/// 持久化随账号体系 v1/S10 落 Postgres)。
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
    required this.registeredAt,
  });

  final String deviceId;
  final String algorithm;
  final String publicKeyB64;
  final String fingerprint;
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

abstract interface class DeviceDirectory {
  /// 注册/刷新设备密钥。幂等:同设备重复注册返回 created=false。
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
