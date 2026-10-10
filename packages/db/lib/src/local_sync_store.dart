/// Drift 实现的本地同步状态(LocalSyncStore,03 文档 §4.3 客户端职责):
/// oplog 队列读写、拉取游标、lamport 时钟持久化、远端 op 的字段级裁决应用。
library;

import 'dart:convert';

import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'project_fields.dart';
import 'task_fields.dart';

class DriftLocalSyncStore implements LocalSyncStore {
  DriftLocalSyncStore._(this._db, this.deviceId, this._clock, this._cursor);

  final AgendumDatabase _db;
  final LamportClock _clock;

  @override
  final String deviceId;

  int _cursor;

  /// 打开(首次为库生成设备 ID 并初始化 sync_state 行)。
  static Future<DriftLocalSyncStore> open(AgendumDatabase db) async {
    final existing = await (db.select(
      db.syncState,
    )..limit(1)).getSingleOrNull();
    if (existing != null) {
      return DriftLocalSyncStore._(
        db,
        existing.deviceId,
        LamportClock(value: existing.lamport),
        existing.lastPullSeq,
      );
    }
    final deviceId = 'dvc_${const Uuid().v7()}';
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(deviceId: deviceId, lamport: 0));
    return DriftLocalSyncStore._(db, deviceId, LamportClock(), 0);
  }

  int get lamport => _clock.value;

  /// 本地写操作:递增时钟并持久化(03 文档 §3)。
  Future<int> tick() async {
    final v = _clock.tick();
    await _persistClock();
    return v;
  }

  Future<void> _observeLamport(int remote) async {
    _clock.observe(remote);
    await _persistClock();
  }

  Future<void> _persistClock() async {
    await (_db.update(_db.syncState)..where((s) => s.deviceId.equals(deviceId)))
        .write(SyncStateCompanion(lamport: Value(_clock.value)));
  }

  @override
  Future<List<PendingOp>> takePendingOps({int limit = 500}) async {
    final rows =
        await (_db.select(_db.oplog)
              ..where((o) => o.serverSeq.isNull())
              ..orderBy([(o) => OrderingTerm.asc(o.localSeq)])
              ..limit(limit))
            .get();
    return [
      for (final r in rows)
        PendingOp(
          localSeq: r.localSeq,
          op: SyncOp(
            deviceId: r.deviceId,
            lamport: r.lamport,
            entity: r.entity,
            entityId: r.entityId,
            field: r.field,
            type: syncOpTypeFromJson(r.op),
            value: r.valueBlob == null
                ? null
                : OpValue.fromJson(
                    (jsonDecode(r.valueBlob!) as Map).cast<String, Object?>(),
                  ),
          ),
        ),
    ];
  }

  @override
  Future<void> markPushed(Iterable<int> localSeqs, int serverSeq) async {
    if (localSeqs.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(
      _db.oplog,
    )..where((o) => o.localSeq.isIn(localSeqs))).write(
      OplogCompanion(serverSeq: Value(serverSeq), pushedAt: Value(now)),
    );
    await (_db.update(_db.syncState)..where((s) => s.deviceId.equals(deviceId)))
        .write(SyncStateCompanion(lastPushAt: Value(now)));
  }

  @override
  Future<int> pullCursor() async => _cursor;

  @override
  Future<void> setPullCursor(int seq) async {
    _cursor = seq;
    await (_db.update(_db.syncState)..where((s) => s.deviceId.equals(deviceId)))
        .write(SyncStateCompanion(lastPullSeq: Value(seq)));
  }

  @override
  Future<bool> applyRemoteOp(SyncOp op) {
    return _db.transaction(() async {
      // 拉到即观察:local = max(local, remote) + 1(03 文档 §3)。
      await _observeLamport(op.lamport);
      return switch (op.entity) {
        TaskFields.entity => _applyTaskOp(op),
        ProjectFields.entity => _applyProjectOp(op),
        // 其余实体(area/tag/task_tag)前向兼容跳过,游标照推;
        // 升级后的数据补齐走快照通道(03 文档 §4.3,后续演进)。
        _ => false,
      };
    });
  }

  /// task 实体:行级 __row(set/del)与字段级 LWW。
  Future<bool> _applyTaskOp(SyncOp op) async {
    if (op.field == rowCreateField) {
      return _applyTaskRowOp(op);
    }
    if (!TaskFields.isSyncable(op.field)) {
      return false; // 未知字段:前向兼容地跳过
    }
    final currentRow = await _mirrorOf(
      TaskFields.entity,
      op.entityId,
      op.field,
    );
    final verdict = _lwwVerdict(op, currentRow);
    if (verdict == null) return false; // 重放幂等 / 本地裁决值更高
    await _materialize(op);
    await _putMirror(
      TaskFields.entity,
      op.entityId,
      op.field,
      op.lamport,
      op.deviceId,
      syncOpTypeToJson(op.type),
    );
    return true;
  }

  /// project 实体远端应用(S07 关系完整性):行级创建/墓碑 + 字段级 LWW。
  /// 墓碑与本地 [ProjectRepository.deleteProject] 对称:项目软删,
  /// 项目内活跃任务回收进收件箱;回收经本地写路径生成 oplog,
  /// 使第三台设备凭这些 op 收敛(而非仅本机视图修补)。
  Future<bool> _applyProjectOp(SyncOp op) async {
    if (op.field == rowCreateField) {
      final existing = await _projectByIdOrNull(op.entityId);
      if (op.type == SyncOpType.set) {
        if (existing != null) return false; // 行已存在,幂等
        final raw = (op.value!.value as Map? ?? const {})
            .cast<String, Object?>();
        final now = DateTime.now().millisecondsSinceEpoch;
        await _db.into(_db.projects).insert(_projectRowFromJson(op, raw, now));
        for (final field in raw.keys) {
          if (!ProjectFields.isSyncable(field)) continue;
          await _putMirror(
            ProjectFields.entity,
            op.entityId,
            field,
            op.lamport,
            op.deviceId,
            'set',
          );
        }
        await _putMirror(
          ProjectFields.entity,
          op.entityId,
          rowCreateField,
          op.lamport,
          op.deviceId,
          'set',
        );
        return true;
      }
      // 墓碑:行可能不存在于本副本(未同步到创建 op)—— 只记镜像。
      var landed = false;
      if (existing != null && existing.deletedAt == null) {
        await _recycleProjectTasks(op.entityId);
        final now = DateTime.now().millisecondsSinceEpoch;
        await (_db.update(
          _db.projects,
        )..where((p) => p.id.equals(op.entityId))).write(
          ProjectsCompanion(
            lamport: Value(op.lamport),
            origin: Value(op.deviceId),
            updatedAt: Value(now),
            deletedAt: Value(now),
          ),
        );
        landed = true;
      }
      await _putMirror(
        ProjectFields.entity,
        op.entityId,
        rowCreateField,
        op.lamport,
        op.deviceId,
        'del',
      );
      return landed;
    }
    if (!ProjectFields.isSyncable(op.field)) {
      return false; // 未知字段:前向兼容地跳过
    }
    final currentRow = await _mirrorOf(
      ProjectFields.entity,
      op.entityId,
      op.field,
    );
    final verdict = _lwwVerdict(op, currentRow);
    if (verdict == null) return false;
    await _materializeProjectField(op);
    await _putMirror(
      ProjectFields.entity,
      op.entityId,
      op.field,
      op.lamport,
      op.deviceId,
      syncOpTypeToJson(op.type),
    );
    return true;
  }

  /// 字段级 LWW 判定:返回 null 表示不落地(重放幂等 / 本地裁决值更高)。
  FieldEntry? _lwwVerdict(SyncOp op, FieldLamportRow? currentRow) {
    final incoming = entryFromOp(op);
    final current = currentRow == null
        ? null
        : FieldEntry(
            version: FieldVersion(
              lamport: currentRow.lamport,
              origin: currentRow.origin,
            ),
            type: syncOpTypeFromJson(currentRow.opType),
          );
    if (current != null && current.version == incoming.version) {
      return null; // 同一条写的重放(幂等)
    }
    final winner = current == null ? incoming : resolveEntry(current, incoming);
    if (winner.version != incoming.version) {
      return null; // 本地裁决值更高,忽略
    }
    return incoming;
  }

  /// 远端项目墓碑 → 项目内任务回收(与 TaskRepository.recycleTasksFromProject
  /// 同语义)。必须走本地写路径(per-task tick + oplog + 镜像),
  /// 让回收本身成为 op 传播出去。
  Future<void> _recycleProjectTasks(String projectId) async {
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
      await _editLocalTask(row, {
        'project_id': null,
        if (backToInbox && row.status != TaskStatus.inbox.value)
          'status': TaskStatus.inbox.value,
      });
    }
  }

  /// 本地任务字段写(远端项目回收引发):oplog + 镜像 + 行落地,单 lamport。
  /// 与 TaskRepository._edit 同构;store 内不持有仓库实例(构造环),故就地实现。
  Future<void> _editLocalTask(Task row, Map<String, Object?> changes) async {
    final lamport = await tick();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final entry in changes.entries) {
      final isDel = entry.value == null;
      await _db
          .into(_db.oplog)
          .insert(
            OplogCompanion.insert(
              deviceId: deviceId,
              lamport: lamport,
              entity: TaskFields.entity,
              entityId: row.id,
              field: entry.key,
              op: syncOpTypeToJson(isDel ? SyncOpType.del : SyncOpType.set),
              valueBlob: isDel
                  ? const Value.absent()
                  : Value(
                      jsonEncode(
                        TaskFields.encode(entry.key, entry.value).toJson(),
                      ),
                    ),
            ),
          );
      await _putMirror(
        TaskFields.entity,
        row.id,
        entry.key,
        lamport,
        deviceId,
        isDel ? 'del' : 'set',
      );
    }
    await (_db.update(_db.tasks)..where((t) => t.id.equals(row.id))).write(
      TasksCompanion(
        lamport: Value(lamport),
        origin: Value(deviceId),
        updatedAt: Value(now),
      ),
    );
    for (final entry in changes.entries) {
      await (_db.update(_db.tasks)..where((t) => t.id.equals(row.id))).write(
        TaskFields.companion(entry.key, entry.value),
      );
    }
  }

  /// 整行创建(__row)与行级墓碑(__row del)。
  Future<bool> _applyTaskRowOp(SyncOp op) async {
    final existing = await _taskById(op.entityId);
    if (op.type == SyncOpType.set) {
      if (existing != null) return false; // 行已存在,幂等
      final raw = (op.value!.value as Map? ?? const {}).cast<String, Object?>();
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.into(_db.tasks).insert(_rowFromJson(op, raw, now));
      for (final field in raw.keys) {
        if (!TaskFields.isSyncable(field)) continue;
        await _putMirror(
          TaskFields.entity,
          op.entityId,
          field,
          op.lamport,
          op.deviceId,
          'set',
        );
      }
      await _putMirror(
        TaskFields.entity,
        op.entityId,
        rowCreateField,
        op.lamport,
        op.deviceId,
        'set',
      );
      return true;
    }
    // 墓碑:标记 deleted_at(行可能不存在于本副本,如刚 GC —— 只记镜像)。
    if (existing != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await (_db.update(
        _db.tasks,
      )..where((t) => t.id.equals(op.entityId))).write(
        TasksCompanion(
          lamport: Value(op.lamport),
          origin: Value(op.deviceId),
          updatedAt: Value(now),
          deletedAt: Value(now),
        ),
      );
    }
    await _putMirror(
      TaskFields.entity,
      op.entityId,
      rowCreateField,
      op.lamport,
      op.deviceId,
      'del',
    );
    return true;
  }

  ProjectsCompanion _projectRowFromJson(
    SyncOp op,
    Map<String, Object?> raw,
    int now,
  ) {
    String? str(String k) => raw[k] as String?;
    int? intv(String k) => raw[k] as int?;
    return ProjectsCompanion.insert(
      id: op.entityId,
      name: str('name') ?? '',
      sortKey: str('sort_key') ?? firstSortKey(),
      status: Value(str('status') ?? 'active'),
      note: Value(str('note')),
      parentId: Value(str('parent_id')),
      areaId: Value(str('area_id')),
      reviewCadenceDays: Value(intv('review_cadence_days')),
      nextActionId: Value(str('next_action_id')),
      createdAt: now,
      updatedAt: now,
      lamport: op.lamport,
      origin: op.deviceId,
    );
  }

  /// project 字段落地:行缺失时先建桩行(补拉/快照边界),再写列。
  Future<void> _materializeProjectField(SyncOp op) async {
    final existing = await _projectByIdOrNull(op.entityId);
    if (existing == null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db
          .into(_db.projects)
          .insert(
            ProjectsCompanion.insert(
              id: op.entityId,
              name: '',
              sortKey: firstSortKey(),
              createdAt: now,
              updatedAt: now,
              lamport: op.lamport,
              origin: op.deviceId,
            ),
          );
    }
    final touch = ProjectsCompanion(
      lamport: Value(op.lamport),
      origin: Value(op.deviceId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    if (op.type == SyncOpType.del &&
        ProjectFields.notNullFields.contains(op.field)) {
      await (_db.update(
        _db.projects,
      )..where((p) => p.id.equals(op.entityId))).write(touch);
      return;
    }
    await (_db.update(
      _db.projects,
    )..where((p) => p.id.equals(op.entityId))).write(
      ProjectFields.companion(
        op.field,
        op.type == SyncOpType.set ? op.value!.value : null,
      ),
    );
    await (_db.update(
      _db.projects,
    )..where((p) => p.id.equals(op.entityId))).write(touch);
  }

  TasksCompanion _rowFromJson(SyncOp op, Map<String, Object?> raw, int now) {
    String? str(String k) => raw[k] as String?;
    int? intv(String k) => raw[k] as int?;
    return TasksCompanion.insert(
      id: op.entityId,
      title: str('title') ?? '',
      sortKey: str('sort_key') ?? firstSortKey(),
      status: Value(str('status') ?? 'inbox'),
      note: Value(str('note')),
      startDate: Value(intv('start_date')),
      dueDate: Value(intv('due_date')),
      plannedDate: Value(intv('planned_date')),
      deferDate: Value(intv('defer_date')),
      completedAt: Value(intv('completed_at')),
      reminderAt: Value(intv('reminder_at')),
      recurrence: Value(str('recurrence')),
      estimateMinutes: Value(intv('estimate_minutes')),
      actualMinutes: Value(intv('actual_minutes')),
      energy: Value(str('energy')),
      waitingFor: Value(str('waiting_for')),
      createdAt: now,
      updatedAt: now,
      lamport: op.lamport,
      origin: op.deviceId,
    );
  }

  /// 单字段落地:行缺失时先建桩行(快照/补拉边界),再写列与行级同步列。
  Future<void> _materialize(SyncOp op) async {
    final existing = await _taskById(op.entityId);
    if (existing == null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db
          .into(_db.tasks)
          .insert(
            TasksCompanion.insert(
              id: op.entityId,
              title: '',
              sortKey: firstSortKey(),
              createdAt: now,
              updatedAt: now,
              lamport: op.lamport,
              origin: op.deviceId,
            ),
          );
    }
    final touch = _touchCompanion(op);
    if (op.type == SyncOpType.del &&
        TaskFields.notNullFields.contains(op.field)) {
      await (_db.update(
        _db.tasks,
      )..where((t) => t.id.equals(op.entityId))).write(touch);
      return;
    }
    final fieldWrite = TaskFields.companion(
      op.field,
      op.type == SyncOpType.set ? op.value!.value : null,
    );
    await (_db.update(
      _db.tasks,
    )..where((t) => t.id.equals(op.entityId))).write(fieldWrite);
    await (_db.update(
      _db.tasks,
    )..where((t) => t.id.equals(op.entityId))).write(touch);
  }

  /// 行级同步列(lamport/origin/updated_at):updated_at 仅展示(03 文档 §2.4)。
  TasksCompanion _touchCompanion(SyncOp op) => TasksCompanion(
    lamport: Value(op.lamport),
    origin: Value(op.deviceId),
    updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
  );

  Future<Task?> _taskById(String id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Project?> _projectByIdOrNull(String id) => (_db.select(
    _db.projects,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<FieldLamportRow?> _mirrorOf(
    String entity,
    String entityId,
    String field,
  ) =>
      (_db.select(_db.fieldLamport)..where(
            (f) =>
                f.entity.equals(entity) &
                f.entityId.equals(entityId) &
                f.field.equals(field),
          ))
          .getSingleOrNull();

  Future<void> _putMirror(
    String entity,
    String entityId,
    String field,
    int lamport,
    String origin,
    String opType,
  ) async {
    await _db
        .into(_db.fieldLamport)
        .insertOnConflictUpdate(
          FieldLamportCompanion.insert(
            entity: entity,
            entityId: entityId,
            field: field,
            lamport: lamport,
            origin: origin,
            opType: opType,
          ),
        );
  }

  @override
  Future<void> close() => _db.close();
}
