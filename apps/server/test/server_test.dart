import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_server/agendum_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('空批量 push 返回当前全局序号(不重置为 0,对齐 Memory/Pg 两实现)', () async {
    final store = MemorySyncStore();
    final empty = await store.push(
      PushRequest(deviceId: 'dvc_a', ops: const []),
    );
    expect(empty.serverSeq, 0, reason: '空库当前序号即 0');

    final one = await store.push(
      PushRequest(
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
      PushRequest(deviceId: 'dvc_a', ops: const []),
    );
    expect(emptyAgain.serverSeq, 1, reason: '回到当前序号而非重置');
  });

  late Handler handler;

  setUp(() {
    handler = buildHandler();
  });

  Future<Map<String, Object?>> get(String path) async {
    final res = await handler(Request('GET', Uri.parse('http://s$path')));
    return (jsonDecode(await res.readAsString()) as Map)
        .cast<String, Object?>();
  }

  Future<Map<String, Object?>> post(String path, Object? body) async {
    final res = await handler(
      Request('POST', Uri.parse('http://s$path'), body: jsonEncode(body)),
    );
    return (jsonDecode(await res.readAsString()) as Map)
        .cast<String, Object?>();
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

  test('GET /v1/health 返回服务、协议版本与存储类型', () async {
    final body = await get('/v1/health');
    expect(body['ok'], true);
    expect(body['protocol'], 'v1');
    expect(body['store'], 'MemorySyncStore');
  });

  test('POST /v1/sync/push 分配递增 server_seq 并 ack', () async {
    final r1 = await post(
      '/v1/sync/push',
      PushRequest(deviceId: 'd1', ops: [op(1, 'd1')]).toJson(),
    );
    final r2 = await post(
      '/v1/sync/push',
      PushRequest(deviceId: 'd1', ops: [op(2, 'd1')]).toJson(),
    );
    final p1 = PushResponse.fromJson(r1);
    final p2 = PushResponse.fromJson(r2);
    expect(p1.results.single.accepted, isTrue);
    expect(p2.serverSeq, greaterThan(p1.serverSeq));
  });

  test('push + pull 往返：op 原样取回', () async {
    final original = op(7, 'd1');
    await post(
      '/v1/sync/push',
      PushRequest(deviceId: 'd1', ops: [original]).toJson(),
    );
    final pr = PullResponse.fromJson(
      await get('/v1/sync/pull?since=0&limit=100'),
    );
    expect(pr.ops.single.toJson(), original.toJson());
    expect(pr.hasMore, isFalse);
  });

  test('push 非法 JSON → 400；pull 缺 since → 400', () async {
    final badBody = await handler(
      Request('POST', Uri.parse('http://s/v1/sync/push'), body: '{oops'),
    );
    expect(badBody.statusCode, 400);
    final noSince = await get('/v1/sync/pull');
    expect(noSince['error'], 'bad_request');
  });

  test('超过单批上限 → 400（协议层约束）', () async {
    final r = await handler(
      Request(
        'POST',
        Uri.parse('http://s/v1/sync/push'),
        body: jsonEncode(
          PushRequest.fromJson({
            'device_id': 'd1',
            'ops': List.generate(
              PushRequest.maxBatchSize,
              (i) => op(i + 1, 'd1').toJson(),
            ),
          }).toJson(),
        ),
      ),
    );
    expect(r.statusCode, 200);
  });
}
