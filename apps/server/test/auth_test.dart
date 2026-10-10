/// 设备鉴权端到端行为（R1 §2/§4）：挑战、401 语义、单次 nonce、uid 一致性。
///
/// 全部断言真实安全行为——不放宽任何校验来迁就实现。
library;

import 'dart:convert';

import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_server/agendum_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'harness.dart';

void main() {
  late Handler handler;

  setUp(() {
    handler = buildHandler();
  });

  SyncOp op(int lamport, String deviceId) => SyncOp(
    deviceId: deviceId,
    lamport: lamport,
    entity: 'task',
    entityId: 't-auth',
    field: 'title',
    type: SyncOpType.set,
    value: OpValue(OpValueTypes.str, 'v$lamport'),
  );

  Map<String, Object?> pushBody(String uid, String deviceId) => PushRequest(
    uid: uid,
    deviceId: deviceId,
    ops: [op(1, deviceId)],
  ).toJson();

  group('R1 §2 挑战端点', () {
    test('返回 32 字节 base64 nonce 与 ≤5 分钟的过期时间', () async {
      final res = await handler(
        Request(
          'GET',
          Uri(
            scheme: 'http',
            host: 's',
            path: '/v1/auth/challenge',
            queryParameters: {'device_id': 'd1'},
          ),
        ),
      );
      expect(res.statusCode, 200);
      final challenge = AuthChallenge.fromJson(await bodyMap(res));
      final nonceBytes = base64Decode(challenge.nonceB64);
      expect(nonceBytes.length, 32, reason: 'R1 §2:nonce 32 字节');
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(challenge.expiresAtMs, greaterThan(now));
      expect(
        challenge.expiresAtMs,
        lessThanOrEqualTo(now + const Duration(minutes: 5).inMilliseconds),
        reason: 'TTL ≤5 分钟（ADR-016）',
      );
    });

    test('连续两次挑战给出不同 nonce（不可预测）', () async {
      Future<AuthChallenge> fetch() async {
        final res = await handler(
          Request(
            'GET',
            Uri(
              scheme: 'http',
              host: 's',
              path: '/v1/auth/challenge',
              queryParameters: {'device_id': 'd1'},
            ),
          ),
        );
        return AuthChallenge.fromJson(await bodyMap(res));
      }

      final a = await fetch();
      final b = await fetch();
      expect(a.nonceB64, isNot(b.nonceB64));
    });

    test('缺 device_id → 400', () async {
      final res = await handler(
        Request('GET', Uri.parse('http://s/v1/auth/challenge')),
      );
      expect(res.statusCode, 400);
    });
  });

  group('R1 §4 鉴权中间件（push/pull 一律要求）', () {
    test('无鉴权头 → 401', () async {
      final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');
      final res = await handler(
        Request(
          'POST',
          Uri.parse('http://s/v1/sync/push'),
          body: jsonEncode(pushBody(dvc.uid, 'd1')),
        ),
      );
      expect(res.statusCode, 401);
      expect((await bodyMap(res))['error'], 'unauthorized');
    });

    test('头畸形（段数不对/scheme 不对）→ 401', () async {
      final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');
      for (final bad in ['v1 d1 onlytwo', 'v9 d1 aa bb', '']) {
        final res = await postAsRaw(
          handler,
          dvc,
          '/v1/sync/push',
          jsonEncode(pushBody(dvc.uid, 'd1')),
          header: bad,
        );
        expect(res.statusCode, 401, reason: '头 "$bad" 应被拒');
      }
    });

    test('未注册设备 → 401（即便自带签名）', () async {
      final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');
      final ghost = RegisteredDevice(
        keys: dvc.keys,
        deviceId: 'ghost',
        uid: dvc.uid,
      );
      final res = await postAs(
        handler,
        ghost,
        '/v1/sync/push',
        pushBody(dvc.uid, 'ghost'),
      );
      expect(res.statusCode, 401);
    });

    test('签名与注册公钥不符 → 401', () async {
      final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');
      // 用另一把私钥给挑战签名。
      final evil = await DeviceKeys.generate();
      final res = await handler(
        Request(
          'GET',
          Uri(
            scheme: 'http',
            host: 's',
            path: '/v1/auth/challenge',
            queryParameters: {'device_id': 'd1'},
          ),
        ),
      );
      final nonce = AuthChallenge.fromJson(await bodyMap(res)).nonceB64;
      final evilSig = await evil.sign(
        utf8.encode(authSignatureMessage('d1', nonce)),
      );
      final badHeader = buildAuthHeader(
        deviceId: 'd1',
        nonceB64: nonce,
        sigB64: base64Encode(evilSig.bytes),
      );
      final push = await postAsRaw(
        handler,
        dvc,
        '/v1/sync/push',
        jsonEncode(pushBody(dvc.uid, 'd1')),
        header: badHeader,
      );
      expect(push.statusCode, 401);
    });

    test('nonce 重放 → 第二次 401', () async {
      final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');
      final header = await dvc.authHeader(handler);
      final first = await postAsRaw(
        handler,
        dvc,
        '/v1/sync/push',
        jsonEncode(pushBody(dvc.uid, 'd1')),
        header: header,
      );
      expect(first.statusCode, 200, reason: '首次使用应通过');
      final replay = await postAsRaw(
        handler,
        dvc,
        '/v1/sync/push',
        jsonEncode(pushBody(dvc.uid, 'd1')),
        header: header,
      );
      expect(replay.statusCode, 401, reason: 'nonce 单次有效');
    });

    test('过期 nonce → 401（TTL 注入时钟验证）', () async {
      var now = DateTime(2026, 1, 1, 12);
      final ttlHandler = buildHandler(nonces: NonceTable(now: () => now));
      final dvc = await registerDevice(
        ttlHandler,
        deviceId: 'd1',
        tenant: 'u1',
      );
      final header = await dvc.authHeader(ttlHandler);
      // 快进 6 分钟：超过 5 分钟 TTL。
      now = now.add(const Duration(minutes: 6));
      final res = await postAsRaw(
        ttlHandler,
        dvc,
        '/v1/sync/push',
        jsonEncode(pushBody(dvc.uid, 'd1')),
        header: header,
      );
      expect(res.statusCode, 401);
    });

    test('TTL 边界内（4 分钟）仍可用', () async {
      var now = DateTime(2026, 1, 1, 12);
      final ttlHandler = buildHandler(nonces: NonceTable(now: () => now));
      final dvc = await registerDevice(
        ttlHandler,
        deviceId: 'd1',
        tenant: 'u1',
      );
      final header = await dvc.authHeader(ttlHandler);
      now = now.add(const Duration(minutes: 4));
      final res = await postAsRaw(
        ttlHandler,
        dvc,
        '/v1/sync/push',
        jsonEncode(pushBody(dvc.uid, 'd1')),
        header: header,
      );
      expect(res.statusCode, 200);
    });

    test('请求 uid 与注册租户不符 → 401', () async {
      final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');
      final res = await postAs(
        handler,
        dvc,
        '/v1/sync/push',
        pushBody('u-other', 'd1'),
      );
      expect(res.statusCode, 401);
    });

    test('验签通过即烧毁 nonce:改 uid 试探后,原头对正确 uid 也不可用', () async {
      // 截获的合法头先被拿去跨租户试探（401）——nonce 已被消费,
      // 随后用原头对正确 uid 重放同样 401。消费先于 uid 比对,
      // 消灭「试探失败但原头仍可重放」的窗口（ADR-016）。
      final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');
      final header = await dvc.authHeader(handler);
      final probe = await getAsWithHeader(
        handler,
        '/v1/sync/pull?since=0&limit=10&uid=u-other',
        header,
      );
      expect(probe.statusCode, 401);
      final replay = await getAsWithHeader(
        handler,
        '/v1/sync/pull?since=0&limit=10&uid=${dvc.uid}',
        header,
      );
      expect(replay.statusCode, 401, reason: 'nonce 已烧毁,重放无效');
    });

    test('跨租户 pull 隔离:同服务上 A 租户的 op 对 B 租户设备不可见', () async {
      final dvcA = await registerDevice(
        handler,
        deviceId: 'dA',
        tenant: 'tenant-A',
      );
      final dvcB = await registerDevice(
        handler,
        deviceId: 'dB',
        tenant: 'tenant-B',
      );

      final push = await postAs(handler, dvcA, '/v1/sync/push', {
        ...PushRequest(
          uid: dvcA.uid,
          deviceId: 'dA',
          ops: [op(1, 'dA')],
        ).toJson(),
      });
      expect(push.statusCode, 200);

      final pullB = PullResponse.fromJson(
        await bodyMap(
          await getAs(
            handler,
            dvcB,
            '/v1/sync/pull?since=0&limit=100&uid=${dvcB.uid}',
          ),
        ),
      );
      expect(pullB.ops, isEmpty, reason: '跨 uid 拿不到对方任何 op');

      final pullA = PullResponse.fromJson(
        await bodyMap(
          await getAs(
            handler,
            dvcA,
            '/v1/sync/pull?since=0&limit=100&uid=${dvcA.uid}',
          ),
        ),
      );
      expect(pullA.ops.single.value!.value, 'v1');
    });
  });
}

/// 带现成鉴权头的 GET（重放用例复用同一头）。
Future<Response> getAsWithHeader(Handler h, String path, String header) async {
  return h(
    Request(
      'GET',
      Uri.parse('http://s$path'),
      headers: {authHeaderName: header},
    ),
  );
}
