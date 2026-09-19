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
      if (op.entity != TaskFields.entity) {
        return false; // PoC 只同步任务实体
      }
      if (op.field == rowCreateField) {
        return _applyRowOp(op);
      }
      if (!TaskFields.isSyncable(op.field)) {
        return false; // 未知字段:前向兼容地跳过
      }
      final incoming = entryFromOp(op);
      final currentRow = await _mirrorOf(op.entityId, op.field);
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
        return false; // 同一条写的重放(幂等)
      }
      final winner = current == null
          ? incoming
          : resolveEntry(current, incoming);
      if (winner.version != incoming.version) {
        return false; // 本地裁决值更高,忽略
      }
      await _materialize(op);
      await _putMirror(
        op.entityId,
        op.field,
        op.lamport,
        op.deviceId,
        syncOpTypeToJson(op.type),
      );
      return true;
    });
  }

  /// 整行创建(__row)与行级墓碑(__row del)。
  Future<bool> _applyRowOp(SyncOp op) async {
    final existing = await _taskById(op.entityId);
    if (op.type == SyncOpType.set) {
      if (existing != null) return false; // 行已存在,幂等
      final raw = (op.value!.value as Map? ?? const {}).cast<String, Object?>();
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.into(_db.tasks).insert(_rowFromJson(op, raw, now));
      for (final field in raw.keys) {
        if (!TaskFields.isSyncable(field)) continue;
        await _putMirror(op.entityId, field, op.lamport, op.deviceId, 'set');
      }
      await _putMirror(
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
      op.entityId,
      rowCreateField,
      op.lamport,
      op.deviceId,
      'del',
    );
    return true;
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

  Future<FieldLamportRow?> _mirrorOf(String entityId, String field) =>
      (_db.select(_db.fieldLamport)..where(
            (f) =>
                f.entity.equals(TaskFields.entity) &
                f.entityId.equals(entityId) &
                f.field.equals(field),
          ))
          .getSingleOrNull();

  Future<void> _putMirror(
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
            entity: TaskFields.entity,
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
