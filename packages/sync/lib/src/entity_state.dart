/// 实体级合并状态：一个 entity_id 的全部字段及其裁决结果。
library;

import 'package:agendum_protocol/agendum_protocol.dart';

import 'lww.dart';

class EntitySyncState {
  EntitySyncState();

  final Map<String, FieldEntry> _fields = {};

  /// 只读视图（调用方不得直接修改）。
  Map<String, FieldEntry> get fields => Map.unmodifiable(_fields);

  bool get isDeleted => _fields[rowCreateField]?.isTombstone ?? false;

  FieldEntry? field(String name) => _fields[name];

  /// 应用一条变更，返回是否有实际变化（oplog 推送端可据此去重）。
  bool apply(SyncOp op) {
    final incoming = entryFromOp(op);
    final current = _fields[op.field];
    final winner = current == null ? incoming : resolveEntry(current, incoming);
    final changed = winner != current && !_sameEntry(winner, current);
    _fields[op.field] = winner;
    return changed;
  }

  /// 重置为空状态（演示/测试用；生产路径不调用）。
  void reset() => _fields.clear();

  /// 与另一副本的字段状态合并（pull 后的双端收敛入口）。
  void mergeInto(EntitySyncState other) {
    other._fields.forEach((name, entry) {
      final current = _fields[name];
      _fields[name] = current == null ? entry : resolveEntry(current, entry);
    });
  }

  bool _sameEntry(FieldEntry a, FieldEntry? b) {
    if (b == null) return false;
    return a.version.lamport == b.version.lamport &&
        a.version.origin == b.version.origin &&
        a.type == b.type &&
        a.value == b.value;
  }
}
