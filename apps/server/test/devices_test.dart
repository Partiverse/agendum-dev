/// 设备注册端点（S07 + R1 §3 + ADR-016 §6）：指纹绑定、注册验签、
/// uid 归属证明（注册准入）、uid 绑定、幂等重注册。
library;

import 'dart:convert';

import 'package:agendum_e2ee/agendum_e2ee.dart' hide devPlaintextUid;
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_server/agendum_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'harness.dart';

void main() {
  Future<Map<String, Object?>> post(
    Handler h,
    String path,
    Object? body,
  ) async {
    final res = await h(
      Request('POST', Uri.parse('http://s$path'), body: jsonEncode(body)),
    );
    return {'status': res.statusCode, ...(await bodyMap(res))};
  }

  /// 组装一份签名与归属证明都正确的注册体（供各用例篡改单个字段）。
  Future<Map<String, Object?>> validBody(String deviceId, String tenant) async {
    final keys = await DeviceKeys.generate();
    final sig = await keys.sign(
      utf8.encode(registerSignatureMessage(keys.fingerprint)),
    );
    return {
      'device_id': deviceId,
      'algorithm': DeviceKeys.algorithm,
      'public_key': keys.publicKeyB64,
      'fingerprint': keys.fingerprint,
      'uid': await tenantUidOf(tenant),
      'uid_proof': await tenantProofB64(tenant),
      'pubkey_b64': keys.publicKeyB64,
      'sig_b64': base64Encode(sig.bytes),
    };
  }

  test('注册成功:指纹校验通过并回显,绑定 uid;重复注册幂等且不换绑', () async {
    final dir = MemoryDeviceDirectory();
    final h = buildHandler(devices: dir);
    final body = await validBody('dvc_test_1', 'tenant-1');

    final r1 = await post(h, '/v1/devices/register', body);
    expect(r1['status'], 200);
    expect(r1['ok'], true);
    expect(r1['created'], true);
    expect(r1['fingerprint'], body['fingerprint']);
    expect((await dir.byId('dvc_test_1'))!.uid, await tenantUidOf('tenant-1'));

    // 同设备重复注册（同钥同 uid）→ created=false,registered_at 不变。
    final r2 = await post(h, '/v1/devices/register', body);
    expect(r2['status'], 200);
    expect(r2['created'], false);
    expect(r2['registered_at'], r1['registered_at']);

    // 换新钥/换 uid 再注册同 deviceId → 首绑为准:公钥与 uid 都不换绑
    // （防注册通道把已有设备改挂到别的租户）。
    final other = await validBody('dvc_test_1', 'tenant-evil');
    final r3 = await post(h, '/v1/devices/register', other);
    expect(r3['status'], 200);
    expect(r3['created'], false);
    final rec = await dir.byId('dvc_test_1');
    expect(rec!.publicKeyB64, body['public_key'], reason: '公钥不换绑');
    expect(rec.uid, await tenantUidOf('tenant-1'), reason: 'uid 不换绑');
  });

  test('指纹与公钥不符 → 400 fingerprint_mismatch', () async {
    final h = buildHandler();
    final body = await validBody('dvc_evil', 'tenant-1');
    body['fingerprint'] = 'AAAA-BBBB-CCCC-DDDD-EEEE-FFFF-0000-1111';
    final r = await post(h, '/v1/devices/register', body);
    expect(r['status'], 400);
    expect(r['error'], 'fingerprint_mismatch');
  });

  test('R1 §3:注册签名错误 → 400 signature_mismatch', () async {
    final h = buildHandler();

    // 用另一把私钥签（公钥对不上签名）。
    final body = await validBody('dvc_bad_sig', 'tenant-1');
    final evil = await DeviceKeys.generate();
    final evilSig = await evil.sign(
      utf8.encode(registerSignatureMessage(body['fingerprint'] as String)),
    );
    body['sig_b64'] = base64Encode(evilSig.bytes);
    final r1 = await post(h, '/v1/devices/register', body);
    expect(r1['status'], 400);
    expect(r1['error'], 'signature_mismatch');

    // 签名原文被篡改（对别的 fingerprint 签名）。
    final body2 = await validBody('dvc_bad_sig2', 'tenant-1');
    final keys2 = await DeviceKeys.generate();
    final wrongMsgSig = await keys2.sign(
      utf8.encode(
        registerSignatureMessage('AAAA-BBBB-CCCC-DDDD-EEEE-FFFF-0000-1111'),
      ),
    );
    body2['public_key'] = keys2.publicKeyB64;
    body2['pubkey_b64'] = keys2.publicKeyB64;
    body2['fingerprint'] = keys2.fingerprint;
    body2['sig_b64'] = base64Encode(wrongMsgSig.bytes);
    final r2 = await post(h, '/v1/devices/register', body2);
    expect(r2['status'], 400);
    expect(r2['error'], 'signature_mismatch');
  });

  test('ADR-016 §6:缺 uid_proof → 400 uid_proof_missing（知悉 uid 不够）', () async {
    final h = buildHandler();
    final body = await validBody('dvc_no_proof', 'tenant-1')
      ..remove('uid_proof');
    final r = await post(h, '/v1/devices/register', body);
    expect(r['status'], 400);
    expect(r['error'], 'uid_proof_missing');
  });

  test('ADR-016 §6:uid 与证明不符 → 400 uid_proof_mismatch（只知 uid 无法入租户）', () async {
    final h = buildHandler();

    // 拿 tenant-1 的证明注册到 tenant-2 的 uid 名下 → 拒绝。
    final body = await validBody('dvc_wrong_proof', 'tenant-1');
    body['uid'] = await tenantUidOf('tenant-2');
    final r = await post(h, '/v1/devices/register', body);
    expect(r['status'], 400);
    expect(r['error'], 'uid_proof_mismatch');

    // 证明是随便的 32 字节（非 HKDF 派生）→ 同样拒绝。
    final body2 = await validBody('dvc_junk_proof', 'tenant-1');
    body2['uid_proof'] = base64Encode(List<int>.filled(32, 7));
    final r2 = await post(h, '/v1/devices/register', body2);
    expect(r2['status'], 400);
    expect(r2['error'], 'uid_proof_mismatch');
  });

  test('ADR-016 §6:归属证明派生链两端同构(独立实现互证)', () async {
    // 服务端 verifyUidOwnership 与 e2ee 的 uidProof/tenantUid 独立实现:
    // 正确 proof 放行、篡改 proof 拒绝(直接对拍),真实注册路径全绿
    // 即两端推导一致(同指纹互证的做法)。
    final dir = MemoryDeviceDirectory();
    final h = buildHandler(devices: dir);
    final r = await post(
      h,
      '/v1/devices/register',
      await validBody('dvc_derive', 'tenant-derive'),
    );
    expect(r['status'], 200);
    expect(
      (await dir.byId('dvc_derive'))!.uid,
      await tenantUidOf('tenant-derive'),
    );
    final mk = await tenantMk('tenant-derive');
    expect(
      await verifyUidOwnership(
        uid: await tenantUid(mk),
        uidProof: await uidProof(mk),
      ),
      isTrue,
    );
    expect(
      await verifyUidOwnership(
        uid: await tenantUid(mk),
        uidProof: List<int>.filled(32, 1),
      ),
      isFalse,
      reason: '非派生 proof 不得通过准入',
    );
  });

  test('ADR-016 §6:明文开发租户 dev-plain 豁免归属证明', () async {
    final h = buildHandler();
    final keys = await DeviceKeys.generate();
    final sig = await keys.sign(
      utf8.encode(registerSignatureMessage(keys.fingerprint)),
    );
    final r = await post(h, '/v1/devices/register', {
      'device_id': 'dvc_plain',
      'algorithm': DeviceKeys.algorithm,
      'public_key': keys.publicKeyB64,
      'fingerprint': keys.fingerprint,
      'uid': devPlaintextUid,
      'pubkey_b64': keys.publicKeyB64,
      'sig_b64': base64Encode(sig.bytes),
    });
    expect(r['status'], 200, reason: 'dev-plain 无 Vault,注册准入豁免');
  });

  test('R1 §3:pubkey_b64 与 public_key 不一致 → 400（指纹必须锚定验签公钥）', () async {
    final h = buildHandler();
    final body = await validBody('dvc_key_swap', 'tenant-1');
    final other = await DeviceKeys.generate();
    body['pubkey_b64'] = other.publicKeyB64;
    final r = await post(h, '/v1/devices/register', body);
    expect(r['status'], 400);
    expect(r['error'], 'bad_request');
  });

  test('algorithm 非 ed25519 → 400', () async {
    final h = buildHandler();
    final body = await validBody('dvc_alg', 'tenant-1');
    body['algorithm'] = 'rsa';
    final r = await post(h, '/v1/devices/register', body);
    expect(r['status'], 400);
  });

  test('缺字段（含 R1 新增的 uid/pubkey_b64/sig_b64）→ 400 bad_request', () async {
    final h = buildHandler();
    final r = await post(h, '/v1/devices/register', {'device_id': 'x'});
    expect(r['status'], 400);
    expect(r['error'], 'bad_request');

    // 旧格式（无 R1 三字段）不再被接受。
    final keys = await DeviceKeys.generate();
    final legacy = await post(h, '/v1/devices/register', {
      'device_id': 'dvc_legacy',
      'algorithm': DeviceKeys.algorithm,
      'public_key': keys.publicKeyB64,
      'fingerprint': keys.fingerprint,
    });
    expect(legacy['status'], 400);
  });

  test('客户端指纹构造与服务端同构(独立实现互证)', () async {
    final keys = await DeviceKeys.generate();
    final serverSide = fingerprintFromKeyBytes(keys.publicKey);
    expect(serverSide, keys.fingerprint);
  });
}
