/// 任务仓库:客户端唯一写路径(03 文档 §4.3)。
///
/// 每次写操作 = 一个事务:
/// 1. 领域校验(状态变更必须经 `transition()` —— 领域红线);
/// 2. lamport 时钟 +1;
/// 3. 更新 tasks 行 + 追加字段级 oplog + 更新字段裁决镜像(同一事务)。
library;

import 'dart:convert';

import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'local_sync_store.dart';
import 'task_fields.dart';

class TaskRepository {
  TaskRepository(this._db, this._sync);

  final AgendumDatabase _db;
  final DriftLocalSyncStore _sync;

  DriftLocalSyncStore get sync => _sync;

  /// 捕获入库(智能捕获公理 1 的最小闭环):解析结果字段直接落模型。
  /// sort_key 头插(分数索引):新任务在最上,拖拽重排后仍稳定。
  Future<Task> addFromCapture(ParsedCapture r) => _db.transaction(() async {
    final lamport = await _sync.tick();
    final now = DateTime.now().millisecondsSinceEpoch;
    final key = prependSortKey(await _firstSortKey());
    final id = const Uuid().v7();
    final rowJson = <String, Object?>{
      'title': r.title,
      'status': TaskStatus.inbox.value,
      'sort_key': key,
      if (r.dueDay != null) 'due_date': r.dueDay,
      if (r.estimateMinutes != null) 'estimate_minutes': r.estimateMinutes,
      if (r.energy != null) 'energy': r.energy,
      if (r.reminderAtMs != null) 'reminder_at': r.reminderAtMs,
    };
    await _db
        .into(_db.tasks)
        .insert(
          TasksCompanion.insert(
            id: id,
            title: r.title,
            sortKey: key,
            dueDate: Value(r.dueDay),
            estimateMinutes: Value(r.estimateMinutes),
            energy: Value(r.energy),
            reminderAt: Value(r.reminderAtMs),
            createdAt: now,
            updatedAt: now,
            lamport: lamport,
            origin: _sync.deviceId,
          ),
        );
    await _appendOp(
      entityId: id,
      field: rowCreateField,
      type: SyncOpType.set,
      lamport: lamport,
      value: OpValue(OpValueTypes.json, rowJson),
    );
    for (final field in rowJson.keys) {
      await _putMirror(id, field, lamport, 'set');
    }
    await _putMirror(id, rowCreateField, lamport, 'set');
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingle();
  });

  Future<Task> addManual(String title) =>
      addFromCapture(ParsedCapture(title: title, confidence: 0));

  /// 完成/恢复(走状态机;done 记 completed_at,回退清除)。
  Future<void> toggleDone(String id) => _db.transaction(() async {
    final row = await _byId(id);
    final from = TaskStatus.fromValue(row.status);
    final target = from.isTerminal ? TaskStatus.next : TaskStatus.done;
    transition(from, target); // 领域红线:非法流转直接抛
    await _edit(row, {
      'status': target.value,
      'completed_at': target == TaskStatus.done
          ? DateTime.now().millisecondsSinceEpoch
          : null,
    });
  });

  /// 收件箱 → 下一步(走状态机)。
  Future<void> promoteToNext(String id) => _db.transaction(() async {
    final row = await _byId(id);
    transition(TaskStatus.fromValue(row.status), TaskStatus.next);
    await _edit(row, {'status': TaskStatus.next.value});
  });

  /// 回收进收件箱(走状态机;waiting → inbox 不在流转表,会按红线抛出)。
  Future<void> moveToInbox(String id) => _db.transaction(() async {
    final row = await _byId(id);
    transition(TaskStatus.fromValue(row.status), TaskStatus.inbox);
    await _edit(row, {'status': TaskStatus.inbox.value, 'completed_at': null});
  });

  /// 任务挂到项目/移出项目(project_id 可空)。
  Future<void> setTaskProject(String id, String? projectId) =>
      _db.transaction(() async {
        final row = await _byId(id);
        await _edit(row, {'project_id': projectId});
      });

  /// 字段级编辑(任务详情页用;字段名必须是 tasks 白名单列)。
  Future<void> editTask(String id, Map<String, Object?> changes) =>
      _db.transaction(() async {
        final row = await _byId(id);
        await _edit(row, changes);
      });

  /// 状态流转(详情页状态 chips;done 记 completed_at,离开 done 清除)。
  Future<void> setTaskStatus(String id, TaskStatus target) =>
      _db.transaction(() async {
        final row = await _byId(id);
        transition(TaskStatus.fromValue(row.status), target);
        await _edit(row, {
          'status': target.value,
          'completed_at': target == TaskStatus.done
              ? DateTime.now().millisecondsSinceEpoch
              : null,
        });
      });

  Future<Task> byId(String id) => _byId(id);

  /// 项目删除的关系完整性(S07):项目内任务回收件箱。
  /// project_id 一律置空;活跃任务(收件箱/下一步/随时)经状态机回 inbox;
  /// waiting 保持(等谁与项目无关)、done 保持完成、trashed 不动。
  /// 在调用方(项目删除)的事务内调用 —— drift 嵌套事务并入外层。
  Future<int> recycleTasksFromProject(String projectId) =>
      _db.transaction(() async {
        final rows =
            await (_db.select(_db.tasks)..where(
                  (t) => t.deletedAt.isNull() & t.projectId.equals(projectId),
                ))
                .get();
        for (final row in rows) {
          final status = TaskStatus.fromValue(row.status);
          if (status == TaskStatus.trashed) continue;
          final backToInbox = switch (status) {
            TaskStatus.inbox || TaskStatus.next || TaskStatus.someday => true,
            _ => false,
          };
          await _edit(row, {
            'project_id': null,
            if (backToInbox) 'status': TaskStatus.inbox.value,
          });
        }
        return rows.length;
      });

  /// 手动排序(S07 拖拽,分数索引):按视图给出的新顺序重排 sort_key。
  /// 单一移动只在原邻居间取新中点(一次拖拽 = 1 条 op);
  /// 中点越界(键超长)或多处变动(远端穿插等)时整表均匀重排压缩。
  Future<void> reorderTasks(List<String> orderedIds) =>
      _db.transaction(() async {
        if (orderedIds.length < 2) return;
        final rows = await (_db.select(
          _db.tasks,
        )..where((t) => t.id.isIn(orderedIds))).get();
        final byId = {for (final r in rows) r.id: r};
        // 视图顺序里可能混入已被并发删除的行,按现存行截断。
        final ids = [
          for (final id in orderedIds)
            if (byId.containsKey(id)) id,
        ];
        if (ids.length < 2) return;
        final oldOrder = [...ids]
          ..sort((a, b) => byId[a]!.sortKey.compareTo(byId[b]!.sortKey));
        if (_listEquals(oldOrder, ids)) return; // 无变化
        final moved = _singleMovedItem(oldOrder, ids);
        if (moved != null) {
          final i = ids.indexOf(moved);
          final prev = i > 0 ? byId[ids[i - 1]]!.sortKey : null;
          final next = i + 1 < ids.length ? byId[ids[i + 1]]!.sortKey : null;
          try {
            final key = midpointSortKey(prev, next);
            if (key.length <= maxSortKeyLength) {
              await _edit(byId[moved]!, {'sort_key': key});
              return;
            }
          } on ArgumentError {
            // prev ≥ next(远端穿插等罕见态):整表重排兜底
          } on StateError {
            // 键超长:整表重排压缩
          }
        }
        final keys = rebalancedSortKeys(ids.length);
        for (var i = 0; i < ids.length; i++) {
          if (byId[ids[i]]!.sortKey != keys[i]) {
            await _edit(byId[ids[i]]!, {'sort_key': keys[i]});
          }
        }
      });

  /// 单项移动识别(严格版):去掉候选项后两序完全一致才算。
  /// 这保证新邻居在原序中相邻 —— 中点键必不与现存键碰撞。
  /// 任意整表重排(远端穿插等)识别失败,走均匀重排压缩兜底。
  String? _singleMovedItem(List<String> oldOrder, List<String> newOrder) {
    if (oldOrder.length != newOrder.length) return null;
    for (var i = 0; i < oldOrder.length; i++) {
      if (oldOrder[i] != newOrder[i]) {
        final candidates = {oldOrder[i], newOrder[i]};
        for (final candidate in candidates) {
          final ro = [...oldOrder]..remove(candidate);
          final rn = [...newOrder]..remove(candidate);
          if (_listEquals(ro, rn)) return candidate;
        }
        return null;
      }
    }
    return null;
  }

  /// 收件箱透视快照:未澄清 + 已完成(Things 行为:完成保留显示删除线)。
  /// trashed 不显示(墓碑由 deleted_at 另行标记)。
  /// 排序 = sort_key(分数索引,创建头插):支持 S07 拖拽手动排序,
  /// 未拖拽时视觉顺序与创建时间倒序一致。
  /// 用一次性查询而非 watch 流:视图缓存由调用方在明确刷新点重查
  /// (本地写后 / 引擎 onRemoteApplied 后);drift watch 依赖真实事件循环,
  /// 在 widget 测试的 FakeAsync zone 不可达,且刷新点收敛后也无必要。
  Future<List<Task>> inboxSnapshot() => _inboxQuery().get();

  /// 今日透视快照:next 状态 + 截止日未过的任务(样板期简化语义)。
  /// 已完成保留显示删除线(Things 行为):行不消失,⌫ 回收等键盘流才有落点。
  Future<List<Task>> todaySnapshot() => _todayQuery().get();

  /// 计划透视:活跃任务中带 planned/due 日期的,按日期排序(S06 简化语义)。
  Future<List<Task>> planSnapshot() =>
      (_db.select(_db.tasks)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.status.isNotIn([
                    TaskStatus.done.value,
                    TaskStatus.trashed.value,
                  ]) &
                  (t.plannedDate.isNotNull() | t.dueDate.isNotNull()),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.plannedDate),
              (t) => OrderingTerm.asc(t.dueDate),
            ]))
          .get();

  /// 随时透视:someday + 无日期的 next(S06 简化语义)。
  /// 排序 = sort_key:随时列表是手动排序的主视图(S07 拖拽)。
  Future<List<Task>> anytimeSnapshot() =>
      (_db.select(_db.tasks)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.plannedDate.isNull() &
                  t.dueDate.isNull() &
                  (t.status.equals(TaskStatus.someday.value) |
                      t.status.equals(TaskStatus.next.value)),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortKey),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .get();

  /// 回顾透视:近 7 天完成(周回顾的素材面)。
  Future<List<Task>> reviewSnapshot() {
    final since = DateTime.now()
        .add(const Duration(days: -7))
        .millisecondsSinceEpoch;
    return (_db.select(_db.tasks)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.status.equals(TaskStatus.done.value) &
                t.completedAt.isBiggerOrEqualValue(since),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  /// 等待中透视(waiting;等待视图 S08 落地,先供详情页索引)。
  Future<List<Task>> waitingSnapshot() =>
      (_db.select(_db.tasks)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.status.equals(TaskStatus.waiting.value),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .get();

  /// 日志簿:全部已完成,按完成时间倒序。
  Future<List<Task>> logSnapshot() =>
      (_db.select(_db.tasks)
            ..where(
              (t) =>
                  t.deletedAt.isNull() & t.status.equals(TaskStatus.done.value),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .get();

  /// 项目透视:挂到指定项目的活跃任务(trashed 排除)。
  Future<List<Task>> tasksByProjectSnapshot(String projectId) =>
      (_db.select(_db.tasks)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.projectId.equals(projectId) &
                  t.status.isNotIn([TaskStatus.trashed.value]),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.sortKey)]))
          .get();

  SimpleSelectStatement<$TasksTable, Task> _inboxQuery() {
    final q = _db.select(_db.tasks)
      ..where(
        (t) =>
            t.deletedAt.isNull() &
            t.status.isIn([TaskStatus.inbox.value, TaskStatus.done.value]),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortKey),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return q;
  }

  SimpleSelectStatement<$TasksTable, Task> _todayQuery() {
    final today = epochDayOf(DateTime.now());
    final q = _db.select(_db.tasks)
      ..where(
        (t) =>
            t.deletedAt.isNull() &
            t.status.isNotIn([TaskStatus.trashed.value]) &
            (t.status.equals(TaskStatus.next.value) |
                t.status.equals(TaskStatus.done.value) |
                (t.dueDate.isNotNull() &
                    t.dueDate.isSmallerOrEqualValue(today))),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return q;
  }

  Future<int> count() async {
    final exp = countAll();
    final q = _db.selectOnly(_db.tasks)..addColumns([exp]);
    return (await q.map((row) => row.read(exp)).getSingle()) ?? 0;
  }

  // ---- 内部:统一写路径 ----

  /// 字段级编辑:与现值相同的字段跳过(oplog 去重),其余 set/del 落 oplog。
  Future<void> _edit(Task row, Map<String, Object?> changes) async {
    final lamport = await _sync.tick();
    final now = DateTime.now().millisecondsSinceEpoch;
    var touched = false;
    for (final entry in changes.entries) {
      final field = entry.key;
      final newValue = entry.value;
      if (_currentValue(row, field) == newValue) continue; // 幂等写不产生 op
      touched = true;
      await _appendOp(
        entityId: row.id,
        field: field,
        type: newValue == null ? SyncOpType.del : SyncOpType.set,
        lamport: lamport,
        value: newValue == null ? null : TaskFields.encode(field, newValue),
      );
      await _putMirror(
        row.id,
        field,
        lamport,
        newValue == null ? 'del' : 'set',
      );
    }
    if (!touched) return;
    final write = TasksCompanion(
      lamport: Value(lamport),
      origin: Value(_sync.deviceId),
      updatedAt: Value(now),
    );
    await (_db.update(
      _db.tasks,
    )..where((t) => t.id.equals(row.id))).write(write);
    for (final entry in changes.entries) {
      if (_currentValue(row, entry.key) == entry.value) continue;
      await (_db.update(_db.tasks)..where((t) => t.id.equals(row.id))).write(
        TaskFields.companion(entry.key, entry.value),
      );
    }
  }

  /// 字段现值(oplog 去重用)。
  Object? _currentValue(Task row, String field) => switch (field) {
    'title' => row.title,
    'note' => row.note,
    'status' => row.status,
    'start_date' => row.startDate,
    'due_date' => row.dueDate,
    'planned_date' => row.plannedDate,
    'defer_date' => row.deferDate,
    'completed_at' => row.completedAt,
    'reminder_at' => row.reminderAt,
    'recurrence' => row.recurrence,
    'estimate_minutes' => row.estimateMinutes,
    'actual_minutes' => row.actualMinutes,
    'energy' => row.energy,
    'waiting_for' => row.waitingFor,
    'project_id' => row.projectId,
    'sort_key' => row.sortKey,
    _ => throw ArgumentError('未知任务字段:$field'),
  };

  Future<Task> _byId(String id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingle();

  Future<String?> _firstSortKey() async {
    final row =
        await (_db.select(_db.tasks)
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortKey),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.sortKey;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _appendOp({
    required String entityId,
    required String field,
    required SyncOpType type,
    required int lamport,
    OpValue? value,
  }) async {
    await _db
        .into(_db.oplog)
        .insert(
          OplogCompanion.insert(
            deviceId: _sync.deviceId,
            lamport: lamport,
            entity: TaskFields.entity,
            entityId: entityId,
            field: field,
            op: syncOpTypeToJson(type),
            valueBlob: value == null
                ? const Value.absent()
                : Value(jsonEncode(value.toJson())),
          ),
        );
  }

  Future<void> _putMirror(
    String entityId,
    String field,
    int lamport,
    String opType,
  ) async {
    await _db
        .into(_db.fieldLamport)
        .insertOnConflictUpdate(
          FieldLamportCompanion.insert(
            entity: TaskFields.entity,
            entityId: entityId,
            field: field,
            lamport: lamport,
            origin: _sync.deviceId,
            opType: opType,
          ),
        );
  }
}
