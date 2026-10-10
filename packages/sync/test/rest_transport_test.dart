/// REST 传输:R1 §4/§9 的鉴权头钩子逐请求附加,pull 查询参数带 uid。
library;

import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('push/pull 每请求都调用 authHeaders 钩子并附加其返回头', () async {
    final seenAuth = <String>[]; // 每次请求的 X-Agendum-Auth 值
    var calls = 0;
    final transport = RestSyncTransport(
      base: 'http://stub',
      client: MockClient((req) async {
        seenAuth.add(req.headers['X-Agendum-Auth']!);
        return http.Response(
          jsonEncode(
            req.url.path.endsWith('push')
                ? const PushResponse(serverSeq: 1, results: []).toJson()
                : const PullResponse(
                    cursor: 0,
                    ops: [],
                    hasMore: false,
                  ).toJson(),
          ),
          200,
        );
      }),
      authHeaders: () async {
        calls++;
        return {'X-Agendum-Auth': 'v1 dvc_$calls nonce_$calls sig_$calls'};
      },
    );

    await transport.push(
      PushRequest(uid: 'uid_x', deviceId: 'dvc_a', ops: const []),
    );
    await transport.pull(since: 0, limit: 10, uid: 'uid_x');

    expect(calls, 2, reason: 'nonce 一次性:每个请求单独取挑战签名');
    expect(seenAuth, ['v1 dvc_1 nonce_1 sig_1', 'v1 dvc_2 nonce_2 sig_2']);
  });

  test('pull 查询参数携带 since/limit/uid(R1 §5)', () async {
    Uri? captured;
    final transport = RestSyncTransport(
      base: 'http://stub',
      client: MockClient((req) async {
        captured = req.url;
        return http.Response(
          jsonEncode(
            const PullResponse(cursor: 0, ops: [], hasMore: false).toJson(),
          ),
          200,
        );
      }),
    );

    await transport.pull(since: 42, limit: 7, uid: 'dev-plain');

    expect(captured!.path, '/v1/sync/pull');
    expect(captured!.queryParameters, {
      'since': '42',
      'limit': '7',
      'uid': 'dev-plain',
    });
  });

  test('push 请求体携带 uid(R1 §5)', () async {
    final bodies = <Map<String, Object?>>[];
    final transport = RestSyncTransport(
      base: 'http://stub',
      client: MockClient((req) async {
        bodies.add((jsonDecode(req.body) as Map).cast<String, Object?>());
        return http.Response(
          jsonEncode(const PushResponse(serverSeq: 1, results: []).toJson()),
          200,
        );
      }),
    );

    await transport.push(
      PushRequest(uid: 'uid_x', deviceId: 'dvc_a', ops: const []),
    );

    expect(bodies.single['uid'], 'uid_x');
    expect(bodies.single['device_id'], 'dvc_a');
  });

  test('authHeaders 为 null 时不带鉴权头(旧服务端兼容路径)', () async {
    final headers = <Map<String, String>>[];
    final transport = RestSyncTransport(
      base: 'http://stub',
      client: MockClient((req) async {
        headers.add(req.headers);
        return http.Response(
          jsonEncode(
            const PullResponse(cursor: 0, ops: [], hasMore: false).toJson(),
          ),
          200,
        );
      }),
    );

    await transport.pull(since: 0, limit: 1, uid: 'uid_x');

    expect(headers.single.containsKey('X-Agendum-Auth'), isFalse);
  });

  test('钩子抛出 → 请求失败,错误上抛(由调用方按传输错误重试)', () async {
    final transport = RestSyncTransport(
      base: 'http://stub',
      client: MockClient((req) async => http.Response('{}', 200)),
      authHeaders: () async => throw StateError('挑战获取失败'),
    );

    await expectLater(
      transport.pull(since: 0, limit: 1, uid: 'uid_x'),
      throwsA(isA<StateError>()),
    );
  });
}
