/// 同步引擎:队列/游标/分页行为(用假传输与假本地库,不含 IO)。
library;

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:test/test.dart';

class FakeStore implements LocalSyncStore {
  @override
  String deviceId = 'dvc_test';

  final pending = <PendingOp>[];
  final applied = <SyncOp>[];
  int? lastPushedSeq;
  int cursor = 0;
  int pushedMarkCalls = 0;

  /// 应用时抛错的毒丸 op(死信隔离行为验证用)。
  Set<SyncOp> poison = const {};

  @override
  Future<List<PendingOp>> takePendingOps({int limit = 500}) async =>
      pending.take(limit).toList();

  @override
  Future<void> markPushed(Iterable<int> localSeqs, int serverSeq) async {
    pushedMarkCalls++;
    lastPushedSeq = serverSeq;
    pending.removeWhere((p) => localSeqs.contains(p.localSeq));
  }

  @override
  Future<int> pullCursor() async => cursor;

  @override
  Future<void> setPullCursor(int seq) async => cursor = seq;

  @override
  Future<bool> applyRemoteOp(SyncOp op) async {
    if (poison.contains(op)) {
      throw StateError('非法字段值:${op.field}');
    }
    applied.add(op);
    return true;
  }

  @override
  Future<void> close() async {}

  void enqueue(String id, int lamport) => pending.add(
    PendingOp(
      localSeq: pending.length + 1,
      op: SyncOp(
        deviceId: deviceId,
        lamport: lamport,
        entity: 'task',
        entityId: id,
        field: 'title',
        type: SyncOpType.set,
        value: const OpValue('str', 't'),
      ),
    ),
  );
}

class FakeTransport implements SyncTransport {
  final pushes = <PushRequest>[];
  final pullSinces = <int>[];
  PushResponse Function(PushRequest req)? onPush;
  PullResponse Function(int since, int limit)? onPull;

  @override
  Future<PushResponse> push(PushRequest req) async {
    pushes.add(req);
    return onPush?.call(req) ??
        PushResponse(
          serverSeq: 1,
          results: [
            for (var i = 0; i < req.ops.length; i++)
              PushOpResult(index: i, accepted: true),
          ],
        );
  }

  @override
  Future<PullResponse> pull({required int since, required int limit}) async {
    pullSinces.add(since);
    return onPull?.call(since, limit) ??
        PullResponse(cursor: since, ops: const [], hasMore: false);
  }
}

SyncOp op(String dev, int lamport, String id) => SyncOp(
  deviceId: dev,
  lamport: lamport,
  entity: 'task',
  entityId: id,
  field: 'title',
  type: SyncOpType.set,
  value: const OpValue('str', 't'),
);

void main() {
  test('pushPending:一次推完未确认 ops 并回填 server_seq', () async {
    final store = FakeStore()
      ..enqueue('e1', 1)
      ..enqueue('e2', 2);
    final transport = FakeTransport();
    final engine = SyncEngine(store: store, transport: transport);

    await engine.pushPending();

    expect(transport.pushes, hasLength(1));
    expect(transport.pushes.single.deviceId, 'dvc_test');
    expect(transport.pushes.single.ops.map((o) => o.entityId), ['e1', 'e2']);
    expect(store.lastPushedSeq, 1);
    expect(store.pending, isEmpty);
  });

  test('pushPending:超过单批上限自动分批(≤500/批)', () async {
    final store = FakeStore();
    for (var i = 0; i < 1201; i++) {
      store.enqueue('e$i', i);
    }
    final transport = FakeTransport();
    final engine = SyncEngine(store: store, transport: transport);

    await engine.pushPending();

    expect(transport.pushes.map((r) => r.ops.length), [500, 500, 201]);
    expect(store.pending, isEmpty);
  });

  test('pull:has_more 分页续传,逐条应用,游标推进到最后一条', () async {
    final store = FakeStore();
    final transport = FakeTransport();
    var page = 0;
    transport.onPull = (since, limit) {
      if (page++ == 0) {
        return PullResponse(
          cursor: 100,
          ops: [op('dvc_a', 1, 'e1')],
          hasMore: true,
        );
      }
      return PullResponse(
        cursor: 200,
        ops: [op('dvc_a', 2, 'e2'), op('dvc_a', 3, 'e3')],
        hasMore: false,
      );
    };
    final engine = SyncEngine(store: store, transport: transport);

    await engine.pull();

    expect(transport.pullSinces, [0, 100], reason: '按 cursor 增量续传');
    expect(store.applied.map((o) => o.entityId), ['e1', 'e2', 'e3']);
    expect(store.cursor, 200);
  });

  test('pull:毒丸 op 死信隔离,游标照推,后续 op 不被阻塞', () async {
    final store = FakeStore();
    final transport = FakeTransport();
    final poison = op('dvc_a', 1, 'e1');
    final good = op('dvc_a', 2, 'e2');
    store.poison = {poison};
    transport.onPull = (since, limit) =>
        PullResponse(cursor: 100, ops: [poison, good], hasMore: false);
    final quarantined = <SyncOp>[];
    final engine = SyncEngine(
      store: store,
      transport: transport,
      onQuarantined: (op, error) => quarantined.add(op),
    );

    await engine.pull();

    expect(quarantined.map((o) => o.entityId), ['e1']);
    expect(store.applied.map((o) => o.entityId), [
      'e2',
    ], reason: '毒丸之后的好 op 照常应用');
    expect(store.cursor, 100, reason: '游标越过毒丸,下一轮不重拉');
  });

  test('syncNow:先推后拉(传输事件顺序)', () async {
    final store = FakeStore()..enqueue('e1', 1);
    final transport = FakeTransport();
    final events = <String>[];
    transport.onPush = (req) {
      events.add('push');
      return PushResponse(
        serverSeq: 9,
        results: [
          for (var i = 0; i < req.ops.length; i++)
            PushOpResult(index: i, accepted: true),
        ],
      );
    };
    transport.onPull = (since, limit) {
      events.add('pull');
      return PullResponse(cursor: since, ops: const [], hasMore: false);
    };
    final engine = SyncEngine(store: store, transport: transport);

    await engine.syncNow();

    expect(events, ['push', 'pull']);
    expect(store.lastPushedSeq, 9);
  });

  test('传输失败抛出,由调用方/轮询决定重试(状态不变)', () async {
    final store = FakeStore()..enqueue('e1', 1);
    final transport = FakeTransport();
    transport.onPush = (req) => throw SyncTransportException('网络断开');
    final engine = SyncEngine(store: store, transport: transport);

    await expectLater(
      engine.pushPending(),
      throwsA(isA<SyncTransportException>()),
    );
    expect(store.pending, hasLength(1), reason: '未确认的 op 仍在队列');
    expect(store.lastPushedSeq, isNull);
  });
}
