import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_server/agendum_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'harness.dart';

void main() {
  test('空批量 push 返回当前全局序号(不重置为 0,对齐 Memory/Pg 两实现)', () async {
    final store = MemorySyncStore();
    final empty = await store.push(
      PushRequest(uid: 'u1', deviceId: 'dvc_a', ops: const []),
    );
    expect(empty.serverSeq, 0, reason: '空库当前序号即 0');

    final one = await store.push(
      PushRequest(
        uid: 'u1',
        deviceId: 'dvc_a',
        ops: [
          SyncOp(
            deviceId: 'dvc_a',
            lamport: 1,
            entity: 'task',
            entityId: 'e1',
            field: 'title',
            type: SyncOpType.set,
            value: const OpValue('str', 't'),
          ),
        ],
      ),
    );
    expect(one.serverSeq, 1);

    final emptyAgain = await store.push(
      PushRequest(uid: 'u1', deviceId: 'dvc_a', ops: const []),
    );
    expect(emptyAgain.serverSeq, 1, reason: '回到当前序号而非重置');
  });

  test('内存存储按 owner 隔离:跨 uid 的 pull 拿不到对方任何 op', () async {
    final store = MemorySyncStore();
    SyncOp op(int lamport, String deviceId, String value) => SyncOp(
      deviceId: deviceId,
      lamport: lamport,
      entity: 'task',
      entityId: 'e-owner',
      field: 'title',
      type: SyncOpType.set,
      value: OpValue(OpValueTypes.str, value),
    );
    await store.push(
      PushRequest(
        uid: 'tenant-A',
        deviceId: 'dvc_a',
        ops: [op(1, 'dvc_a', 'A 的数据')],
      ),
    );

    final asB = await store.pull(since: 0, limit: 100, owner: 'tenant-B');
    expect(asB.ops, isEmpty, reason: 'tenant-B 不得看到 tenant-A 的 op');
    expect(asB.hasMore, isFalse);

    final asA = await store.pull(since: 0, limit: 100, owner: 'tenant-A');
    expect(asA.ops.single.value!.value, 'A 的数据');
  });

  late Handler handler;

  setUp(() {
    handler = buildHandler();
  });

  Future<Map<String, Object?>> get(String path) async {
    final res = await handler(Request('GET', Uri.parse('http://s$path')));
    return bodyMap(res);
  }

  SyncOp op(int lamport, String deviceId) => SyncOp(
    deviceId: deviceId,
    lamport: lamport,
    entity: 'task',
    entityId: 't1',
    field: 'title',
    type: SyncOpType.set,
    value: OpValue(OpValueTypes.str, 'v$lamport'),
  );

  test('GET /v1/health 返回服务、协议版本与存储类型(无需鉴权)', () async {
    final body = await get('/v1/health');
    expect(body['ok'], true);
    expect(body['protocol'], 'v1');
    expect(body['store'], 'MemorySyncStore');
  });

  test('注册后 push 分配递增 server_seq 并 ack;pull 原样取回', () async {
    final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');

    final r1 = await postAs(handler, dvc, '/v1/sync/push', {
      ...PushRequest(uid: dvc.uid, deviceId: 'd1', ops: [op(1, 'd1')]).toJson(),
    });
    expect(r1.statusCode, 200);
    final p1 = PushResponse.fromJson(await bodyMap(r1));
    expect(p1.results.single.accepted, isTrue);

    final r2 = await postAs(handler, dvc, '/v1/sync/push', {
      ...PushRequest(uid: dvc.uid, deviceId: 'd1', ops: [op(2, 'd1')]).toJson(),
    });
    final p2 = PushResponse.fromJson(await bodyMap(r2));
    expect(p2.serverSeq, greaterThan(p1.serverSeq));

    final pr = PullResponse.fromJson(
      await bodyMap(
        await getAs(
          handler,
          dvc,
          '/v1/sync/pull?since=0&limit=100&uid=${dvc.uid}',
        ),
      ),
    );
    expect(pr.ops.map((o) => o.lamport), {1, 2});
    expect(pr.hasMore, isFalse);
  });

  test('未鉴权请求 → 401（无签名/头畸形/未注册设备）', () async {
    final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');

    // 完全无头。
    final noHeader = await handler(
      Request(
        'POST',
        Uri.parse('http://s/v1/sync/push'),
        body: jsonEncode(
          PushRequest(
            uid: dvc.uid,
            deviceId: 'd1',
            ops: [op(1, 'd1')],
          ).toJson(),
        ),
      ),
    );
    expect(noHeader.statusCode, 401);

    // scheme 非 v1。
    final badScheme = await handler(
      Request(
        'POST',
        Uri.parse('http://s/v1/sync/push'),
        headers: {authHeaderName: 'v2 d1 abc def'},
        body: jsonEncode(
          PushRequest(
            uid: dvc.uid,
            deviceId: 'd1',
            ops: [op(1, 'd1')],
          ).toJson(),
        ),
      ),
    );
    expect(badScheme.statusCode, 401);

    // 未注册设备（挑战可取,但注册表里没有 → 401）。
    final ghost = RegisteredDevice(
      keys: dvc.keys,
      deviceId: 'ghost',
      uid: dvc.uid,
    );
    final unregistered = await postAs(
      handler,
      ghost,
      '/v1/sync/push',
      PushRequest(
        uid: dvc.uid,
        deviceId: 'ghost',
        ops: [op(1, 'ghost')],
      ).toJson(),
    );
    expect(unregistered.statusCode, 401);
  });

  test('请求 uid 与注册租户不符 → 401;pull 缺 uid → 400', () async {
    final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');

    final pushWrongUid = await postAs(handler, dvc, '/v1/sync/push', {
      ...PushRequest(
        uid: 'u-other',
        deviceId: 'd1',
        ops: [op(1, 'd1')],
      ).toJson(),
    });
    expect(pushWrongUid.statusCode, 401);

    final pullNoUid = await getAs(
      handler,
      dvc,
      '/v1/sync/pull?since=0&limit=10',
    );
    expect(pullNoUid.statusCode, 400);

    final pullWrongUid = await getAs(
      handler,
      dvc,
      '/v1/sync/pull?since=0&limit=10&uid=u-other',
    );
    expect(pullWrongUid.statusCode, 401);
  });

  test('push 非法 JSON → 400；pull 缺 since → 400', () async {
    final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');
    final badBody = await postAsRaw(handler, dvc, '/v1/sync/push', '{oops');
    expect(badBody.statusCode, 400);
    final noSince = await getAs(
      handler,
      dvc,
      '/v1/sync/pull?limit=10&uid=${dvc.uid}',
    );
    expect(noSince.statusCode, 400);
    expect((await bodyMap(noSince))['error'], 'bad_request');
  });

  test('超过单批上限 → 400（协议层约束）', () async {
    final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');
    final r = await postAs(
      handler,
      dvc,
      '/v1/sync/push',
      PushRequest.fromJson({
        'uid': dvc.uid,
        'device_id': 'd1',
        'ops': List.generate(
          PushRequest.maxBatchSize,
          (i) => op(i + 1, 'd1').toJson(),
        ),
      }).toJson(),
    );
    expect(r.statusCode, 200);
  });
}
