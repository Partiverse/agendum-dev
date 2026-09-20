/// 密钥保险库（03 文档 §6.1）：信封封装、口令解锁、恢复短语找回。
///
/// 服务端只保存 [KekEnvelope] 的 JSON —— Argon2 参数 + 盐 + 用 KEK
/// 包裹的 MK（AEAD 验证器：口令错误时解包即失败）。换密码 = 解包
/// MK 后用新 KEK 重新包裹上传，历史密文不变（DK 由 MK 派生）。
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;

import 'aead.dart';
import 'kdf.dart';
import 'mnemonic.dart';

/// KEK 信封：唯一需要上传服务端的密钥材料（零知识：MK/KEK 均不出设备）。
class KekEnvelope {
  const KekEnvelope({
    required this.alg,
    required this.memoryKib,
    required this.iterations,
    required this.parallelism,
    required this.saltB64,
    required this.wrappedMkB64,
  });

  static const aad = 'agendum/envelope-v1';

  factory KekEnvelope.fromJson(Map<String, Object?> json) => KekEnvelope(
    alg: json['alg'] as String,
    memoryKib: json['memory_kib'] as int,
    iterations: json['iterations'] as int,
    parallelism: json['parallelism'] as int,
    saltB64: json['salt'] as String,
    wrappedMkB64: json['wrapped_mk'] as String,
  );

  final String alg; // 'argon2id'
  final int memoryKib;
  final int iterations;
  final int parallelism;
  final String saltB64;
  final String wrappedMkB64;

  /// 验证器（展示用，如换设备时「指纹核对」）：包裹密文 SHA-256 前 8 字节 hex。
  String get verifier => sha256
      .convert(utf8.encode(wrappedMkB64))
      .bytes
      .sublist(0, 8)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  Map<String, Object?> toJson() => {
    'alg': alg,
    'memory_kib': memoryKib,
    'iterations': iterations,
    'parallelism': parallelism,
    'salt': saltB64,
    'wrapped_mk': wrappedMkB64,
  };

  String encode() => jsonEncode(toJson());

  static KekEnvelope decode(String s) =>
      KekEnvelope.fromJson((jsonDecode(s) as Map).cast<String, Object?>());

  @override
  String toString() =>
      'KekEnvelope($alg m=$memoryKib t=$iterations p=$parallelism)';
}

/// 保险库操作：setup（开新库）/ unlock（口令解锁）/ recover（短语找回）。
abstract final class VaultKeys {
  /// 开新库：生成 12 词恢复短语，派生 MK，用 KEK 包裹成信封。
  static Future<({Uint8List mk, String mnemonic, KekEnvelope envelope})> setup({
    required String password,
    String passphrase = '',
  }) async {
    final mnemonic = Bip39.generate();
    final mk = await masterKey(mnemonic: mnemonic, passphrase: passphrase);
    final envelope = await wrapWithPassword(password, mk);
    return (mk: mk, mnemonic: mnemonic, envelope: envelope);
  }

  /// 恢复短语 → 主密钥 MK（恢复流程的唯一路径；短语丢失即不可救）。
  static Future<Uint8List> masterKey({
    required String mnemonic,
    String passphrase = '',
  }) async {
    final normalized = Bip39.normalize(mnemonic);
    if (!Bip39.validate(normalized)) {
      throw const Bip39FormatError('恢复短语校验失败');
    }
    final seed = await bip39Seed(normalized, passphrase: passphrase);
    // 03 文档：短语 ──PBKDF2──► MK。BIP39 种子 64 字节，经 HKDF 收敛为 32。
    return hkdfSha256(seed, info: 'agendum/mk');
  }

  /// 口令 → KEK → 解包 MK。口令错/AAD 不符抛 [AeadAuthError]。
  static Future<Uint8List> unwrap({
    required String password,
    required KekEnvelope envelope,
  }) async {
    if (envelope.alg != 'argon2id') {
      throw ArgumentError.value(envelope.alg, 'alg', '未知 KDF');
    }
    final kek = await deriveKek(password, salt: base64Decode(envelope.saltB64));
    final wrapped = base64Decode(envelope.wrappedMkB64);
    return XchachaAead.open(
      key: kek,
      sealed: wrapped,
      aad: utf8.encode(KekEnvelope.aad),
    );
  }

  /// 用口令（KEK）包裹 MK 成信封（setup 与换密码共用）。
  static Future<KekEnvelope> wrapWithPassword(
    String password,
    List<int> mk,
  ) async {
    final salt = Uint8List(saltLength);
    final random = _random;
    for (var i = 0; i < saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    final kek = await deriveKek(password, salt: salt);
    final wrapped = await XchachaAead.seal(
      key: kek,
      plaintext: mk,
      aad: utf8.encode(KekEnvelope.aad),
    );
    return KekEnvelope(
      alg: 'argon2id',
      memoryKib: argon2MemoryKib,
      iterations: argon2Iterations,
      parallelism: argon2Parallelism,
      saltB64: base64Encode(salt),
      wrappedMkB64: base64Encode(wrapped),
    );
  }

  /// 换密码：解包 MK → 新 KEK 重新包裹（历史密文不变）。
  static Future<KekEnvelope> changePassword({
    required List<int> mk,
    required String newPassword,
  }) => wrapWithPassword(newPassword, mk);

  /// 数据密钥 DK = HKDF(MK, info: 'db') —— op 负载加密。
  static Future<Uint8List> dataKey(List<int> mk) => hkdfSha256(mk, info: 'db');

  /// 备份密钥 = HKDF(MK, info: 'backup')（服务端每日备份再加密层）。
  static Future<Uint8List> backupKey(List<int> mk) =>
      hkdfSha256(mk, info: 'backup');
}

final Random _random = Random.secure();
