/// S05 同步闭环集成测试:两个客户端实例(独立 Drift 内存库 = 两台设备)
/// 经真实服务端(shelf in-process,内存同步存储)push/pull,
/// 验证 03 文档 §4.3 的字段级同步收敛。
///
/// R1 起:客户端默认 E2EE + 设备鉴权。两台设备共享同一条恢复短语 →
/// 同一 MK/DK/uid;各自注册 Ed25519 设备密钥,push/pull 带
/// X-Agendum-Auth 签名头 —— 服务端只见密文与鉴权元数据,两端照常收敛。
/// (服务端为 R1 版内存实现:challenge/注册验签/owner=uid 隔离。)
library;

import 'dart:convert';
import 'dart:io';

import 'package:agendum_client/device_auth.dart';
import 'package:agendum_client/views/store.dart';
import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:agendum_server/agendum_server.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as io;

void main() {
  late HttpServer server;
  late String base;

  setUp(() async {
    server = await io.serve(buildHandler(), 'localhost', 0);
    base = 'http://localhost:${server.port}';
  });
  tearDown(() => server.close(force: true));

  Future<TaskStore> newDevice(String phrase) => TaskStore.open(
    executor: NativeDatabase.memory(),
    keyStore: InMemoryKeyStore(), // 测试走内存 KeyStore(R1 §7)
    recoveryPhrase: phrase, // 同种子 → 同 MK/uid/DK,密文互通
    serverBase: base,
    autoSync: false, // 手动 syncNow,测试确定性
  );

  test('两设备经真实服务端收敛:创建→完成→并发各自新建(全程密文)', () async {
    final phrase = Bip39.generate();
    final a = await newDevice(phrase);
    final b = await newDevice(phrase);
    addTearDown(a.close);
    addTearDown(b.close);
    expect(a.uid, b.uid, reason: '同一种子多端必得同一 uid(R1 §1)');
    expect(a.recoveryPhrase, isNotNull, reason: '恢复短语只读可取(onboarding UI 用)');

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
    final phrase = Bip39.generate();
    final a = await newDevice(phrase);
    final b = await newDevice(phrase);
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

  test('租户隔离:不同种子的设备(uid 不同)拉不到 A 的 op,线上全程密文', () async {
    final a = await newDevice(Bip39.generate());
    final other = await newDevice(Bip39.generate()); // 另一用户(不同种子)
    addTearDown(a.close);
    addTearDown(other.close);
    expect(other.uid, isNot(a.uid), reason: '不同种子必得不同 uid(R1 §1)');

    // A 捕获任务并推送;oplog 归 owner=A.uid。
    await a.addFromCapture(
      const ParsedCapture(
        title: '买牛奶',
        dueDay: 20650,
        estimateMinutes: 15,
        confidence: 1,
      ),
    );
    await a.syncNow();

    // 另一租户经同一服务端同步:各视图全空 —— 跨 uid 拿不到对方任何 op。
    await other.syncNow();
    expect(other.inboxTasks, isEmpty, reason: 'R1 §5:跨 uid 的 pull 零泄漏');
    expect(other.todayTasks, isEmpty);
    expect(other.planTasks, isEmpty);
    expect(other.anytimeTasks, isEmpty);
    expect(other.logTasks, isEmpty);
    expect(other.projectList, isEmpty);

    // 原始 HTTP 交叉验证(真实客户端签名路径 + 真实服务端):
    // probe 设备(注册为 A 的 uid)拉 owner=A.uid 的原始 op ——
    // 线上 value 必须全是 enc 密文,响应体不含明文标题。
    final probe = DeviceAuthService(
      base: base,
      deviceId: 'dvc_probe_a',
      keys: await DeviceKeys.generate(),
      uid: a.uid,
      uidProofB64: a.uidProofB64, // 注册准入:uid 归属证明(ADR-016 §6)
    );
    Uri pullUri(String uid) => Uri.parse(
      '$base/v1/sync/pull',
    ).replace(queryParameters: {'since': '0', 'limit': '2000', 'uid': uid});
    final raw = await http.get(
      pullUri(a.uid),
      headers: await probe.authHeaders(),
    );
    expect(raw.statusCode, 200);
    expect(raw.body, isNot(contains('买牛奶')), reason: '服务端只见密文(E2EE)');
    final body = jsonDecode(raw.body) as Map<String, Object?>;
    final ops = (body['ops'] as List).cast<Map<String, Object?>>();
    expect(ops, isNotEmpty, reason: 'A 的 op 在服务端 oplog 中(owner=A.uid)');
    final values = [
      for (final op in ops)
        if (op['value'] != null) op['value']! as Map<String, Object?>,
    ];
    expect(values, isNotEmpty);
    expect(
      values.every((v) => v['t'] == 'enc'),
      isTrue,
      reason: '所有 value 均为 enc 密文负载(R1 §7)',
    );

    // other 租户的设备冒用 A 的 uid 发 pull → 401(请求 uid 与注册租户不符)。
    final rogue = DeviceAuthService(
      base: base,
      deviceId: 'dvc_rogue',
      keys: await DeviceKeys.generate(),
      uid: other.uid,
      uidProofB64: other.uidProofB64,
    );
    final cross = await http.get(
      pullUri(a.uid),
      headers: await rogue.authHeaders(),
    );
    expect(cross.statusCode, 401, reason: 'R1 §4:请求 uid 与注册 uid 不符一律 401');
  });
}
