/// PgSyncStore 集成测试：需要本地 Postgres。
///
/// 运行方式（02 文档 §9；R1 起用 tools/wf/test-server-pg.sh 一键跑）：
/// ```sh
/// make up   # docker compose 启动 Postgres
/// DATABASE_URL=postgres://agendum:agendum_dev_only@localhost:5433/agendum_dev flutter test apps/server
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
        uid: 'u-pg',
        deviceId: 'd1',
        ops: [op(5, 'd1', 'title', value: 'v5')],
      ),
    );
    expect(r1.results.single.accepted, isTrue);

    final stale = await store.push(
      PushRequest(
        uid: 'u-pg',
        deviceId: 'd2',
        ops: [op(3, 'd2', 'title', value: '旧值')],
      ),
    );
    expect(stale.results.single.accepted, isFalse, reason: 'lamport 落后被裁决拒绝');

    final r3 = await store.push(
      PushRequest(
        uid: 'u-pg',
        deviceId: 'd2',
        ops: [op(6, 'd2', 'note', value: 'n6')],
      ),
    );
    expect(r3.results.single.accepted, isTrue, reason: '不同字段不受 title 裁决影响');
    expect(r3.serverSeq, greaterThan(r1.serverSeq));

    final pull = await store.pull(since: 0, limit: 100, owner: 'u-pg');
    expect(pull.ops.length, 3);
    expect(pull.ops.map((o) => o.field).toSet(), {'title', 'note'});
    final titleOp = pull.ops.firstWhere((o) => o.field == 'title');
    expect(titleOp.lamport, 5);
    expect(titleOp.value!.value, 'v5');
  });

  test('R1 §5:owner 隔离——跨 uid 的 pull 拿不到对方任何 op', () async {
    await store.push(
      PushRequest(
        uid: 'tenant-A',
        deviceId: 'dA',
        ops: [op(40, 'dA', 'secret_field', value: 'A 的私有数据')],
      ),
    );

    final asB = await store.pull(since: 0, limit: 1000, owner: 'tenant-B');
    expect(asB.ops, isEmpty, reason: 'tenant-B 不得看到 tenant-A 的任何 op');
    expect(asB.hasMore, isFalse);
    expect(asB.cursor, 0);

    final asA = await store.pull(since: 0, limit: 1000, owner: 'tenant-A');
    expect(asA.ops.single.value!.value, 'A 的私有数据');
  });

  test('R1 §5:owner 过滤下的游标推进——别租户的 seq 不产生本租户空页死循环', () async {
    // tenant-A 先写;tenant-B 再写(全局 seq 更大);A 用全量 since=0 拉取,
    // 拿到的 cursor 应落在自己最后一条 op 的 seq 上(跳过 B 的 seq 无妨,
    // since 是全局水位线,pull 按 owner 过滤,不会因此丢自己的 op)。
    final a1 = await store.push(
      PushRequest(
        uid: 'iso-A',
        deviceId: 'dA',
        ops: [op(50, 'dA', 'iso_f1', value: 'a1')],
      ),
    );
    await store.push(
      PushRequest(
        uid: 'iso-B',
        deviceId: 'dB',
        ops: [op(50, 'dB', 'iso_f1', value: 'b1')],
      ),
    );
    final pull = await store.pull(since: 0, limit: 1000, owner: 'iso-A');
    expect(pull.ops.single.value!.value, 'a1');
    expect(pull.cursor, a1.serverSeq, reason: 'cursor = 本租户最后一条的 seq');

    // A 续拉:cursor 之后 B 又写一条,A 拉不到 B,也无 A 自己的新 op。
    await store.push(
      PushRequest(
        uid: 'iso-B',
        deviceId: 'dB',
        ops: [op(51, 'dB', 'iso_f1', value: 'b2')],
      ),
    );
    final pull2 = await store.pull(
      since: pull.cursor,
      limit: 1000,
      owner: 'iso-A',
    );
    expect(pull2.ops, isEmpty);
  });

  test('等时钟 (lamport, origin) 字典序破平；幂等重放 accepted', () async {
    final a = await store.push(
      PushRequest(
        uid: 'u-pg',
        deviceId: 'dA',
        ops: [op(10, 'dA', 'title', value: '来自A')],
      ),
    );
    expect(a.results.single.accepted, isTrue);

    final b = await store.push(
      PushRequest(
        uid: 'u-pg',
        deviceId: 'dB',
        ops: [op(10, 'dB', 'title', value: '来自B')],
      ),
    );
    expect(b.results.single.accepted, isTrue, reason: 'origin dB > dA 胜出');

    // 幂等重放当前胜出的同源 op（equal >= 判定）→ accepted。
    final replay = await store.push(
      PushRequest(
        uid: 'u-pg',
        deviceId: 'dB',
        ops: [op(10, 'dB', 'title', value: '来自B')],
      ),
    );
    expect(replay.results.single.accepted, isTrue);

    // 重放已败的旧写入（equal lamport、origin 更低）→ 拒绝。
    final replayLoser = await store.push(
      PushRequest(
        uid: 'u-pg',
        deviceId: 'dA',
        ops: [op(10, 'dA', 'title', value: '来自A')],
      ),
    );
    expect(replayLoser.results.single.accepted, isFalse);

    // 落后 origin 的等时钟写被拒。
    final below = await store.push(
      PushRequest(
        uid: 'u-pg',
        deviceId: 'dA2',
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
    await store.push(PushRequest(uid: 'u-pg', deviceId: 'pager', ops: ops));

    final collected = <SyncOp>[];
    var cursor = 0;
    var guard = 0;
    while (guard++ < 10) {
      final pr = await store.pull(since: cursor, limit: 2, owner: 'u-pg');
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
    await store.push(
      PushRequest(uid: 'u-pg', deviceId: 'dd', ops: [op(30, 'dd', 'gone')]),
    );
    final pull = await store.pull(since: 0, limit: 1000, owner: 'u-pg');
    final delOp = pull.ops.lastWhere((o) => o.field == 'gone');
    expect(delOp.type, SyncOpType.del);
    expect(delOp.value, isNull);
    expect(jsonEncode(delOp.toJson()), isNotEmpty);
  });

  test('R1 §6:vault_envelopes 真库读写——最新一条、跨 uid 隔离', () async {
    final envelopes = await PgVaultEnvelopeStore.open(dbUrl);
    await envelopes.resetForTest();
    try {
      await envelopes.put(
        VaultEnvelope(
          uid: 'env-u1',
          deviceId: 'd1',
          envelopeB64: base64Encode(utf8.encode('envelope-v1')),
        ),
      );
      await envelopes.put(
        VaultEnvelope(
          uid: 'env-u1',
          deviceId: 'd2',
          envelopeB64: base64Encode(utf8.encode('envelope-v2')),
        ),
      );
      await envelopes.put(
        VaultEnvelope(
          uid: 'env-other',
          deviceId: 'dx',
          envelopeB64: base64Encode(utf8.encode('other-tenant')),
        ),
      );

      final latest = await envelopes.latest('env-u1');
      expect(latest, isNotNull);
      expect(
        utf8.decode(base64Decode(latest!.envelopeB64)),
        'envelope-v2',
        reason: '同 uid 重复上传,取回最新一条',
      );
      expect(latest.deviceId, 'd2');

      // 跨 uid 互不可见（表级 owner 隔离）。
      expect(await envelopes.latest('env-unknown'), isNull);
      final other = await envelopes.latest('env-other');
      expect(utf8.decode(base64Decode(other!.envelopeB64)), 'other-tenant');
    } finally {
      await envelopes.close();
    }
  });

  test('ADR-016 §1:nonce 共享表多实例单次有效——A 实例消费后 B 实例不可重放', () async {
    // 两条独立连接 = 两个服务实例;单次有效必须跨实例成立（红线 2）。
    final a = await PgNonceStore.open(dbUrl);
    final b = await PgNonceStore.open(dbUrl);
    await a.resetForTest();
    try {
      final challenge = await a.issue();
      expect(base64Decode(challenge.nonceB64), hasLength(32));
      final ttlMs =
          challenge.expiresAtMs - DateTime.now().millisecondsSinceEpoch;
      expect(ttlMs, greaterThan(0));
      expect(
        ttlMs,
        lessThanOrEqualTo(const Duration(minutes: 5).inMilliseconds),
        reason: 'TTL ≤5 分钟（R1 §2）',
      );

      expect(await a.consume(challenge.nonceB64), isTrue, reason: '首次消费成功');
      expect(
        await b.consume(challenge.nonceB64),
        isFalse,
        reason: '另一实例重放同一 nonce 必须失败',
      );

      // 方向对称:B 实例签发,A 实例同样只能消费一次。
      final challenge2 = await b.issue();
      expect(await b.consume(challenge2.nonceB64), isTrue);
      expect(await a.consume(challenge2.nonceB64), isFalse);
    } finally {
      await a.close();
      await b.close();
    }
  });

  test('ADR-016 §1:nonce 过 TTL 即不可消费（DB 时钟校验）', () async {
    final store = await PgNonceStore.open(dbUrl);
    try {
      final challenge = await store.issue();
      await store.expireForTest(challenge.nonceB64);
      expect(
        await store.consume(challenge.nonceB64),
        isFalse,
        reason: '过期 nonce 消费失败',
      );
      // 过期行可被签发路径的惰性清扫回收(不阻塞新签发)。
      final next = await store.issue();
      expect(next.nonceB64, isNot(challenge.nonceB64));
    } finally {
      await store.close();
    }
  });
}
