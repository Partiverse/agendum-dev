/// S07 关系完整性(项目删除→任务回收件箱)+ 拖拽排序(分数索引)。
library;

import 'package:agendum_db/agendum_db.dart';
import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:test/test.dart';

void main() {
  late AgendumDatabase db;
  late DriftLocalSyncStore sync;
  late TaskRepository tasks;
  late ProjectRepository projects;

  setUp(() async {
    db = openInMemoryDb();
    sync = await DriftLocalSyncStore.open(db);
    tasks = TaskRepository(db, sync);
    projects = ProjectRepository(db, sync, tasks);
  });
  tearDown(() async => db.close());

  group('关系完整性:项目删除→任务回收件箱', () {
    test('活跃任务(next/someday/inbox)回 inbox,project_id 置空', () async {
      final p = await projects.createProject(name: '装修');
      final next = await tasks.addManual('选瓷砖');
      await tasks.promoteToNext(next.id);
      final someday = await tasks.addManual('考虑换地板');
      await tasks.setTaskStatus(someday.id, TaskStatus.someday);
      for (final t in [next, someday]) {
        await tasks.setTaskProject(t.id, p.id);
      }

      await projects.deleteProject(p.id);

      final row1 = await tasks.byId(next.id);
      expect(row1.status, TaskStatus.inbox.value);
      expect(row1.projectId, isNull);
      final row2 = await tasks.byId(someday.id);
      expect(row2.status, TaskStatus.inbox.value);
      expect(row2.projectId, isNull);
    });

    test('waiting/done 保持状态,project_id 仍置空', () async {
      final p = await projects.createProject(name: '程簿 1.0');
      final waiting = await tasks.addManual('等法务审条款');
      await tasks.setTaskStatus(waiting.id, TaskStatus.waiting);
      await tasks.setTaskProject(waiting.id, p.id);
      final done = await tasks.addManual('写需求初稿');
      await tasks.toggleDone(done.id);
      await tasks.setTaskProject(done.id, p.id);

      await projects.deleteProject(p.id);

      final w = await tasks.byId(waiting.id);
      expect(w.status, TaskStatus.waiting.value);
      expect(w.projectId, isNull);
      final d = await tasks.byId(done.id);
      expect(d.status, TaskStatus.done.value);
      expect(d.projectId, isNull);
      expect(d.completedAt, isNotNull);
    });

    test('项目软删墓碑:__row del op + 幂等', () async {
      final p = await projects.createProject(name: '一次性项目');
      expect(await projects.deleteProject(p.id), greaterThanOrEqualTo(0));
      final row = await projects.projectById(p.id);
      expect(row.deletedAt, isNotNull);
      expect(await projects.deleteProject(p.id), 0); // 幂等

      final dels = (await sync.takePendingOps())
          .map((e) => e.op)
          .where(
            (o) =>
                o.entity == 'project' &&
                o.type == SyncOpType.del &&
                o.field == rowCreateField,
          )
          .toList();
      expect(dels, hasLength(1));

      // 已删项目不在列表
      expect(
        (await projects.projectListSnapshot()).where((e) => e.$1.id == p.id),
        isEmpty,
      );
    });
  });

  group('拖拽排序:reorderTasks', () {
    Future<List<String>> seedThree() async {
      final a = await tasks.addManual('A');
      final b = await tasks.addManual('B');
      final c = await tasks.addManual('C');
      return [a.id, b.id, c.id];
    }

    test('创建头插:后建的在快照前面', () async {
      final ids = await seedThree();
      final anytimeKeys = [for (final t in await tasks.anytimeSnapshot()) t.id];
      // anytime 只含 next/someday;此处全在 inbox,改用收件箱快照验证
      final order = [for (final t in await tasks.inboxSnapshot()) t.id];
      expect(order, [ids[2], ids[1], ids[0]]);
      expect(anytimeKeys, isEmpty);
    });

    test('单顶置移动:仅移动项变键,其余不动', () async {
      final ids = await seedThree(); // 快照序:C,B,A
      final before = {
        for (final t in await tasks.inboxSnapshot()) t.id: t.sortKey,
      };
      await tasks.reorderTasks([ids[0], ids[2], ids[1]]); // A 置顶
      final after = {
        for (final t in await tasks.inboxSnapshot()) t.id: t.sortKey,
      };
      expect(after[ids[0]], isNotNull);
      // C、B 键不变(它们之间的相对序未变,移动项插在其间)
      expect(after[ids[2]], before[ids[2]]);
      expect(after[ids[1]], before[ids[1]]);
      // 新序严格递增
      expect(after[ids[0]]!.compareTo(after[ids[2]]!), lessThan(0));
      expect(after[ids[2]]!.compareTo(after[ids[1]]!), lessThan(0));
      // 只产生一条 sort_key op
      final sortOps = (await sync.takePendingOps())
          .map((e) => e.op)
          .where((o) => o.field == 'sort_key')
          .toList();
      expect(sortOps, hasLength(1));
      expect(sortOps.single.entityId, ids[0]);
    });

    test('整体倒序(多处变动)触发均匀重排', () async {
      final ids = await seedThree();
      await tasks.reorderTasks(ids); // C,B,A → A,B,C
      final keys = {
        for (final t in await tasks.inboxSnapshot()) t.id: t.sortKey,
      };
      expect(keys[ids[0]]!.compareTo(keys[ids[1]]!), lessThan(0));
      expect(keys[ids[1]]!.compareTo(keys[ids[2]]!), lessThan(0));
      expect(keys.values.every((k) => k.length <= maxSortKeyLength), isTrue);
    });

    test('无变化顺序零 op;含已删行时截断重排', () async {
      final ids = await seedThree();
      await tasks.reorderTasks([ids[2], ids[1], ids[0]]); // 与当前一致
      final before = (await sync.takePendingOps())
          .map((e) => e.op)
          .where((o) => o.field == 'sort_key')
          .length;
      expect(before, 0);

      await tasks.setTaskStatus(ids[2], TaskStatus.trashed);
      // 传入了已 trashed 的行:仍按现存两行重排
      await tasks.reorderTasks([ids[2], ids[0], ids[1]]);
      final order = [for (final t in await tasks.inboxSnapshot()) t.id];
      // trashed 不在收件箱,现存 A、B 相对序不变 → 零额外键变更也合法
      expect(order, [ids[0], ids[1]]);
    });

    test('相邻长键触发重排压缩(键长受限)', () async {
      final a = await tasks.addManual('长键A');
      final b = await tasks.addManual('长键B');
      // 直接把两行键改成相邻极限,再插入新项
      await tasks.editTask(a.id, {'sort_key': '0' * 32});
      await tasks.editTask(b.id, {'sort_key': '0' * 31 + '1'});
      // B 移到 A 之后:A(0…0) < newKey < B(0…01) 需 33 位 → 压缩
      await tasks.reorderTasks([a.id, b.id]); // A 在 B 前(与现序一致)→ 无变化
      // 现构造一次真实移动:B、A 互换
      await tasks.reorderTasks([b.id, a.id]);
      final keys = {
        for (final t in await tasks.inboxSnapshot()) t.id: t.sortKey,
      };
      expect(keys[b.id]!.compareTo(keys[a.id]!), lessThan(0));
      expect(
        keys.values.every((k) => k.length <= maxSortKeyLength),
        isTrue,
        reason: '重排压缩后所有键不超过定长上限',
      );
    });
  });
}
