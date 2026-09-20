/// TagRepository(S07):互斥组校验 + task_tag 关联行 oplog。
library;

import 'package:agendum_db/agendum_db.dart';
import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:test/test.dart';

void main() {
  late AgendumDatabase db;
  late DriftLocalSyncStore sync;
  late TaskRepository tasks;
  late TagRepository tags;
  late ProjectRepository projects;

  setUp(() async {
    db = openInMemoryDb();
    sync = await DriftLocalSyncStore.open(db);
    tasks = TaskRepository(db, sync);
    tags = TagRepository(db, sync);
    projects = ProjectRepository(db, sync, tasks);
  });
  tearDown(() async => db.close());

  test('创建互斥组与标签:__row 整行 op + 目录投影', () async {
    final group = await tags.createGroup(name: '场合', exclusive: true);
    final venue = await tags.createTag(name: '现场', groupId: group.id);
    final free = await tags.createTag(name: '快事');

    final descriptors = await tags.tagDescriptorsSnapshot();
    expect(descriptors, hasLength(2));
    final venueD = descriptors.firstWhere((d) => d.id == venue.id);
    expect(venueD.groupExclusive, isTrue);
    expect(venueD.groupName, '场合');
    expect(descriptors.firstWhere((d) => d.id == free.id).groupId, isNull);

    final ops = (await sync.takePendingOps()).map((e) => e.op).toList();
    expect(
      ops.where(
        (o) => o.entity == SyncEntities.tagGroup && o.field == rowCreateField,
      ),
      hasLength(1),
    );
  });

  test('createTag 指向不存在的组抛 ArgumentError', () async {
    await expectLater(
      tags.createTag(name: '孤儿', groupId: 'nope'),
      throwsArgumentError,
    );
  });

  test('互斥组:同组第二个标签拒绝,摘除后可换', () async {
    final group = await tags.createGroup(name: '模式', exclusive: true);
    final deep = await tags.createTag(name: '深度工作', groupId: group.id);
    final light = await tags.createTag(name: '轻杂事', groupId: group.id);
    final free = await tags.createTag(name: '快事');
    final t = await tasks.addManual('写周报');

    await tags.assignTag(t.id, deep.id);
    // 同互斥组冲突(领域红线)
    await expectLater(
      tags.assignTag(t.id, light.id),
      throwsA(isA<ExclusiveTagGroupError>()),
    );
    // 自由标签不受限
    await tags.assignTag(t.id, free.id);
    expect(
      (await tags.tagsOfTaskSnapshot(t.id)).map((d) => d.name),
      unorderedEquals(['深度工作', '快事']),
    );

    // 摘除后可挂同组另一标签
    await tags.unassignTag(t.id, deep.id);
    await tags.assignTag(t.id, light.id);
    expect(
      (await tags.tagsOfTaskSnapshot(t.id)).map((d) => d.name),
      contains('轻杂事'),
    );
  });

  test('重复挂签幂等(不产生新 op)', () async {
    final t = await tasks.addManual('买咖啡豆');
    final tag = await tags.createTag(name: '快事');
    await tags.assignTag(t.id, tag.id);
    final before = (await sync.takePendingOps())
        .where((o) => o.op.entity == SyncEntities.taskTag)
        .length;
    await tags.assignTag(t.id, tag.id);
    final after = (await sync.takePendingOps())
        .where((o) => o.op.entity == SyncEntities.taskTag)
        .length;
    expect(after, before);
  });

  test('摘签幂等;task_tag 走 __row del + 墓碑', () async {
    final t = await tasks.addManual('取快递');
    final tag = await tags.createTag(name: '出门顺手');
    await tags.assignTag(t.id, tag.id);
    await tags.unassignTag(t.id, tag.id);
    await tags.unassignTag(t.id, tag.id); // 幂等
    expect(await tags.tagsOfTaskSnapshot(t.id), isEmpty);

    final dels = (await sync.takePendingOps())
        .map((e) => e.op)
        .where(
          (o) =>
              o.entity == SyncEntities.taskTag &&
              o.type == SyncOpType.del &&
              o.field == rowCreateField,
        )
        .toList();
    expect(dels, hasLength(1));
    expect(dels.single.entityId, '${t.id}:${tag.id}');
  });

  test('allTaskTagsSnapshot:全任务标签映射(含组信息)', () async {
    final g = await tags.createGroup(name: '场合', exclusive: true);
    final venue = await tags.createTag(name: '现场', groupId: g.id);
    final t1 = await tasks.addManual('A');
    final t2 = await tasks.addManual('B');
    await tags.assignTag(t1.id, venue.id);

    final map = await tags.allTaskTagsSnapshot();
    expect(map[t1.id]!.single.id, venue.id);
    expect(map.containsKey(t2.id), isFalse);
  });

  test('删除项目后标签关联保留(标签与项目互不相干)', () async {
    final p = await projects.createProject(name: '搬家');
    final t = await tasks.addManual('联系搬家公司');
    await tasks.setTaskProject(t.id, p.id);
    final tag = await tags.createTag(name: '电话沟通');
    await tags.assignTag(t.id, tag.id);

    await projects.deleteProject(p.id);
    final descriptors = await tags.tagsOfTaskSnapshot(t.id);
    expect(descriptors.single.name, '电话沟通');
  });

  test('标签目录快照:groups/tags 独立查询', () async {
    final g = await tags.createGroup(name: '状态', exclusive: true);
    await tags.createTag(name: '阻塞', groupId: g.id);
    expect((await tags.groupsSnapshot()).single.id, g.id);
    expect(await tags.tagsSnapshot(), hasLength(1));
    // 未挂签任务快照为空但可查询
    await tasks.addManual('孤例');
    final none = await (db.select(
      db.taskTags,
    )..where((tt) => tt.deletedAt.isNull())).get();
    expect(none, isEmpty);
  });
}
