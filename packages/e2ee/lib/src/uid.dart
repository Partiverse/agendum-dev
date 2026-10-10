/// 租户标识 uid(R1 §1/§5):从 Vault 主密钥派生,服务端按 owner=uid 隔离。
///
/// 两跳派生(ADR-016 §6 注册准入):
/// ```text
/// proof = HKDF(MK, info: 'agendum/uid-proof', 32 字节)   ← 注册归属证明
/// uid   = hex(HKDF(proof, info: 'agendum/uid', 16 字节)) ← 服务端路由键
/// ```
/// - 同一种子多端必得同一 uid;不同种子(不同用户)uid 碰撞概率 2^-128。
/// - 注册时上送 proof,服务端重算 HKDF(proof) 与声明的 uid 比对:持 MK 者
///   必能出示 proof;**只知 uid 无法反推 proof**(HKDF 单向)——修复
///   「知悉 uid 即可把设备注册进任意租户」的准入缺口。
/// - proof 只在注册请求出现,服务端验后即弃、不落库;它不泄露 MK,也
///   推不出 DK(HKDF 单向 + info 域分离)。
library;

import 'dart:typed_data';

import 'kdf.dart';

/// HKDF info 常量(R1 §1 / ADR-016 §6)。
const String uidInfo = 'agendum/uid';

/// 注册归属证明的 HKDF info(ADR-016 §6)。
const String uidProofInfo = 'agendum/uid-proof';

/// 明文开发模式的固定 uid(R1 §1):无 Vault 的开发链路共用一个租户,
/// 便于本地联调;生产构建永远走派生 uid。
const String devPlaintextUid = 'dev-plain';

/// uid 十六进制长度(16 字节 → 32 字符)。
const int uidHexLength = 32;

/// 注册归属证明(ADR-016 §6):proof = HKDF(MK, info: 'agendum/uid-proof',
/// 32 字节)。注册时随 `uid_proof` 上送,服务端验证 uid = HKDF(proof)。
Future<Uint8List> uidProof(List<int> mk) => hkdfSha256(mk, info: uidProofInfo);

/// 租户 uid(ADR-016 §6):hex(HKDF(uidProof(MK), info: 'agendum/uid',
/// 16 字节))(R1 §1)。
Future<String> tenantUid(List<int> mk) async {
  final bytes = await hkdfSha256(
    await uidProof(mk),
    info: uidInfo,
    outputLength: 16,
  );
  return hexEncode(bytes);
}

/// 字节 → 小写十六进制(uid 与测试辅助共用)。
String hexEncode(List<int> bytes) =>
    [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
