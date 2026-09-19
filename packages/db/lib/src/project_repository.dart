/// 项目/领域仓库:客户端唯一写路径(S06),与 TaskRepository 同构:
/// 每次写 = 一个事务(领域校验 + lamport +1 + 行更新 + 字段级 oplog + 裁决镜像)。
///
/// 远端应用:DriftLocalSyncStore.applyRemoteOp 目前只落地 task 实体,
/// project/area 的远端 op 前向兼容地跳过(推上去不丢,双端收敛随 S07 接入)。
library;

import 'dart:convert';

import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'local_sync_store.dart';
import 'project_fields.dart';

class ProjectRepository {
  ProjectRepository(this._db, this._sync);

  final AgendumDatabase _db;
  final DriftLocalSyncStore _sync;

  // ---- 写路径 ----

  Future<Project> createProject({
    required String name,
    String? areaId,
    String? parentId,
    String? note,
  }) => _db.transaction(() async {
    final lamport = await _sync.tick();
    final now = DateTime.now().millisecondsSinceEpoch;
    final key = await _nextSortKey();
    final id = const Uuid().v7();
    final rowJson = <String, Object?>{
      'name': name,
      'status': ProjectStatus.active.value,
      'sort_key': key,
      'area_id': ?areaId,
      'parent_id': ?parentId,
      'note': ?note,
    };
    await _db
        .into(_db.projects)
        .insert(
          ProjectsCompanion.insert(
            id: id,
            name: name,
            sortKey: key,
            areaId: Value(areaId),
            parentId: Value(parentId),
            note: Value(note),
            createdAt: now,
            updatedAt: now,
            lamport: lamport,
            origin: _sync.deviceId,
          ),
        );
    await _appendOp(
      entity: ProjectFields.entity,
      entityId: id,
      field: rowCreateField,
      lamport: lamport,
      value: OpValue(OpValueTypes.json, rowJson),
    );
    for (final field in rowJson.keys) {
      await _putMirror(ProjectFields.entity, id, field, lamport, 'set');
    }
    await _putMirror(ProjectFields.entity, id, rowCreateField, lamport, 'set');
    return (_db.select(
      _db.projects,
    )..where((p) => p.id.equals(id))).getSingle();
  });

  Future<Area> createArea({required String name, String? color}) =>
      _db.transaction(() async {
        final lamport = await _sync.tick();
        final now = DateTime.now().millisecondsSinceEpoch;
        final key = await _nextAreaSortKey();
        final id = const Uuid().v7();
        final rowJson = <String, Object?>{
          'name': name,
          'sort_key': key,
          'color': ?color,
        };
        await _db
            .into(_db.areas)
            .insert(
              AreasCompanion.insert(
                id: id,
                name: name,
                sortKey: key,
                color: Value(color),
                createdAt: now,
                updatedAt: now,
                lamport: lamport,
                origin: _sync.deviceId,
              ),
            );
        await _appendOp(
          entity: AreaFields.entity,
          entityId: id,
          field: rowCreateField,
          lamport: lamport,
          value: OpValue(OpValueTypes.json, rowJson),
        );
        for (final field in rowJson.keys) {
          await _putMirror(AreaFields.entity, id, field, lamport, 'set');
        }
        await _putMirror(AreaFields.entity, id, rowCreateField, lamport, 'set');
        return (_db.select(
          _db.areas,
        )..where((a) => a.id.equals(id))).getSingle();
      });

  /// 改名/备注/归属等字段级编辑(oplog 去重:与现值相同则跳过)。
  Future<void> editProject(String id, Map<String, Object?> changes) =>
      _db.transaction(() async {
        final row = await _projectById(id);
        await _editEntity(
          entity: ProjectFields.entity,
          notNull: ProjectFields.notNullFields,
          row: _rowValues(row),
          id: row.id,
          changes: changes,
          writeRow: (updates) async {
            await (_db.update(
              _db.projects,
            )..where((p) => p.id.equals(row.id))).write(
              ProjectsCompanion(
                lamport: Value(updates.lamport),
                origin: Value(_sync.deviceId),
                updatedAt: Value(updates.nowMs),
              ),
            );
            for (final entry in changes.entries) {
              if (_rowValues(row)[entry.key] == entry.value) continue;
              await (_db.update(_db.projects)
                    ..where((p) => p.id.equals(row.id)))
                  .write(ProjectFields.companion(entry.key, entry.value));
            }
          },
        );
      });

  /// 项目状态流转(领域红线:经 transitionProject 校验)。
  Future<void> setProjectStatus(String id, ProjectStatus target) =>
      _db.transaction(() async {
        final row = await _projectById(id);
        transitionProject(ProjectStatus.fromValue(row.status), target);
        await editProject(id, {'status': target.value});
      });

  Future<void> renameProject(String id, String name) =>
      editProject(id, {'name': name});

  Future<void> renameArea(String id, String name) => _db.transaction(() async {
    final row = await (_db.select(
      _db.areas,
    )..where((a) => a.id.equals(id))).getSingle();
    await _editEntity(
      entity: AreaFields.entity,
      notNull: AreaFields.notNullFields,
      row: {'name': row.name, 'color': row.color, 'sort_key': row.sortKey},
      id: row.id,
      changes: {'name': name},
      writeRow: (updates) async {
        await (_db.update(_db.areas)..where((a) => a.id.equals(row.id))).write(
          AreasCompanion(
            lamport: Value(updates.lamport),
            origin: Value(_sync.deviceId),
            updatedAt: Value(updates.nowMs),
          ),
        );
        await (_db.update(_db.areas)..where((a) => a.id.equals(row.id))).write(
          AreasCompanion(name: Value(name)),
        );
      },
    );
  });

  // ---- 读路径(快照语义,与 TaskRepository 一致) ----

  /// 项目列表(含未完成任务数,按 sort_key)。done 项目仍列出但计数为 0 口径另议。
  Future<List<(Project, int)>> projectListSnapshot() async {
    final rows =
        await (_db.select(_db.projects)
              ..where((p) => p.deletedAt.isNull())
              ..orderBy([(p) => OrderingTerm.asc(p.sortKey)]))
            .get();
    final countsExp = countAll();
    final countsQuery = _db.selectOnly(_db.tasks)
      ..addColumns([_db.tasks.projectId, countsExp])
      ..where(
        _db.tasks.deletedAt.isNull() &
            _db.tasks.status.isNotIn([
              TaskStatus.done.value,
              TaskStatus.trashed.value,
            ]),
      )
      ..groupBy([_db.tasks.projectId]);
    final counts = <String, int>{};
    for (final row in await countsQuery.get()) {
      final pid = row.read(_db.tasks.projectId);
      if (pid != null) counts[pid] = row.read(countsExp) ?? 0;
    }
    return [for (final p in rows) (p, counts[p.id] ?? 0)];
  }

  Future<List<Area>> areasSnapshot() =>
      (_db.select(_db.areas)
            ..where((a) => a.deletedAt.isNull())
            ..orderBy([(a) => OrderingTerm.asc(a.sortKey)]))
          .get();

  /// 项目内任务(收件箱/下一步等活跃态优先展示,trashed 排除)。
  Future<List<Task>> tasksInProjectSnapshot(String projectId) =>
      (_db.select(_db.tasks)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.projectId.equals(projectId) &
                  t.status.isNotIn([TaskStatus.trashed.value]),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.sortKey)]))
          .get();

  Future<Project> projectById(String id) => _projectById(id);

  // ---- 内部 ----

  Future<Project> _projectById(String id) =>
      (_db.select(_db.projects)..where((p) => p.id.equals(id))).getSingle();

  Map<String, Object?> _rowValues(Project row) => {
    'name': row.name,
    'note': row.note,
    'status': row.status,
    'parent_id': row.parentId,
    'area_id': row.areaId,
    'review_cadence_days': row.reviewCadenceDays,
    'next_action_id': row.nextActionId,
    'sort_key': row.sortKey,
  };

  Future<String> _nextSortKey() async {
    final row =
        await (_db.select(_db.projects)
              ..orderBy([(p) => OrderingTerm.desc(p.sortKey)])
              ..limit(1))
            .getSingleOrNull();
    return appendSortKey(row?.sortKey);
  }

  /// project/area 共用的字段级编辑体(task 侧同型逻辑的抽象)。
  Future<void> _editEntity({
    required String entity,
    required Set<String> notNull,
    required Map<String, Object?> row,
    required String id,
    required Map<String, Object?> changes,
    required Future<void> Function(_EditStamp updates) writeRow,
  }) async {
    final lamport = await _sync.tick();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    var touched = false;
    for (final entry in changes.entries) {
      final field = entry.key;
      final newValue = entry.value;
      if (row[field] == newValue) continue;
      if (newValue == null && notNull.contains(field)) continue; // 非空列跳过 del
      touched = true;
      await _appendOp(
        entity: entity,
        entityId: id,
        field: field,
        lamport: lamport,
        value: newValue == null ? null : _encode(entity, field, newValue),
      );
      await _putMirror(
        entity,
        id,
        field,
        lamport,
        newValue == null ? 'del' : 'set',
      );
    }
    if (!touched) return;
    await writeRow(_EditStamp(lamport: lamport, nowMs: nowMs));
  }

  Future<String> _nextAreaSortKey() async {
    final row =
        await (_db.select(_db.areas)
              ..orderBy([(a) => OrderingTerm.desc(a.sortKey)])
              ..limit(1))
            .getSingleOrNull();
    return appendSortKey(row?.sortKey);
  }

  Future<void> _appendOp({
    required String entity,
    required String entityId,
    required String field,
    required int lamport,
    OpValue? value,
  }) async {
    await _db
        .into(_db.oplog)
        .insert(
          OplogCompanion.insert(
            deviceId: _sync.deviceId,
            lamport: lamport,
            entity: entity,
            entityId: entityId,
            field: field,
            op: syncOpTypeToJson(SyncOpType.set),
            valueBlob: value == null
                ? const Value.absent()
                : Value(jsonEncode(value.toJson())),
          ),
        );
  }

  Future<void> _putMirror(
    String entity,
    String entityId,
    String field,
    int lamport,
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
            origin: _sync.deviceId,
            opType: opType,
          ),
        );
  }
}

final class _EditStamp {
  _EditStamp({required this.lamport, required this.nowMs});

  final int lamport;
  final int nowMs;
}

// 编码入口按实体分流(供 _editEntity 闭包引用)。
OpValue? _encode(String entity, String field, Object? value) {
  if (entity == ProjectFields.entity) {
    return ProjectFields.encode(field, value);
  }
  if (entity == AreaFields.entity) {
    return AreaFields.encode(field, value);
  }
  throw ArgumentError('未知实体:$entity');
}
