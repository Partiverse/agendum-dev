/// XChaCha20-Poly1305 AEAD 封装（03 文档 §6.2）。
///
/// 线上/存储格式：`nonce(24B) || ciphertext || mac(16B)` 单字节串，
/// nonce 每次加密随机生成（24B 随机空间，无需查重）。
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// 认证失败（密钥错误、密文被篡改或 AAD 不匹配）。
class AeadAuthError implements Exception {
  const AeadAuthError(this.message);

  final String message;

  @override
  String toString() => 'AeadAuthError: $message';
}

abstract final class XchachaAead {
  static final _aead = Xchacha20.poly1305Aead();

  static final Random _random = Random.secure();

  /// 加密：返回 nonce || ciphertext || mac。
  static Future<Uint8List> seal({
    required List<int> key, // 32B
    required List<int> plaintext,
    List<int> aad = const <int>[],
  }) async {
    if (key.length != 32) {
      throw ArgumentError.value(key.length, 'key', '密钥须为 32 字节');
    }
    final nonce = Uint8List(24);
    for (var i = 0; i < 24; i++) {
      nonce[i] = _random.nextInt(256);
    }
    final box = await _aead.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
      aad: aad,
    );
    final out = Uint8List(24 + box.cipherText.length + box.mac.bytes.length);
    out.setRange(0, 24, nonce);
    out.setRange(24, 24 + box.cipherText.length, box.cipherText);
    out.setRange(24 + box.cipherText.length, out.length, box.mac.bytes);
    return out;
  }

  /// 解密：任何字节被改、密钥或 AAD 不符即抛 [AeadAuthError]。
  static Future<Uint8List> open({
    required List<int> key,
    required List<int> sealed,
    List<int> aad = const <int>[],
  }) async {
    if (key.length != 32) {
      throw ArgumentError.value(key.length, 'key', '密钥须为 32 字节');
    }
    if (sealed.length < 24 + 16) {
      throw ArgumentError.value(sealed.length, 'sealed', '长度不足');
    }
    final box = SecretBox(
      sealed.sublist(24, sealed.length - 16),
      nonce: sealed.sublist(0, 24),
      mac: Mac(sealed.sublist(sealed.length - 16)),
    );
    try {
      return Uint8List.fromList(
        await _aead.decrypt(box, secretKey: SecretKey(key), aad: aad),
      );
    } on SecretBoxAuthenticationError {
      throw const AeadAuthError('认证失败：密钥不符或数据被篡改');
    }
  }
}
