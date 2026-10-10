/// 设备身份密钥（03 文档 §6.1）：每设备 Ed25519 密钥对，
/// 注册时上送公钥与密钥指纹（S07「设备注册带密钥指纹」）。
///
/// 指纹 = SHA-256(公钥) 前 16 字节，按 4 hex 一组连字展示
/// （`AB12-CD34-…`），供用户在多设备间肉眼核对，防中间替换。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' show sha256;

class DeviceKeys {
  DeviceKeys._(this._keyPair, this.publicKey);

  static final _ed25519 = Ed25519();

  final SimpleKeyPair _keyPair;

  /// Ed25519 公钥原始字节（32B）。
  final Uint8List publicKey;

  /// 注册协议字段：算法标识。
  static const algorithm = 'ed25519';

  /// 随机生成设备密钥对。
  static Future<DeviceKeys> generate() async {
    final keyPair = await _ed25519.newKeyPair();
    final pub = await keyPair.extractPublicKey();
    return DeviceKeys._(keyPair, Uint8List.fromList(pub.bytes));
  }

  /// 由 32 字节种子确定性重建（测试/从钥匙串恢复用）。
  static Future<DeviceKeys> fromSeed(List<int> seed) async {
    if (seed.length != 32) {
      throw ArgumentError.value(seed.length, 'seed', '种子须为 32 字节');
    }
    final keyPair = await _ed25519.newKeyPairFromSeed(seed);
    final pub = await keyPair.extractPublicKey();
    return DeviceKeys._(keyPair, Uint8List.fromList(pub.bytes));
  }

  /// 公钥 base64（注册协议字段）。
  String get publicKeyB64 => base64Encode(publicKey);

  /// 密钥指纹：SHA-256(公钥) 前 16 字节，每 2 字节一组 4 hex、`-` 相连
  /// （共 8 组，`AAAA-BBBB-…`）。
  String get fingerprint =>
      fingerprintFromDigest(sha256.convert(publicKey).bytes);

  /// 签名（设备身份证明；注册协议预留）。
  Future<Signature> sign(List<int> message) =>
      _ed25519.sign(message, keyPair: _keyPair);

  /// 验签（对端设备）。
  static Future<bool> verify({
    required List<int> message,
    required Signature signature,
  }) => _ed25519.verify(message, signature: signature);

  /// wire 验签（R1 §3/§4）：base64 公钥 + base64 签名 + 原文，一次调用。
  /// 服务端注册/鉴权校验与客户端测试共用，免去各处手工组 Signature。
  static Future<bool> verifyB64({
    required List<int> message,
    required String sigB64,
    required String publicKeyB64,
  }) => verify(
    message: message,
    signature: Signature(
      base64Decode(sigB64),
      publicKey: SimplePublicKey(
        base64Decode(publicKeyB64),
        type: KeyPairType.ed25519,
      ),
    ),
  );

  /// 指纹格式自检（防手滑改坏格式）。
  static bool looksLikeFingerprint(String s) =>
      RegExp(r'^[0-9A-F]{4}(-[0-9A-F]{4}){7}$').hasMatch(s);
}

/// 指纹派生（对任意公钥字节；注册端点校验用）。
Future<String> fingerprintOf(List<int> publicKey) async =>
    fingerprintFromDigest(sha256.convert(publicKey).bytes);

/// SHA-256 摘要 → 展示指纹（前 16 字节，8 组 × 4 hex，`AAAA-BBBB-…`）。
String fingerprintFromDigest(List<int> digest) {
  final hex = [
    for (final b in digest.sublist(0, 16)) b.toRadixString(16).padLeft(2, '0'),
  ].join();
  return [
    for (var g = 0; g < 8; g++) hex.substring(g * 4, g * 4 + 4).toUpperCase(),
  ].join('-');
}
