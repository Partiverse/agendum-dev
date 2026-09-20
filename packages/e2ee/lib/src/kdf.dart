/// KDF 层（03 文档 §6.1）：Argon2id 口令派生、HKDF 子密钥、BIP39 种子。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Argon2id 参数（03 文档 §6.1：m=64MB, t=3, p=1）。
/// memory 单位为 1KiB block（RFC 9106），64MiB = 65536。
const int argon2MemoryKib = 65536;
const int argon2Iterations = 3;
const int argon2Parallelism = 1;
const int argon2HashLength = 32;
const int saltLength = 16;

final Argon2id _argon2 = Argon2id(
  parallelism: argon2Parallelism,
  memory: argon2MemoryKib,
  iterations: argon2Iterations,
  hashLength: argon2HashLength,
);

final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

final Pbkdf2 _pbkdf2 = Pbkdf2(
  macAlgorithm: Hmac.sha512(),
  iterations: 2048,
  bits: 512,
);

/// 主密码 → KEK（Key Encryption Key，不出设备）。
/// salt 须随机生成并随信封保存；同密码不同 salt 派生不同 KEK。
Future<Uint8List> deriveKek(String password, {required List<int> salt}) async =>
    Uint8List.fromList(
      await (await _argon2.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      )).extractBytes(),
    );

/// HKDF-SHA256 子密钥派生（DK = HKDF(MK, info: 'db')，备份密钥 info: 'backup'）。
Future<Uint8List> hkdfSha256(
  List<int> ikm, {
  required String info,
  List<int> salt = const <int>[],
}) async => Uint8List.fromList(
  await (await _hkdf.deriveKey(
    secretKey: SecretKey(ikm),
    nonce: salt,
    info: utf8.encode(info),
  )).extractBytes(),
);

/// BIP39 种子（规范：PBKDF2-HMAC-SHA512，口令 = 'mnemonic' + passphrase，
/// 2048 轮，64 字节）。英文词表为纯 ASCII，无需 Unicode 规范化；
/// 非 ASCII passphrase 的规范化由上层负责（BIP39 §种子生成）。
Future<Uint8List> bip39Seed(String mnemonic, {String passphrase = ''}) async =>
    Uint8List.fromList(
      await (await _pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(mnemonic)),
        nonce: utf8.encode('mnemonic$passphrase'),
      )).extractBytes(),
    );
