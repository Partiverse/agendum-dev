/// 字段级 LWW 裁决（03 文档 §2.4 收敛规则与 §5 冲突细则）。
///
/// 规则：
/// 1. lamport 大者胜；
/// 2. lamport 相同（真并发）且类型不同 → **删除胜**（墓碑）；
/// 3. lamport 相同且类型相同 → origin 设备 ID 字典序**大者胜**（确定性破平）。
/// 墙钟永不参与裁决（02 文档 §7.2 混沌场景 4）。
library;

import 'package:agendum_protocol/agendum_protocol.dart';

/// 版本向量单元：决定字段归属的两个标量。
class FieldVersion {
  const FieldVersion({required this.lamport, required this.origin});

  final int lamport;
  final String origin;

  @override
  bool operator ==(Object other) =>
      other is FieldVersion &&
      other.lamport == lamport &&
      other.origin == origin;

  @override
  int get hashCode => Object.hash(lamport, origin);

  @override
  String toString() => 'v($lamport, $origin)';
}

/// 字段的合并后状态。
class FieldEntry {
  const FieldEntry({required this.version, required this.type, this.value})
    : isTombstone = type == SyncOpType.del;

  final FieldVersion version;
  final SyncOpType type;
  final OpValue? value;
  final bool isTombstone;

  @override
  bool operator ==(Object other) =>
      other is FieldEntry &&
      other.version == version &&
      other.type == type &&
      other.value == value;

  @override
  int get hashCode => Object.hash(version, type, value);

  @override
  String toString() => 'FieldEntry($version, $type, $value)';
}

/// 单字段合并：返回胜出的 [FieldEntry]。两侧副本以任意顺序调用，
/// 结果一致（交换律），这是收敛证明的核心性质。
FieldEntry resolveEntry(FieldEntry a, FieldEntry b) {
  if (a.version.lamport != b.version.lamport) {
    return a.version.lamport > b.version.lamport ? a : b;
  }
  if (a.isTombstone != b.isTombstone) {
    return a.isTombstone ? a : b;
  }
  final c = a.version.origin.compareTo(b.version.origin);
  if (c == 0) return a; // 同一条写（幂等重放）
  return c > 0 ? a : b;
}

FieldEntry entryFromOp(SyncOp op) => FieldEntry(
  version: FieldVersion(lamport: op.lamport, origin: op.deviceId),
  type: op.type,
  value: op.value,
);
