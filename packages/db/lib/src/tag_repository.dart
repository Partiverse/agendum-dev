/// 标签仓库(S07):标签组/标签/任务挂签的唯一写路径,与 Task/Project
/// 仓库同构 —— 每次写 = 一个事务(领域校验 + lamport +1 + 行写入 +
/// 字段级 oplog + 裁决镜像)。
///
/// 互斥校验经领域红线 [checkExclusiveAssign](挂签事务内执行)。
/// 同步实体:tag_group / tag 以整行创建 + 字段编辑;task_tag 关联行以
/// `__row` set/del 表达挂签/摘签,entityId 取 `taskId:tagId` 复合串
/// (field_lamport 主键为 (entity, entityId, field),复合串保证唯一)。
library;

import 'dart:convert';

import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'local_sync_store.dart';

class TagRepository {
  TagRepository(this._db, this._sync);

  final AgendumDatabase _db;
  final DriftLocalSyncStore _sync;

  // ---- 写路径 ----

  Future<TagGroup> createGroup({
    required String name,
    bool exclusive = false,
  }) => _db.transaction(() async {
    final lamport = await _sync.tick();
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = const Uuid().v7();
    final rowJson = <String, Object?>{
      'name': name,
      'exclusive': exclusive ? 1 : 0,
    };
    await _db
        .into(_db.tagGroups)
        .insert(
          TagGroupsCompanion.insert(
            id: id,
            name: name,
            exclusive: Value(exclusive ? 1 : 0),
            createdAt: now,
            updatedAt: now,
            lamport: lamport,
            origin: _sync.deviceId,
          ),
        );
    await _appendOp(
      entity: SyncEntities.tagGroup,
      entityId: id,
      lamport: lamport,
      value: OpValue(OpValueTypes.json, rowJson),
    );
    for (final field in rowJson.keys) {
      await _putMirror(SyncEntities.tagGroup, id, field, lamport, 'set');
    }
    await _putMirror(SyncEntities.tagGroup, id, rowCreateField, lamport, 'set');
    return (_db.select(
      _db.tagGroups,
    )..where((g) => g.id.equals(id))).getSingle();
  });

  /// groupId 为空 = 自由标签;组必须存在且未删。
  Future<Tag> createTag({required String name, String? groupId}) =>
      _db.transaction(() async {
        if (groupId != null) {
          final group =
              await (_db.select(_db.tagGroups)
                    ..where((g) => g.id.equals(groupId) & g.deletedAt.isNull()))
                  .getSingleOrNull();
          if (group == null) {
            throw ArgumentError.value(groupId, 'groupId', '标签组不存在');
          }
        }
        final lamport = await _sync.tick();
        final now = DateTime.now().millisecondsSinceEpoch;
        final id = const Uuid().v7();
        final rowJson = <String, Object?>{'name': name, 'group_id': ?groupId};
        await _db
            .into(_db.tags)
            .insert(
              TagsCompanion.insert(
                id: id,
                name: name,
                groupId: Value(groupId),
                createdAt: now,
                updatedAt: now,
                lamport: lamport,
                origin: _sync.deviceId,
              ),
            );
        await _appendOp(
          entity: SyncEntities.tag,
          entityId: id,
          lamport: lamport,
          value: OpValue(OpValueTypes.json, rowJson),
        );
        for (final field in rowJson.keys) {
          await _putMirror(SyncEntities.tag, id, field, lamport, 'set');
        }
        await _putMirror(SyncEntities.tag, id, rowCreateField, lamport, 'set');
        return (_db.select(
          _db.tags,
        )..where((t) => t.id.equals(id))).getSingle();
      });

  /// 任务挂签(互斥校验是领域红线)。重复挂签幂等;曾摘除的关联行复活。
  Future<void> assignTag(
    String taskId,
    String tagId,
  ) => _db.transaction(() async {
    final tag = await _tagOrThrow(tagId);
    final current = await tagsOfTaskSnapshot(taskId);
    checkExclusiveAssign(current, tag);
    final existing = await _taskTagRow(taskId, tagId);
    if (existing != null && existing.deletedAt == null) return; // 幂等
    final lamport = await _sync.tick();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (existing != null) {
      await (_db.update(_db.taskTags)
            ..where((tt) => tt.taskId.equals(taskId) & tt.tagId.equals(tagId)))
          .write(
            TaskTagsCompanion(
              deletedAt: const Value(null),
              updatedAt: Value(now),
              lamport: Value(lamport),
              origin: Value(_sync.deviceId),
            ),
          );
    } else {
      await _db
          .into(_db.taskTags)
          .insert(
            TaskTagsCompanion.insert(
              taskId: taskId,
              tagId: tagId,
              createdAt: now,
              updatedAt: now,
              lamport: lamport,
              origin: _sync.deviceId,
            ),
          );
    }
    await _appendOp(
      entity: SyncEntities.taskTag,
      entityId: _taskTagEntityId(taskId, tagId),
      lamport: lamport,
      value: OpValue(OpValueTypes.json, {'task_id': taskId, 'tag_id': tagId}),
    );
    await _putMirror(
      SyncEntities.taskTag,
      _taskTagEntityId(taskId, tagId),
      rowCreateField,
      lamport,
      'set',
    );
  });

  /// 摘签(软删墓碑;幂等)。
  Future<void> unassignTag(String taskId, String tagId) => _db.transaction(
    () async {
      final existing = await _taskTagRow(taskId, tagId);
      if (existing == null || existing.deletedAt != null) return; // 幂等
      final lamport = await _sync.tick();
      final now = DateTime.now().millisecondsSinceEpoch;
      await (_db.update(_db.taskTags)
            ..where((tt) => tt.taskId.equals(taskId) & tt.tagId.equals(tagId)))
          .write(
            TaskTagsCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
              lamport: Value(lamport),
              origin: Value(_sync.deviceId),
            ),
          );
      await _appendOp(
        entity: SyncEntities.taskTag,
        entityId: _taskTagEntityId(taskId, tagId),
        type: SyncOpType.del,
        lamport: lamport,
      );
      await _putMirror(
        SyncEntities.taskTag,
        _taskTagEntityId(taskId, tagId),
        rowCreateField,
        lamport,
        'del',
      );
    },
  );

  // ---- 读路径(快照语义,与 Task/Project 仓库一致) ----

  Future<List<TagGroup>> groupsSnapshot() =>
      (_db.select(_db.tagGroups)
            ..where((g) => g.deletedAt.isNull())
            ..orderBy([(g) => OrderingTerm.asc(g.createdAt)]))
          .get();

  Future<List<Tag>> tagsSnapshot() =>
      (_db.select(_db.tags)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  /// 全量标签目录(tags × tag_groups 投影,供互斥校验与选择器)。
  Future<List<TagDescriptor>> tagDescriptorsSnapshot() async {
    final joins = await (_db.select(_db.tags).join([
      leftOuterJoin(
        _db.tagGroups,
        _db.tagGroups.id.equalsExp(_db.tags.groupId),
      ),
    ])..where(_db.tags.deletedAt.isNull())).get();
    return [
      for (final row in joins)
        _toDescriptor(
          row.readTable(_db.tags),
          row.readTableOrNull(_db.tagGroups),
        ),
    ];
  }

  /// 单任务的标签(描述符投影)。
  Future<List<TagDescriptor>> tagsOfTaskSnapshot(String taskId) async {
    final joins =
        await (_db.select(_db.taskTags).join([
              innerJoin(_db.tags, _db.tags.id.equalsExp(_db.taskTags.tagId)),
              leftOuterJoin(
                _db.tagGroups,
                _db.tagGroups.id.equalsExp(_db.tags.groupId),
              ),
            ])..where(
              _db.taskTags.deletedAt.isNull() &
                  _db.taskTags.taskId.equals(taskId),
            ))
            .get();
    return [
      for (final row in joins)
        _toDescriptor(
          row.readTable(_db.tags),
          row.readTableOrNull(_db.tagGroups),
        ),
    ];
  }

  /// 全任务的标签映射(视图层一次性装配,免逐行查询)。
  Future<Map<String, List<TagDescriptor>>> allTaskTagsSnapshot() async {
    final joins = await (_db.select(_db.taskTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.taskTags.tagId)),
      leftOuterJoin(
        _db.tagGroups,
        _db.tagGroups.id.equalsExp(_db.tags.groupId),
      ),
    ])..where(_db.taskTags.deletedAt.isNull())).get();
    final map = <String, List<TagDescriptor>>{};
    for (final row in joins) {
      final descriptor = _toDescriptor(
        row.readTable(_db.tags),
        row.readTableOrNull(_db.tagGroups),
      );
      map
          .putIfAbsent(row.readTable(_db.taskTags).taskId, () => [])
          .add(descriptor);
    }
    return map;
  }

  // ---- 内部 ----

  TagDescriptor _toDescriptor(Tag tag, TagGroup? group) => TagDescriptor(
    id: tag.id,
    name: tag.name,
    groupId: tag.groupId,
    groupName: group?.name,
    groupExclusive: group?.exclusive == 1,
  );

  Future<TagDescriptor> _tagOrThrow(String tagId) async {
    final rows = await (_db.select(_db.tags).join([
      leftOuterJoin(
        _db.tagGroups,
        _db.tagGroups.id.equalsExp(_db.tags.groupId),
      ),
    ])..where(_db.tags.id.equals(tagId) & _db.tags.deletedAt.isNull())).get();
    if (rows.isEmpty) {
      throw ArgumentError.value(tagId, 'tagId', '标签不存在或已删');
    }
    return _toDescriptor(
      rows.single.readTable(_db.tags),
      rows.single.readTableOrNull(_db.tagGroups),
    );
  }

  Future<TaskTag?> _taskTagRow(String taskId, String tagId) =>
      (_db.select(_db.taskTags)
            ..where((tt) => tt.taskId.equals(taskId) & tt.tagId.equals(tagId)))
          .getSingleOrNull();

  String _taskTagEntityId(String taskId, String tagId) => '$taskId:$tagId';

  Future<void> _appendOp({
    required String entity,
    required String entityId,
    required int lamport,
    SyncOpType type = SyncOpType.set,
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
            field: rowCreateField,
            op: syncOpTypeToJson(type),
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
