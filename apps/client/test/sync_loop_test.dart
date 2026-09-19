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
}
