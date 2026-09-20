/// BIP39 恢复短语（12 词英文，S07「BIP39 恢复短语流程」）。
///
/// 生成：128 位随机熵 + 4 位 SHA-256 校验和 → 12 × 11 位词索引。
/// 校验：词数/词表/校验和三方验证。
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;

import 'bip39_english.dart';

/// 词数不支持（本包支持 12/15/18/21/24，生成默认 12）。
class Bip39FormatError implements Exception {
  const Bip39FormatError(this.message);

  final String message;

  @override
  String toString() => 'Bip39FormatError: $message';
}

abstract final class Bip39 {
  static final RegExp _wordRe = RegExp(r'^[a-z]+$');

  /// 生成 12 词恢复短语（entropyBytes 默认 16 = 128 位 → 12 词）。
  static String generate({int entropyBytes = 16, Random? random}) {
    final entropy = Uint8List(entropyBytes);
    final rng = random ?? Random.secure();
    for (var i = 0; i < entropyBytes; i++) {
      entropy[i] = rng.nextInt(256);
    }
    return fromEntropy(entropy);
  }

  /// 熵 → 助记词（含校验和位）。
  static String fromEntropy(List<int> entropy) {
    final bits = entropy.length * 8;
    if (bits < 128 || bits % 32 != 0) {
      throw ArgumentError.value(entropy.length, 'entropy', '须为 ≥16 字节的 4 倍');
    }
    final checksumBits = bits ~/ 32;
    final totalBits = bits + checksumBits;
    final wordCount = totalBits ~/ 11;
    final digest = sha256.convert(entropy).bytes;
    final sb = StringBuffer();
    for (var i = 0; i < totalBits; i++) {
      final bit = i < bits
          ? (entropy[i >> 3] >> (7 - (i & 7))) & 1
          : (digest[(i - bits) >> 3] >> (7 - ((i - bits) & 7))) & 1;
      sb.write(bit);
    }
    final bitString = sb.toString();
    return [
      for (var w = 0; w < wordCount; w++)
        bip39EnglishWordlist[_bitsToInt(
          bitString.substring(w * 11, (w + 1) * 11),
        )],
    ].join(' ');
  }

  /// 校验短语（词数/词表/校验和）。空串或结构非法返回假。
  static bool validate(String mnemonic) {
    try {
      _indexes(mnemonic);
      return true;
    } on Bip39FormatError {
      return false;
    }
  }

  /// 短语 → 熵（恢复校验用，如「抄录短语回填验证」）。
  static Uint8List toEntropy(String mnemonic) {
    final indexes = _indexes(mnemonic);
    final bitString = indexes
        .map((i) => i.toRadixString(2).padLeft(11, '0'))
        .join();
    final checksumBits = bitString.length ~/ 33;
    final entropyBits = bitString.length - checksumBits;
    final entropy = Uint8List(entropyBits ~/ 8);
    for (var i = 0; i < entropyBits; i++) {
      if (bitString[i] == '1') entropy[i >> 3] |= 1 << (7 - (i & 7));
    }
    final digest = sha256.convert(entropy).bytes;
    for (var i = 0; i < checksumBits; i++) {
      final expect = bitString[entropyBits + i] == '1' ? 1 : 0;
      final actual = (digest[i >> 3] >> (7 - (i & 7))) & 1;
      if (expect != actual) {
        throw const Bip39FormatError('校验和不匹配（抄录有误？）');
      }
    }
    return entropy;
  }

  /// 规范化：小写、按空白切分重组（用户手抄输入的容错）。
  static String normalize(String mnemonic) =>
      mnemonic.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');

  static List<int> _indexes(String mnemonic) {
    final words = normalize(mnemonic).split(' ');
    const legal = [12, 15, 18, 21, 24];
    if (!legal.contains(words.length)) {
      throw Bip39FormatError('词数 ${words.length} 不合法（$legal）');
    }
    final indexes = <int>[];
    for (final w in words) {
      if (!_wordRe.hasMatch(w)) throw Bip39FormatError('非词项:"$w"');
      final i = bip39EnglishWordlist.indexOf(w);
      if (i < 0) throw Bip39FormatError('词不在词表:"$w"');
      indexes.add(i);
    }
    // 校验和位复验
    final bitString = indexes
        .map((i) => i.toRadixString(2).padLeft(11, '0'))
        .join();
    final checksumBits = bitString.length ~/ 33;
    final entropyBits = bitString.length - checksumBits;
    final entropy = Uint8List(entropyBits ~/ 8);
    for (var i = 0; i < entropyBits; i++) {
      if (bitString[i] == '1') entropy[i >> 3] |= 1 << (7 - (i & 7));
    }
    final digest = sha256.convert(entropy).bytes;
    for (var i = 0; i < checksumBits; i++) {
      final expect = bitString[entropyBits + i] == '1' ? 1 : 0;
      final actual = (digest[i >> 3] >> (7 - (i & 7))) & 1;
      if (expect != actual) {
        throw const Bip39FormatError('校验和不匹配（抄录有误？）');
      }
    }
    return indexes;
  }

  static int _bitsToInt(String bits) {
    var v = 0;
    for (final c in bits.split('')) {
      v = (v << 1) | (c == '1' ? 1 : 0);
    }
    return v;
  }
}
