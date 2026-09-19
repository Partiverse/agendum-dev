/// project / area 的 op 字段名 ↔ 列映射(03 文档 §4.1;与 task_fields 同构)。
library;

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:drift/drift.dart';

import 'database.dart';

abstract final class ProjectFields {
  /// 同步实体类型名(oplog.entity;服务端按 (entity, entity_id, field) 通用裁决)。
  static const entity = 'project';

  static const Map<String, String> kinds = {
    'name': OpValueTypes.str,
    'note': OpValueTypes.str,
    'status': OpValueTypes.str,
    'parent_id': OpValueTypes.str,
    'area_id': OpValueTypes.str,
    'review_cadence_days': OpValueTypes.intT,
    'next_action_id': OpValueTypes.str,
    'sort_key': OpValueTypes.str,
  };

  /// 非空列:del 落地为 NULL 会违反约束,应用侧跳过。
  static const Set<String> notNullFields = {'name', 'status', 'sort_key'};

  static bool isSyncable(String field) => kinds.containsKey(field);

  static OpValue encode(String field, Object? value) {
    if (value == null) {
      throw ArgumentError.value(field, 'field', '值为空,应为 del op');
    }
    return OpValue(kinds[field]!, value);
  }

  static ProjectsCompanion companion(String field, Object? value) =>
      switch (field) {
        'name' => ProjectsCompanion(name: Value(value as String? ?? '')),
        'note' => ProjectsCompanion(note: Value(value as String?)),
        'status' => ProjectsCompanion(
          status: Value(value as String? ?? 'active'),
        ),
        'parent_id' => ProjectsCompanion(parentId: Value(value as String?)),
        'area_id' => ProjectsCompanion(areaId: Value(value as String?)),
        'review_cadence_days' => ProjectsCompanion(
          reviewCadenceDays: Value(value as int?),
        ),
        'next_action_id' => ProjectsCompanion(
          nextActionId: Value(value as String?),
        ),
        'sort_key' => ProjectsCompanion(sortKey: Value(value as String? ?? '')),
        _ => throw ArgumentError('未知项目字段:$field'),
      };
}

abstract final class AreaFields {
  static const entity = 'area';

  static const Map<String, String> kinds = {
    'name': OpValueTypes.str,
    'color': OpValueTypes.str,
    'sort_key': OpValueTypes.str,
  };

  static const Set<String> notNullFields = {'name', 'sort_key'};

  static bool isSyncable(String field) => kinds.containsKey(field);

  static OpValue encode(String field, Object? value) {
    if (value == null) {
      throw ArgumentError.value(field, 'field', '值为空,应为 del op');
    }
    return OpValue(kinds[field]!, value);
  }

  static AreasCompanion companion(String field, Object? value) =>
      switch (field) {
        'name' => AreasCompanion(name: Value(value as String? ?? '')),
        'color' => AreasCompanion(color: Value(value as String?)),
        'sort_key' => AreasCompanion(sortKey: Value(value as String? ?? '')),
        _ => throw ArgumentError('未知领域字段:$field'),
      };
}
