/// ProjectRepository 写路径:项目状态机 + 同事务字段级 oplog(S06)。
library;

import 'package:agendum_db/agendum_db.dart';
import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:test/test.dart';

void main() {
  late AgendumDatabase db;
  late DriftLocalSyncStore sync;
  late ProjectRepository repo;
  late TaskRepository tasks;

  setUp(() async {
    db = openInMemoryDb();
    sync = await DriftLocalSyncStore.open(db);
    tasks = TaskRepository(db, sync);
    repo = ProjectRepository(db, sync, tasks);
  });
  tearDown(() async => db.close());

  test('创建项目:行落地 + __row 整行 op(entity=project)', () async {
    final area = await repo.createArea(name: '工作');
    final p = await repo.createProject(name: '程簿 1.0', areaId: area.id);
    expect(p.name, '程簿 1.0');
    expect(p.status, 'active');
    expect(p.areaId, area.id);

    final ops = await sync.takePendingOps();
    final create = ops
        .map((e) => e.op)
        .firstWhere((o) => o.entityId == p.id && o.field == rowCreateField);
    expect(create.entity, 'project');
    final rowJson = create.value!.value as Map;
    expect(rowJson['name'], '程簿 1.0');
    expect(rowJson['status'], 'active');
    expect(rowJson['area_id'], area.id);
  });

  test('renameProject:字段级 set op,值相同则零 op', () async {
    final p = await repo.createProject(name: '旧名');
    final before = (await sync.takePendingOps()).length;
    await repo.renameProject(p.id, '旧名'); // 幂等写
    expect((await sync.takePendingOps()).length, before);
    await repo.renameProject(p.id, '新名');
    final ops = (await sync.takePendingOps())
        .map((e) => e.op)
        .where((o) => o.field == 'name' && o.entityId == p.id)
        .toList();
    expect(ops, hasLength(1));
    expect(ops.single.value!.value, '新名');
  });

  test('setProjectStatus:走领域状态机,非法流转抛出', () async {
    final p = await repo.createProject(name: '迁移');
    await repo.setProjectStatus(p.id, ProjectStatus.onHold);
    expect((await repo.projectById(p.id)).status, ProjectStatus.onHold.value);
    await repo.setProjectStatus(p.id, ProjectStatus.done);
    expect((await repo.projectById(p.id)).status, ProjectStatus.done.value);
    await expectLater(
      repo.setProjectStatus(p.id, ProjectStatus.onHold),
      throwsArgumentError,
    );
  });

  test('项目列表快照:未完成任务计数', () async {
    final p = await repo.createProject(name: '搬家');
    final t1 = await tasks.addManual('联系搬家公司');
    await tasks.setTaskProject(t1.id, p.id);
    final t2 = await tasks.addManual('打包书籍');
    await tasks.setTaskProject(t2.id, p.id);
    await tasks.toggleDone(t2.id);
    await tasks.addManual('未挂项目的任务');

    final list = await repo.projectListSnapshot();
    final entry = list.firstWhere((e) => e.$1.id == p.id);
    expect(entry.$2, 1); // t2 已完成,不计
  });

  test('项目内任务快照:trashed 排除', () async {
    final p = await repo.createProject(name: '装修');
    final t = await tasks.addManual('选瓷砖');
    await tasks.setTaskProject(t.id, p.id);
    final other = await tasks.addManual('无关任务');
    await tasks.setTaskProject(other.id, p.id);
    await tasks.promoteToNext(t.id);

    final rows = await repo.tasksInProjectSnapshot(p.id);
    expect(rows.map((r) => r.id), containsAll([t.id, other.id]));
  });
}
