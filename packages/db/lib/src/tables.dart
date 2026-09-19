/// Drift 表定义 —— SQLite DDL v2(03 文档 §2)。
///
/// v2(S06)新增 areas / projects 实体;同步基建三表
/// (oplog / sync_state / field_lamport)自 v1 全量落地。外键约束不启用:
/// 跨实体引用以应用层完整性规则维护(S07 落地项目删除→任务回收件箱)。
///
/// field_lamport 是 03 文档 §2.4 之外补充的客户端表:pull 应用时按
/// (lamport, origin, op) 判定远端 op 是否胜出,与服务端 entity_lamport
/// 同构 —— 保证重放/重拉幂等(03 文档 §4.3「对端 lamport ≤ 本地裁决值 → 忽略」)。
library;

import 'package:drift/drift.dart';

/// tasks 表(03 文档 §2.2)。
@TableIndex(name: 'idx_tasks_status', columns: {#status, #deletedAt})
@TableIndex(name: 'idx_tasks_dates', columns: {#dueDate, #plannedDate})
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get projectId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('inbox'))();
  IntColumn get startDate => integer().nullable()();
  IntColumn get dueDate => integer().nullable()();
  IntColumn get plannedDate => integer().nullable()();
  IntColumn get deferDate => integer().nullable()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get reminderAt => integer().nullable()();
  TextColumn get recurrence => text().nullable()();
  IntColumn get estimateMinutes => integer().nullable()();
  IntColumn get actualMinutes => integer().nullable()();
  TextColumn get energy => text().nullable()();
  TextColumn get waitingFor => text().nullable()();
  TextColumn get sortKey => text()();

  // 公共同步列(03 文档 §2.1)。
  IntColumn get createdAt => integer()(); // epoch ms
  IntColumn get updatedAt => integer()(); // epoch ms(仅展示,不参与裁决)
  IntColumn get lamport => integer()();
  TextColumn get origin => text()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// areas 表(03 文档 §2.2):任务与项目的上层归属,无状态字段。
@DataClassName('Area')
class Areas extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get sortKey => text()();

  // 公共同步列(03 文档 §2.1)。
  IntColumn get createdAt => integer()(); // epoch ms
  IntColumn get updatedAt => integer()();
  IntColumn get lamport => integer()();
  TextColumn get origin => text()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// projects 表(03 文档 §2.2):嵌套 + area 归属 + 显式 next action 指针。
@TableIndex(name: 'idx_projects_status', columns: {#status, #deletedAt})
@DataClassName('Project')
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get areaId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get note => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get reviewCadenceDays => integer().nullable()();
  TextColumn get nextActionId => text().nullable()();
  TextColumn get sortKey => text()();

  // 公共同步列(03 文档 §2.1)。
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get lamport => integer()();
  TextColumn get origin => text()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// oplog:本地待推送/已推送日志(03 文档 §2.4)。
/// value_blob 在开发模式存 OpValue JSON 明文;E2EE 时改密文(S08)。
@DataClassName('OplogRow')
class Oplog extends Table {
  IntColumn get localSeq => integer().autoIncrement()();
  IntColumn get serverSeq => integer().nullable()();
  TextColumn get deviceId => text()();
  IntColumn get lamport => integer()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get field => text()();
  TextColumn get op => text()(); // set|del
  TextColumn get valueBlob => text().nullable()();
  TextColumn get valueMeta => text().nullable()();
  IntColumn get pushedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {localSeq};
}

/// sync_state:本设备时钟与拉取游标(03 文档 §2.4)。
@DataClassName('SyncStateRow')
class SyncState extends Table {
  TextColumn get deviceId => text()();
  IntColumn get lamport => integer()();
  IntColumn get lastPullSeq => integer().withDefault(const Constant(0))();
  IntColumn get lastPushAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {deviceId};
}

/// 字段裁决镜像(见文件头说明)。
@DataClassName('FieldLamportRow')
class FieldLamport extends Table {
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get field => text()();
  IntColumn get lamport => integer()();
  TextColumn get origin => text()();
  TextColumn get opType => text()(); // set|del(平局"删除胜"的裁决输入)

  @override
  Set<Column> get primaryKey => {entity, entityId, field};
}
