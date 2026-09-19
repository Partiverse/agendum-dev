/// PgSyncStore 集成测试：需要本地 Postgres。
///
/// 运行方式（02 文档 §9）：
/// ```sh
/// make up   # docker compose 启动 Postgres
/// DATABASE_URL=postgres://agendum:agendum_dev_only@localhost:5433/agendum_dev dart test apps/server
/// ```
/// 未设置 DATABASE_URL 时自动跳过（CI 默认跳过）。
library;

import 'dart:convert';
import 'dart:io';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_server/agendum_server.dart';
import 'package:test/test.dart';

SyncOp op(int lamport, String deviceId, String field, {String? value}) =>
    SyncOp(
      deviceId: deviceId,
      lamport: lamport,
      entity: 'task',
      entityId: 'pg-1',
      field: field,
      type: value == null ? SyncOpType.del : SyncOpType.set,
      value: value == null ? null : OpValue(OpValueTypes.str, value),
    );

void main() {
  final dbUrl = Platform.environment['DATABASE_URL'];
  if (dbUrl == null || dbUrl.isEmpty) {
    test('PG 集成测试（跳过：未设置 DATABASE_URL）', () {
      markTestSkipped('未设置 DATABASE_URL；make up 后再跑');
    });
    return;
  }

  late PgSyncStore store;
  setUpAll(() async {
    store = await PgSyncStore.open(dbUrl);
    // 测试用共享开发库：清空 PoC 表保证用例可重复（库本身可丢弃）。
    await store.resetForTest();
  });
  tearDownAll(() async => store.close());

  test('push 分配递增 seq 且裁决 ack 正确；pull 原样取回', () async {
    final r1 = await store.push(
      PushRequest(
        deviceId: 'd1',
        ops: [op(5, 'd1', 'title', value: 'v5')],
      ),
    );
    expect(r1.results.single.accepted, isTrue);

    final stale = await store.push(
      PushRequest(
        deviceId: 'd2',
        ops: [op(3, 'd2', 'title', value: '旧值')],
      ),
    );
    expect(stale.results.single.accepted, isFalse, reason: 'lamport 落后被裁决拒绝');

    final r3 = await store.push(
      PushRequest(
        deviceId: 'd2',
        ops: [op(6, 'd2', 'note', value: 'n6')],
      ),
    );
    expect(r3.results.single.accepted, isTrue, reason: '不同字段不受 title 裁决影响');
    expect(r3.serverSeq, greaterThan(r1.serverSeq));

    final pull = await store.pull(since: 0, limit: 100);
    expect(pull.ops.length, 3);
    expect(pull.ops.map((o) => o.field).toSet(), {'title', 'note'});
    final titleOp = pull.ops.firstWhere((o) => o.field == 'title');
    expect(titleOp.lamport, 5);
    expect(titleOp.value!.value, 'v5');
  });

  test('等时钟 (lamport, origin) 字典序破平；幂等重放 accepted', () async {
    final a = await store.push(
      PushRequest(
        deviceId: 'dA',
        ops: [op(10, 'dA', 'title', value: '来自A')],
      ),
    );
    expect(a.results.single.accepted, isTrue);

    final b = await store.push(
      PushRequest(
        deviceId: 'dB',
        ops: [op(10, 'dB', 'title', value: '来自B')],
      ),
    );
    expect(b.results.single.accepted, isTrue, reason: 'origin dB > dA 胜出');

    // 幂等重放当前胜出的同源 op（equal >= 判定）→ accepted。
    final replay = await store.push(
      PushRequest(
        deviceId: 'dB',
        ops: [op(10, 'dB', 'title', value: '来自B')],
      ),
    );
    expect(replay.results.single.accepted, isTrue);

    // 重放已败的旧写入（equal lamport、origin 更低）→ 拒绝。
    final replayLoser = await store.push(
      PushRequest(
        deviceId: 'dA',
        ops: [op(10, 'dA', 'title', value: '来自A')],
      ),
    );
    expect(replayLoser.results.single.accepted, isFalse);

    // 落后 origin 的等时钟写被拒。
    final below = await store.push(
      PushRequest(
        deviceId: 'dA',
        ops: [op(10, 'dA2', 'title', value: 'x')],
      ),
    );
    expect(below.results.single.accepted, isFalse);
  });

  test('分页 pull：hasMore 与 cursor 续传不丢不重', () async {
    final ops = <SyncOp>[
      for (var i = 1; i <= 5; i++)
        op(20 + i, 'pager', 'page_f$i', value: 'p$i'),
    ];
    await store.push(PushRequest(deviceId: 'pager', ops: ops));

    final collected = <SyncOp>[];
    var cursor = 0;
    var guard = 0;
    while (guard++ < 10) {
      final pr = await store.pull(since: cursor, limit: 2);
      collected.addAll(pr.ops);
      cursor = pr.cursor;
      if (!pr.hasMore) break;
    }
    expect(collected.map((o) => o.field).where((f) => f.startsWith('page_f')), {
      'page_f1',
      'page_f2',
      'page_f3',
      'page_f4',
      'page_f5',
    });
  });

  test('payload JSON 往返保真（含 del 无 value）', () async {
    await store.push(PushRequest(deviceId: 'dd', ops: [op(30, 'dd', 'gone')]));
    final pull = await store.pull(since: 0, limit: 1000);
    final delOp = pull.ops.lastWhere((o) => o.field == 'gone');
    expect(delOp.type, SyncOpType.del);
    expect(delOp.value, isNull);
    expect(jsonEncode(delOp.toJson()), isNotEmpty);
  });
}
