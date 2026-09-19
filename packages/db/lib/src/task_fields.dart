/// op 字段名 ↔ tasks 列的映射(03 文档 §4.1)。
///
/// 字段名与 DDL 列名一致(snake_case);OpValue 类型标签按 DDL 语义:
/// `date` = epoch days(本地日),`ms` = epoch ms,`int` = 分钟等计数。
library;

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:drift/drift.dart';

import 'database.dart';

abstract final class TaskFields {
  /// 同步实体类型名(与协议 SyncEntities.task 一致)。
  static const entity = 'task';

  /// 可同步字段 → OpValue 类型标签。白名单之外的远端字段前向兼容地跳过。
  static const Map<String, String> kinds = {
    'title': OpValueTypes.str,
    'note': OpValueTypes.str,
    'status': OpValueTypes.str,
    'start_date': OpValueTypes.date,
    'due_date': OpValueTypes.date,
    'planned_date': OpValueTypes.date,
    'defer_date': OpValueTypes.date,
    'completed_at': OpValueTypes.ms,
    'reminder_at': OpValueTypes.ms,
    'recurrence': OpValueTypes.str,
    'estimate_minutes': OpValueTypes.intT,
    'actual_minutes': OpValueTypes.intT,
    'energy': OpValueTypes.str,
    'waiting_for': OpValueTypes.str,
    'project_id': OpValueTypes.str,
    'sort_key': OpValueTypes.str,
  };

  /// 非空列:del 落地为 NULL 会违反约束,应用侧跳过(PoC 约定)。
  static const Set<String> notNullFields = {'title', 'status', 'sort_key'};

  static bool isSyncable(String field) => kinds.containsKey(field);

  static OpValue encode(String field, Object? value) {
    if (value == null) {
      throw ArgumentError.value(field, 'field', '值为空,应为 del op');
    }
    return OpValue(kinds[field]!, value);
  }

  /// 远端字段值 → 列写入口;value 为 null 表示 del(置 NULL)。
  /// 非空列收到 del 时调用方应跳过,这里防御性原样返回。
  static TasksCompanion companion(String field, Object? value) =>
      switch (field) {
        'title' => TasksCompanion(title: Value(value as String? ?? '')),
        'note' => TasksCompanion(note: Value(value as String?)),
        'status' => TasksCompanion(status: Value(value as String? ?? 'inbox')),
        'start_date' => TasksCompanion(startDate: Value(value as int?)),
        'due_date' => TasksCompanion(dueDate: Value(value as int?)),
        'planned_date' => TasksCompanion(plannedDate: Value(value as int?)),
        'defer_date' => TasksCompanion(deferDate: Value(value as int?)),
        'completed_at' => TasksCompanion(completedAt: Value(value as int?)),
        'reminder_at' => TasksCompanion(reminderAt: Value(value as int?)),
        'recurrence' => TasksCompanion(recurrence: Value(value as String?)),
        'estimate_minutes' => TasksCompanion(
          estimateMinutes: Value(value as int?),
        ),
        'actual_minutes' => TasksCompanion(actualMinutes: Value(value as int?)),
        'energy' => TasksCompanion(energy: Value(value as String?)),
        'waiting_for' => TasksCompanion(waitingFor: Value(value as String?)),
        'project_id' => TasksCompanion(projectId: Value(value as String?)),
        'sort_key' => TasksCompanion(sortKey: Value(value as String? ?? '')),
        _ => throw ArgumentError('未知任务字段:$field'),
      };
}
