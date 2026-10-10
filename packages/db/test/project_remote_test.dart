/// 远端 project 实体 op 应用:行级创建/墓碑 + 字段级 LWW。
/// 关系完整性(S07):远端删项目 → 本地活跃任务回收进收件箱,
/// 且回收经本地写路径生成 oplog,向第三台设备传播。
library;

import 'package:agendum_db/agendum_db.dart';
import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:test/test.dart';

SyncOp projectCreate(String dev, int lamport, String id, String name) => SyncOp(
  deviceId: dev,
  lamport: lamport,
  entity: 'project',
  entityId: id,
  field: rowCreateField,
  type: SyncOpType.set,
  value: OpValue(OpValueTypes.json, {
    'name': name,
    'status': 'active',
    'sort_key': 'zzzz',
  }),
);

SyncOp projectField(
  String dev,
  int lamport,
  String id,
  String field,
  String value,
) => SyncOp(
  deviceId: dev,
  lamport: lamport,
  entity: 'project',
  entityId: id,
  field: field,
  type: SyncOpType.set,
  value: OpValue(const {'name': 'str', 'note': 'str'}[field]!, value),
);

SyncOp projectDelete(String dev, int lamport, String id) => SyncOp(
  deviceId: dev,
  lamport: lamport,
  entity: 'project',
  entityId: id,
  field: rowCreateField,
  type: SyncOpType.del,
);

void main() {
  late AgendumDatabase db;
  late DriftLocalSyncStore sync;
  late TaskRepository repo;
  late ProjectRepository projects;

  setUp(() async {
    db = openInMemoryDb();
    sync = await DriftLocalSyncStore.open(db);
    repo = TaskRepository(db, sync);
    projects = ProjectRepository(db, sync, repo);
  });
  tearDown(() async => db.close());

  test('远端项目创建 → 落地;重放幂等;未知字段跳过', () async {
    expect(
      await sync.applyRemoteOp(projectCreate('dvc_a', 5, 'p1', '装修')),
      isTrue,
    );
    final row = await projects.projectById('p1');
    expect(row.name, '装修');
    expect(row.sortKey, 'zzzz');
    expect(row.lamport, 5);

    expect(
      await sync.applyRemoteOp(projectCreate('dvc_a', 5, 'p1', '装修')),
      isFalse,
      reason: '行已存在,重放幂等',
    );

    final unknown = SyncOp(
      deviceId: 'dvc_a',
      lamport: 6,
      entity: 'project',
      entityId: 'p1',
      field: 'future_field',
      type: SyncOpType.set,
      value: const OpValue('str', 'x'),
    );
    expect(await sync.applyRemoteOp(unknown), isFalse, reason: '前向兼容跳过');
  });

  test('远端项目删除 → 项目软删 + 活跃任务回收进收件箱 + 回收 op 入队', () async {
    final p = await projects.createProject(name: '搬家');
    final t1 = await repo.addManual('打包书籍');
    await repo.setTaskProject(t1.id, p.id);
    await repo.promoteToNext(t1.id);
    final t2 = await repo.addManual('已完成杂事');
    await repo.setTaskProject(t2.id, p.id);
    await repo.toggleDone(t2.id);
    final localClock = sync.lamport;

    final del = projectDelete('dvc_z', localClock + 10, p.id);
    expect(await sync.applyRemoteOp(del), isTrue);

    expect(
      (await projects.projectById(p.id)).deletedAt,
      isNotNull,
      reason: '项目软删',
    );

    final t1row = await repo.byId(t1.id);
    expect(t1row.projectId, isNull, reason: 'project_id 置空');
    expect(t1row.status, TaskStatus.inbox.value, reason: '活跃任务回收进收件箱');

    final t2row = await repo.byId(t2.id);
    expect(t2row.projectId, isNull);
    expect(t2row.status, TaskStatus.done.value, reason: 'done 保持完成');

    // 回收走本地写路径:本设备产生新的回收 op(向第三端传播)。
    final pending = await sync.takePendingOps();
    final delOps = pending
        .where(
          (o) =>
              o.op.entityId == t1.id &&
              o.op.field == 'project_id' &&
              o.op.type == SyncOpType.del,
        )
        .toList();
    expect(delOps, hasLength(1), reason: '回收生成 project_id del op');
    expect(delOps.single.op.lamport, greaterThan(localClock));

    // 重放幂等:同一墓碑再应用 → false,不重复回收。
    expect(await sync.applyRemoteOp(del), isFalse);
    expect(
      (await sync.takePendingOps()).where(
        (o) => o.op.entityId == t1.id && o.op.field == 'project_id',
      ),
      hasLength(2),
      reason: '仅原有的 set 与一次回收 del,无重复回收',
    );
  });

  test('远端项目字段 LWW:stale 忽略,更高 lamport 胜出', () async {
    await sync.applyRemoteOp(projectCreate('dvc_a', 5, 'p1', '装修'));

    expect(
      await sync.applyRemoteOp(projectField('dvc_b', 3, 'p1', 'name', '旧名')),
      isFalse,
      reason: 'stale 忽略',
    );
    expect((await projects.projectById('p1')).name, '装修');

    expect(
      await sync.applyRemoteOp(projectField('dvc_b', 6, 'p1', 'name', '新名')),
      isTrue,
    );
    expect((await projects.projectById('p1')).name, '新名');
  });
}
