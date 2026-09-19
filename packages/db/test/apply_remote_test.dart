/// 远端 op 应用:字段级 LWW 裁决在持久层的行为(03 文档 §4.3、§5)。
library;

import 'package:agendum_db/agendum_db.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:test/test.dart';

SyncOp setOp(
  String dev,
  int lamport,
  String entityId,
  String field,
  Object? value,
) => SyncOp(
  deviceId: dev,
  lamport: lamport,
  entity: 'task',
  entityId: entityId,
  field: field,
  type: SyncOpType.set,
  value: OpValue(
    const {'title': 'str', 'note': 'str', 'due_date': 'date'}[field]!,
    value,
  ),
);

void main() {
  late AgendumDatabase db;
  late DriftLocalSyncStore sync;
  late TaskRepository repo;

  setUp(() async {
    db = openInMemoryDb();
    sync = await DriftLocalSyncStore.open(db);
    repo = TaskRepository(db, sync);
  });
  tearDown(() async => db.close());

  test('远端整行创建 → 落地;重放幂等;stale 忽略;更高 lamport 胜出', () async {
    final create = SyncOp(
      deviceId: 'dvc_a',
      lamport: 5,
      entity: 'task',
      entityId: 'e1',
      field: rowCreateField,
      type: SyncOpType.set,
      value: OpValue(OpValueTypes.json, {
        'title': '远端任务',
        'due_date': 20650,
        'status': 'inbox',
      }),
    );
    expect(await sync.applyRemoteOp(create), isTrue);
    final row = await repo.byId('e1');
    expect(row.title, '远端任务');
    expect(row.dueDate, 20650);
    expect(row.lamport, 5);
    expect(row.origin, 'dvc_a');

    expect(await sync.applyRemoteOp(create), isFalse, reason: '同一条写重放');

    final stale = setOp('dvc_b', 3, 'e1', 'title', '旧标题');
    expect(await sync.applyRemoteOp(stale), isFalse);
    expect((await repo.byId('e1')).title, '远端任务');

    expect(
      await sync.applyRemoteOp(setOp('dvc_b', 6, 'e1', 'title', '新标题')),
      isTrue,
    );
    expect((await repo.byId('e1')).title, '新标题');
  });

  test('真并发平局:origin 字典序大者胜,且与应用顺序无关(交换律)', () async {
    final opA = setOp('dvc_a', 7, 'e2', 'title', 'A 版');
    final opZ = setOp('dvc_z', 7, 'e2', 'title', 'Z 版');

    // 顺序一:A 先,Z 后 → Z 胜。
    await sync.applyRemoteOp(opA);
    await sync.applyRemoteOp(opZ);
    expect((await repo.byId('e2')).title, 'Z 版');
  });

  test('真并发平局(反向顺序):结果一致', () async {
    final opA = setOp('dvc_a', 7, 'e3', 'title', 'A 版');
    final opZ = setOp('dvc_z', 7, 'e3', 'title', 'Z 版');

    final db2 = openInMemoryDb();
    final sync2 = await DriftLocalSyncStore.open(db2);
    final repo2 = TaskRepository(db2, sync2);
    addTearDown(db2.close);

    await sync2.applyRemoteOp(opZ);
    await sync2.applyRemoteOp(opA);
    expect((await repo2.byId('e3')).title, 'Z 版');
  });

  test('del 落 NULL;非空列 del 跳过但仍推进行级同步列', () async {
    final t = await repo.addManual('本地任务');
    // 远端删除 note(lamport 更高)→ note 为 NULL。
    final delNote = SyncOp(
      deviceId: 'dvc_b',
      lamport: 99,
      entity: 'task',
      entityId: t.id,
      field: 'note',
      type: SyncOpType.del,
    );
    expect(await sync.applyRemoteOp(delNote), isTrue);
    expect((await repo.byId(t.id)).note, isNull);

    // 远端 del title(非空列)→ 值保持,行级 lamport/origin 推进。
    final delTitle = SyncOp(
      deviceId: 'dvc_b',
      lamport: 100,
      entity: 'task',
      entityId: t.id,
      field: 'title',
      type: SyncOpType.del,
    );
    expect(await sync.applyRemoteOp(delTitle), isTrue);
    final row = await repo.byId(t.id);
    expect(row.title, '本地任务');
    expect(row.lamport, 100);
    expect(row.origin, 'dvc_b');
  });

  test('未知字段与未知实体前向兼容地跳过', () async {
    expect(
      await sync.applyRemoteOp(
        SyncOp(
          deviceId: 'dvc_a',
          lamport: 9,
          entity: 'task',
          entityId: 'e9',
          field: '未来字段',
          type: SyncOpType.set,
          value: const OpValue('str', 'x'),
        ),
      ),
      isFalse,
    );
    expect(
      await sync.applyRemoteOp(
        SyncOp(
          deviceId: 'dvc_a',
          lamport: 9,
          entity: 'project',
          entityId: 'p1',
          field: rowCreateField,
          type: SyncOpType.set,
          value: OpValue(OpValueTypes.json, {'name': '项目'}),
        ),
      ),
      isFalse,
      reason: 'PoC 只同步 task 实体',
    );
  });

  test('拉取观察推进本机 lamport:max(local, remote) + 1', () async {
    await sync.applyRemoteOp(setOp('dvc_a', 100, 'e10', 'title', 'x'));
    expect(sync.lamport, greaterThanOrEqualTo(101));
    final l1 = sync.lamport;
    await sync.applyRemoteOp(setOp('dvc_a', 50, 'e10', 'note', 'y'));
    expect(sync.lamport, l1 + 1, reason: '远端更低也 +1(观察即推进)');
  });
}
