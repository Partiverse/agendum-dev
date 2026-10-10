/// S05 同步闭环集成测试:两个客户端实例(独立 Drift 内存库 = 两台设备)
/// 经真实服务端(shelf in-process,内存同步存储)push/pull,
/// 验证 03 文档 §4.3 的字段级同步收敛。
library;

import 'dart:io';

import 'package:agendum_client/views/store.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:agendum_server/agendum_server.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf_io.dart' as io;

void main() {
  late HttpServer server;
  late String base;

  setUp(() async {
    server = await io.serve(buildHandler(), 'localhost', 0);
    base = 'http://localhost:${server.port}';
  });
  tearDown(() => server.close(force: true));

  Future<TaskStore> newDevice() => TaskStore.open(
    executor: NativeDatabase.memory(),
    serverBase: base,
    autoSync: false, // 手动 syncNow,测试确定性
  );

  test('两设备经真实服务端收敛:创建→完成→并发各自新建', () async {
    final a = await newDevice();
    final b = await newDevice();
    addTearDown(a.close);
    addTearDown(b.close);

    // A 捕获入库 → 推送;B 首次拉取即见(字段级 ops 经 __row 重放)。
    await a.addFromCapture(
      const ParsedCapture(
        title: '买牛奶',
        dueDay: 20650,
        estimateMinutes: 15,
        confidence: 1,
      ),
    );
    await a.syncNow();

    await b.syncNow();
    expect(b.inboxTasks.single.title, '买牛奶');
    expect(b.inboxTasks.single.dueDay, 20650);
    expect(b.inboxTasks.single.estimateMinutes, 15);
    final taskId = b.inboxTasks.single.id;
    expect(taskId, a.inboxTasks.single.id, reason: '实体 ID 跨设备一致');

    // B 完成(状态机)→ 同步后 A 看到同一终态。
    await b.toggleDone(taskId);
    await b.syncNow();
    await a.syncNow();
    expect(a.byId(taskId).isDone, isTrue);
    expect(b.byId(taskId).isDone, isTrue);

    // 并发:双端离线各建一条,互通后两端视图集合一致(收敛)。
    await a.addFromCapture(const ParsedCapture(title: 'A 本地捕获', confidence: 1));
    await b.addFromCapture(const ParsedCapture(title: 'B 本地捕获', confidence: 1));
    await a.syncNow();
    await b.syncNow();
    await a.syncNow(); // 收 B 的新任务
    final aTitles = a.inboxTasks.map((t) => t.title).toSet();
    final bTitles = b.inboxTasks.map((t) => t.title).toSet();
    expect(aTitles, {'买牛奶', 'A 本地捕获', 'B 本地捕获'});
    expect(bTitles, aTitles);
  });

  test('两设备收敛:远端删项目 → 对端任务回收进收件箱(S07 关系完整性)', () async {
    final a = await newDevice();
    final b = await newDevice();
    addTearDown(a.close);
    addTearDown(b.close);

    // A 建项目 + 挂任务并推进到 next,推送;B 拉到项目与任务。
    await a.addProject('装修');
    final pid = a.projectList.single.id;
    await a.addManual('选瓷砖');
    final taskId = a.inboxTasks.single.id;
    await a.setTaskProject(taskId, pid);
    await a.promoteToNext(taskId);
    await a.syncNow();

    await b.syncNow();
    expect((await b.tasksInProject(pid)).single.id, taskId);

    // A 删项目(本地任务回收)→ 同步后 B 收敛:项目消失、任务回收进收件箱。
    await a.deleteProject(pid);
    await a.syncNow();
    await b.syncNow();
    await a.syncNow(); // 收 B 的回收 op,两端终态一致

    expect(a.projectList.where((p) => p.id == pid), isEmpty);
    expect(b.projectList.where((p) => p.id == pid), isEmpty, reason: '墓碑传播到 B');
    expect((await b.tasksInProject(pid)), isEmpty);
    expect(
      b.inboxTasks.map((t) => t.id),
      contains(taskId),
      reason: 'B 的任务回收进收件箱',
    );
    expect(
      a.inboxTasks.map((t) => t.id),
      contains(taskId),
      reason: 'A 的任务回收进收件箱',
    );
  });
}
