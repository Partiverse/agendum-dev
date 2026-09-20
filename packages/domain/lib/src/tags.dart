/// 标签与互斥标签组（03 文档 DDL：`tag_groups.exclusive`）。
///
/// 互斥校验是领域红线：任何"给任务加标签"的写路径必须先经
/// [checkExclusiveAssign]。自由标签（不属于任何组）不加限制；
/// 同一互斥组内一个任务最多持有一个标签——语义是互斥的枚举维度
/// （如 场合：现场/远程、状态：阻塞/可推进），与单选字段对齐。
library;

/// 标签描述符（仓库层从 tags × tag_groups 投影，领域层不依赖 DB）。
class TagDescriptor {
  const TagDescriptor({
    required this.id,
    required this.name,
    this.groupId,
    this.groupName,
    this.groupExclusive = false,
  });

  final String id;
  final String name;

  /// 所属标签组；null = 自由标签。
  final String? groupId;
  final String? groupName;
  final bool groupExclusive;

  @override
  bool operator ==(Object other) =>
      other is TagDescriptor &&
      other.id == id &&
      other.name == name &&
      other.groupId == groupId &&
      other.groupExclusive == groupExclusive;

  @override
  int get hashCode => Object.hash(id, name, groupId, groupExclusive);

  @override
  String toString() =>
      'TagDescriptor(${groupId == null ? '' : '@$groupId '}$name)';
}

/// 互斥组冲突（抛出即调用方未校验，UI 层应捕获并提示而非崩）。
class ExclusiveTagGroupError extends Error {
  ExclusiveTagGroupError(this.groupId, this.existing, this.candidate);

  final String groupId;
  final TagDescriptor existing;
  final TagDescriptor candidate;

  @override
  String toString() =>
      'ExclusiveTagGroupError: 互斥组「${existing.groupName ?? groupId}」'
      '已含「${existing.name}」，不能再加「${candidate.name}」';
}

/// 校验"给任务加入 [candidate]"是否合法。
/// 重复加入同一标签不在此处理（仓库层幂等）；互斥组冲突抛
/// [ExclusiveTagGroupError]。
void checkExclusiveAssign(
  Iterable<TagDescriptor> current,
  TagDescriptor candidate,
) {
  if (!candidate.groupExclusive) return;
  for (final t in current) {
    if (t.id == candidate.id) continue;
    if (t.groupId != null && t.groupId == candidate.groupId) {
      throw ExclusiveTagGroupError(candidate.groupId!, t, candidate);
    }
  }
}

/// 计算移除某标签后的集合（领域层只管纯集合，仓库层落库）。
List<TagDescriptor> withoutTag(Iterable<TagDescriptor> current, String tagId) =>
    [
      for (final t in current)
        if (t.id != tagId) t,
    ];
