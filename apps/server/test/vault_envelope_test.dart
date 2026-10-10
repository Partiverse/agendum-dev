/// 信封端点行为（R1 §6）：不透明存储、最新一条、仅限本 uid 设备读写。
library;

import 'dart:convert';

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

  VaultEnvelope envelope(String uid, String deviceId, String secret) =>
      VaultEnvelope(
        uid: uid,
        deviceId: deviceId,
        envelopeB64: base64Encode(utf8.encode('kek-enveloped:$secret')),
      );

  group('R1 §6 /v1/vault/envelope', () {
    test('上传后取回最新一条;重复上传覆盖（GET 返回最新）', () async {
      final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');

      final put1 = await postAs(
        handler,
        dvc,
        '/v1/vault/envelope',
        envelope(dvc.uid, 'd1', '第一版').toJson(),
      );
      expect(put1.statusCode, 200);
      expect((await bodyMap(put1))['ok'], true);

      final got1 = VaultEnvelope.fromJson(
        await bodyMap(
          await getAs(handler, dvc, '/v1/vault/envelope?uid=${dvc.uid}'),
        ),
      );
      expect(got1.envelopeB64, envelope(dvc.uid, 'd1', '第一版').envelopeB64);
      expect(got1.deviceId, 'd1');

      final put2 = await postAs(
        handler,
        dvc,
        '/v1/vault/envelope',
        envelope(dvc.uid, 'd1', '第二版').toJson(),
      );
      expect(put2.statusCode, 200);
      final got2 = VaultEnvelope.fromJson(
        await bodyMap(
          await getAs(handler, dvc, '/v1/vault/envelope?uid=${dvc.uid}'),
        ),
      );
      expect(
        got2.envelopeB64,
        envelope(dvc.uid, 'd1', '第二版').envelopeB64,
        reason: 'GET 返回最新一条',
      );
    });

    test('同租户第二台设备可读（多设备恢复路径）,跨租户不可读', () async {
      await registerDevice(handler, deviceId: 'd1', tenant: 'u1');
      final dvc2 = await registerDevice(handler, deviceId: 'd2', tenant: 'u1');
      final dvcX = await registerDevice(
        handler,
        deviceId: 'dx',
        tenant: 'u-evil',
      );

      final put = await postAs(
        handler,
        dvc2,
        '/v1/vault/envelope',
        envelope(dvc2.uid, 'd2', '共享信封').toJson(),
      );
      expect(put.statusCode, 200);

      // 同 uid 的另一台设备可读回。
      final got = await getAs(
        handler,
        dvc2,
        '/v1/vault/envelope?uid=${dvc2.uid}',
      );
      expect(got.statusCode, 200);
      expect(
        (await bodyMap(got))['envelope_b64'],
        envelope(dvc2.uid, 'd2', '共享信封').envelopeB64,
      );

      // 跨 uid 设备：GET 对方 uid → 401。
      final steal = await getAs(
        handler,
        dvcX,
        '/v1/vault/envelope?uid=${dvc2.uid}',
      );
      expect(steal.statusCode, 401);

      // 跨 uid 设备：往对方 uid 写 → 401。
      final poison = await postAs(
        handler,
        dvcX,
        '/v1/vault/envelope',
        envelope(dvc2.uid, 'dx', '毒信封').toJson(),
      );
      expect(poison.statusCode, 401);

      // 毒写未生效：内容仍是合法设备的信封。
      final after = await getAs(
        handler,
        dvc2,
        '/v1/vault/envelope?uid=${dvc2.uid}',
      );
      expect(
        (await bodyMap(after))['envelope_b64'],
        envelope(dvc2.uid, 'd2', '共享信封').envelopeB64,
      );
    });

    test('无信封时 GET → 404;缺 uid → 400;无鉴权头 → 401', () async {
      final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');

      final empty = await getAs(
        handler,
        dvc,
        '/v1/vault/envelope?uid=${dvc.uid}',
      );
      expect(empty.statusCode, 404);
      expect((await bodyMap(empty))['error'], 'not_found');

      final noUid = await getAs(handler, dvc, '/v1/vault/envelope');
      expect(noUid.statusCode, 400);

      final noAuth = await handler(
        Request('GET', Uri.parse('http://s/v1/vault/envelope?uid=${dvc.uid}')),
      );
      expect(noAuth.statusCode, 401);
    });

    test('body 缺字段/非 base64 → 400', () async {
      final dvc = await registerDevice(handler, deviceId: 'd1', tenant: 'u1');
      final missing = await postAs(handler, dvc, '/v1/vault/envelope', {
        'uid': dvc.uid,
        'device_id': 'd1',
      });
      expect(missing.statusCode, 400);

      final notB64 = await postAs(handler, dvc, '/v1/vault/envelope', {
        'uid': dvc.uid,
        'device_id': 'd1',
        'envelope_b64': '!!!not-base64!!!',
      });
      expect(notB64.statusCode, 400);
    });
  });
}
