/// 引擎加密闭环（S07）：E2eeOpCodec 挂进 SyncEngine 后，
/// push 出去的 op 是密文、pull 回来的 op 能解密落地。
/// FakeStore/FakeTransport 与 packages/sync 的测试同型（避免依赖反转）。
library;

import 'dart:convert';

import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:test/test.dart';

class FakeStore implements LocalSyncStore {
  @override
  String deviceId = 'dvc_enc';

  @override
  String uid = 'uid_enc';

  final pending = <PendingOp>[];
  final applied = <SyncOp>[];
  int cursor = 0;

  @override
  Future<List<PendingOp>> takePendingOps({int limit = 500}) async =>
      pending.take(limit).toList();

  @override
  Future<void> markPushed(Iterable<int> localSeqs, int serverSeq) async =>
      pending.removeWhere((p) => localSeqs.contains(p.localSeq));

  @override
  Future<int> pullCursor() async => cursor;

  @override
  Future<void> setPullCursor(int seq) async => cursor = seq;

  @override
  Future<bool> applyRemoteOp(SyncOp op) async {
    applied.add(op);
    return true;
  }

  @override
  Future<void> close() async {}

  void enqueue(String id, String title) => pending.add(
    PendingOp(
      localSeq: pending.length + 1,
      op: SyncOp(
        deviceId: deviceId,
        lamport: pending.length + 1,
        entity: 'task',
        entityId: id,
        field: 'title',
        type: SyncOpType.set,
        value: OpValue('str', title),
      ),
    ),
  );
}

/// 模拟服务端:原样存取 op(不解读 value),双端共享一个收件箱。
class RelayTransport implements SyncTransport {
  final inbox = <SyncOp>[];
  var seq = 0;

  @override
  Future<PushResponse> push(PushRequest req) async {
    inbox.addAll(req.ops);
    seq += req.ops.length;
    return PushResponse(
      serverSeq: seq,
      results: [
        for (var i = 0; i < req.ops.length; i++)
          PushOpResult(index: i, accepted: true),
      ],
    );
  }

  @override
  Future<PullResponse> pull({
    required int since,
    required int limit,
    required String uid,
  }) async {
    final ops = inbox.skip(since).take(limit).toList();
    return PullResponse(
      cursor: since + ops.length,
      ops: ops,
      hasMore: since + ops.length < inbox.length,
    );
  }
}

void main() {
  test('push 落到线上的 value 已加密;pull 端解密还原明文', () async {
    final alice = FakeStore();
    final bob = FakeStore()..deviceId = 'dvc_bob';
    final relay = RelayTransport();
    final dk = Uint8ListAid.shared; // 两端共享 DK
    final aliceEngine = SyncEngine(
      store: alice,
      transport: relay,
      codec: E2eeOpCodec(dk),
    );
    final bobEngine = SyncEngine(
      store: bob,
      transport: relay,
      codec: E2eeOpCodec(dk),
    );

    alice.enqueue('tsk_1', '给司机发合同');
    await aliceEngine.syncNow();

    // 服务端收件箱里是密文,看不到明文
    expect(relay.inbox, hasLength(1));
    expect(relay.inbox.single.value!.type, OpValueTypes.enc);
    expect(jsonEncode(relay.inbox.single.toJson()).contains('给司机发合同'), isFalse);

    await bobEngine.syncNow();
    // bob 端解密落地为明文 op
    expect(bob.applied, hasLength(1));
    expect(bob.applied.single.value!.value, '给司机发合同');
    expect(bob.applied.single.field, 'title');
  });

  test('无密钥端拉到密文:解密失败抛 AeadAuthError(同步中断可见)', () async {
    final alice = FakeStore();
    final mallory = FakeStore()..deviceId = 'dvc_evil';
    final relay = RelayTransport();
    final dk = List.filled(32, 42);
    alice.enqueue('tsk_1', '给司机发合同');
    await SyncEngine(
      store: alice,
      transport: relay,
      codec: E2eeOpCodec(dk),
    ).syncNow();

    mallory.enqueue('tsk_9', 'mallory 自己的任务'); // 混入自己的待推
    final engine = SyncEngine(
      store: mallory,
      transport: relay,
      codec: E2eeOpCodec(List.filled(32, 43)), // 错误 DK
    );
    await expectLater(engine.syncNow(), throwsA(isA<AeadAuthError>()));
  });

  test('明文模式:恒等 codec,线上即可读(开发模式回归)', () async {
    final store = FakeStore();
    final relay = RelayTransport();
    await SyncEngine(store: store, transport: relay).syncNow();
    expect(relay.inbox, isEmpty); // 无待推

    store.enqueue('tsk_2', '明文任务');
    await SyncEngine(store: store, transport: relay).syncNow();
    expect(relay.inbox.single.value!.type, 'str');
    expect(relay.inbox.single.value!.value, '明文任务');
  });
}

/// 测试共享 DK 的简单封装(避免测试内重复字面量)。
class Uint8ListAid {
  static List<int> get shared => List.filled(32, 42);
}
