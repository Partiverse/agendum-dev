/// R1 部署验收(环境门控,常规 CI/本地不跑):
/// - 前置:两个独立服务端进程共享 Postgres(多实例部署形态),
///   `AGENDUM_ACCEPTANCE_BASES="http://localhost:8091,http://localhost:8092"`。
/// - 阶段一(默认):设备 A 经实例①、设备 B(同恢复短语)经实例②,
///   真实 TCP + PG 持久层下密文收敛;异种子设备(不同 uid)对 A 不可见。
/// - 阶段二(`AGENDUM_ACCEPTANCE_PHASE=2`,先手动重启实例②):
///   全新设备(同短语)经重启后的实例②仍能拉到阶段一的数据 ——
///   oplog/注册表/信封在 PG 真实持久,非进程内存。
/// 未提供环境变量时整体 skip(与 pg_store_test 的 DATABASE_URL 门控同风格)。
library;

import 'dart:io';

import 'package:agendum_client/views/store.dart';
import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  final basesEnv = Platform.environment['AGENDUM_ACCEPTANCE_BASES'];
  final hasBases = basesEnv != null && basesEnv.split(',').length >= 2;
  final bases = hasBases ? basesEnv.split(',') : <String>[];
  final phase = Platform.environment['AGENDUM_ACCEPTANCE_PHASE'] ?? '1';
  final phraseEnv = Platform.environment['AGENDUM_ACCEPTANCE_PHRASE'];

  Future<void> expectHealthy(String base) async {
    final res = await http.get(Uri.parse('$base/v1/health'));
    expect(res.statusCode, 200, reason: '$base 应就绪');
    expect(
      res.body.toLowerCase(),
      contains('pgsyncstore'),
      reason: '$base 应为 PG 存储形态',
    );
  }

  Future<TaskStore> deviceAt(String base, String phrase) => TaskStore.open(
    executor: NativeDatabase.memory(),
    keyStore: InMemoryKeyStore(),
    recoveryPhrase: phrase,
    serverBase: base,
    autoSync: false,
  );

  test('部署验收阶段一:双设备跨实例密文收敛 + 异租户隔离 + 双实例 PG 形态', () async {
    if (!hasBases) {
      markTestSkipped('未提供 AGENDUM_ACCEPTANCE_BASES(双实例基址),跳过部署验收');
      return;
    }
    await expectHealthy(bases[0]);
    await expectHealthy(bases[1]);

    final phrase = phraseEnv ?? Bip39.generate();
    // ignore: avoid_print
    print('ACCEPTANCE_PHRASE=$phrase');

    final a = await deviceAt(bases[0], phrase);
    addTearDown(a.close);
    await a.addFromCapture(
      const ParsedCapture(title: '部署验收任务甲', confidence: 1),
    );
    await a.syncNow();

    final b = await deviceAt(bases[1], phrase);
    addTearDown(b.close);
    expect(b.uid, a.uid, reason: '同种子跨实例必同 uid');
    await b.syncNow();
    expect(
      b.inboxTasks.map((t) => t.title),
      contains('部署验收任务甲'),
      reason: '设备 B 经实例②拉到实例①上的密文 op 并解密收敛',
    );

    // 异种子设备(不同 uid)经任一实例都看不到 A 的数据。
    final c = await deviceAt(bases[1], Bip39.generate());
    addTearDown(c.close);
    await c.syncNow();
    expect(c.inboxTasks, isEmpty, reason: '跨租户在双实例 + PG 形态下隔离');
  });

  test('部署验收阶段二:实例重启后数据仍可恢复(PG 持久)', () async {
    if (!hasBases) {
      markTestSkipped('未提供 AGENDUM_ACCEPTANCE_BASES(双实例基址),跳过部署验收');
      return;
    }
    if (phase != '2') {
      markTestSkipped('非阶段二(PHASE=2 才执行);重启实例②后复跑本文件');
      return;
    }
    final phrase = phraseEnv;
    if (phrase == null || phrase.isEmpty) {
      fail('阶段二需要 AGENDUM_ACCEPTANCE_PHRASE(阶段一打印的恢复短语)');
    }
    await expectHealthy(bases[1]);
    final d = await deviceAt(bases[1], phrase);
    addTearDown(d.close);
    await d.syncNow();
    expect(
      d.inboxTasks.map((t) => t.title),
      contains('部署验收任务甲'),
      reason: '服务端重启后,oplog/设备注册仍来自 PG,新设备照常恢复',
    );
  });
}
