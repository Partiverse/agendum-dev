/// 设备注册端点（S07）：密钥指纹绑定、指纹不符拒绝、幂等重注册。
library;

import 'dart:convert';

import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:agendum_server/agendum_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  Future<Map<String, Object?>> post(
    Handler h,
    String path,
    Object? body,
  ) async {
    final res = await h(
      Request('POST', Uri.parse('http://s$path'), body: jsonEncode(body)),
    );
    return {
      'status': res.statusCode,
      ...(jsonDecode(await res.readAsString()) as Map).cast<String, Object?>(),
    };
  }

  test('注册成功:指纹校验通过并回显;重复注册幂等', () async {
    final keys = await DeviceKeys.generate();
    final h = buildHandler();

    final r1 = await post(h, '/v1/devices/register', {
      'device_id': 'dvc_test_1',
      'algorithm': DeviceKeys.algorithm,
      'public_key': keys.publicKeyB64,
      'fingerprint': keys.fingerprint,
    });
    expect(r1['status'], 200);
    expect(r1['ok'], true);
    expect(r1['created'], true);
    expect(r1['fingerprint'], keys.fingerprint);

    final r2 = await post(h, '/v1/devices/register', {
      'device_id': 'dvc_test_1',
      'algorithm': DeviceKeys.algorithm,
      'public_key': keys.publicKeyB64,
      'fingerprint': keys.fingerprint,
    });
    expect(r2['status'], 200);
    expect(r2['created'], false);
    expect(r2['registered_at'], r1['registered_at']);
  });

  test('指纹与公钥不符 → 400 fingerprint_mismatch', () async {
    final keys = await DeviceKeys.generate();
    final h = buildHandler();
    final r = await post(h, '/v1/devices/register', {
      'device_id': 'dvc_evil',
      'algorithm': DeviceKeys.algorithm,
      'public_key': keys.publicKeyB64,
      'fingerprint': 'AAAA-BBBB-CCCC-DDDD-EEEE-FFFF-0000-1111',
    });
    expect(r['status'], 400);
    expect(r['error'], 'fingerprint_mismatch');
  });

  test('缺字段 → 400 bad_request', () async {
    final h = buildHandler();
    final r = await post(h, '/v1/devices/register', {'device_id': 'x'});
    expect(r['status'], 400);
    expect(r['error'], 'bad_request');
  });

  test('客户端指纹构造与服务端同构(独立实现互证)', () async {
    final keys = await DeviceKeys.generate();
    final serverSide = fingerprintFromKeyBytes(keys.publicKey);
    expect(serverSide, keys.fingerprint);
  });
}
