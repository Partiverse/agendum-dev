/// TaskRepository 写路径:领域状态机 + 同事务字段级 oplog(03 文档 §4.3)。
library;

import 'package:agendum_db/agendum_db.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:test/test.dart';

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

  test('捕获入库:行落地 + __row 整行 op(lamport 1)', () async {
    final t = await repo.addFromCapture(
      ParsedCapture(
        title: '买牛奶',
        dueDay: 20650,
        estimateMinutes: 15,
        energy: 'low',
        confidence: 1,
      ),
    );
    expect(t.title, '买牛奶');
    expect(t.dueDate, 20650);
    expect(t.status, 'inbox');
    expect(t.lamport, 1);
    expect(t.origin, sync.deviceId);

    final ops = await sync.takePendingOps();
    expect(ops, hasLength(1));
    final op = ops.single.op;
    expect(op.field, rowCreateField);
    expect(op.type, SyncOpType.set);
    expect(op.lamport, 1);
    expect(op.value!.type, OpValueTypes.json);
    final rowJson = op.value!.value as Map;
    expect(rowJson['title'], '买牛奶');
    expect(rowJson['due_date'], 20650);
    expect(rowJson['estimate_minutes'], 15);
  });

  test('toggleDone:走状态机,status+completed_at 两个 op 共享一个 lamport', () async {
    final t = await repo.addManual('发邮件');
    await repo.toggleDone(t.id);
    final row = await repo.byId(t.id);
    expect(row.status, 'done');
    expect(row.completedAt, isNotNull);

    final ops = await sync.takePendingOps();
    final fieldOps = ops.skip(1).toList(); // 去掉 __row
    expect(fieldOps.map((p) => p.op.field).toSet(), {'status', 'completed_at'});
    expect(fieldOps.every((p) => p.op.lamport == 2), isTrue);
    expect(
      fieldOps.firstWhere((p) => p.op.field == 'status').op.value!.value,
      'done',
    );

    // 回退:done → next(领域允许),completed_at 转 del 墓碑。
    await repo.toggleDone(t.id);
    final ops2 = (await sync.takePendingOps())
        .skip(1)
        .where((p) => p.op.lamport > 2)
        .toList();
    expect(
      ops2.firstWhere((p) => p.op.field == 'status').op.value!.value,
      'next',
    );
    expect(
      ops2.firstWhere((p) => p.op.field == 'completed_at').op.type,
      SyncOpType.del,
    );
  });

  test('幂等写不产生 op(值未变化)', () async {
    final t = await repo.addManual('发邮件');
    await repo.promoteToNext(t.id);
    final n1 = (await sync.takePendingOps()).length;
    expect(n1, greaterThan(0));
    await repo.promoteToNext(t.id); // 已是 next
    expect((await sync.takePendingOps()).length, n1);
  });

  test('推送队列:markPushed 回填 server_seq 后清空待推', () async {
    await repo.addManual('a');
    await repo.addManual('b');
    final batch = await sync.takePendingOps();
    expect(batch.length, greaterThanOrEqualTo(2));
    expect(batch.map((p) => p.op.deviceId), everyElement(sync.deviceId));

    await sync.markPushed(batch.map((p) => p.localSeq), 10440);
    expect(await sync.takePendingOps(), isEmpty);
    expect(await sync.pullCursor(), 0, reason: '推送不影响拉取游标');
  });

  test('设备 ID 持久化:重开库后同一设备与时钟', () async {
    await repo.addManual('a');
    final lamport = sync.lamport;
    final reopened = await DriftLocalSyncStore.open(db);
    expect(reopened.deviceId, sync.deviceId);
    expect(reopened.lamport, lamport);
  });
}
