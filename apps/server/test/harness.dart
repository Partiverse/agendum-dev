/// 服务端测试公共脚手架：真实 Ed25519 密钥的设备注册与鉴权头组装。
///
/// 全程走与客户端一致的协议路径（packages/protocol 常量 + packages/e2ee
/// DeviceKeys 签名 + uid 归属证明推导）——测试不伪造签名格式,断言的是
/// 真实安全行为。
///
/// 租户固定装置（ADR-016 §6）：注册准入要求 uid = hex(HKDF(uid_proof))，
/// 任意字符串当不了 uid。测试用 label → 确定性 MK → (uid, proof)，与
/// 客户端 IdentityVault 同一条派生链；`tenantUidOf('u1')` 即该租户 uid。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:shelf/shelf.dart';

/// label → 确定性测试 MK（同一 label 恒得同一 uid/proof）。
Future<Uint8List> tenantMk(String label) =>
    hkdfSha256(utf8.encode(label), info: 'agendum/test/tenant-mk');

/// label 对应租户的 uid（注册时实际绑定的值）。
Future<String> tenantUidOf(String label) async =>
    tenantUid(await tenantMk(label));

/// label 对应租户的注册归属证明（wire `uid_proof`，base64）。
Future<String> tenantProofB64(String label) async =>
    base64Encode(await uidProof(await tenantMk(label)));

/// 已注册设备：密钥 + 服务端绑定（deviceId → uid）。
final class RegisteredDevice {
  RegisteredDevice({
    required this.keys,
    required this.deviceId,
    required this.uid,
  });

  final DeviceKeys keys;
  final String deviceId;
  final String uid;

  /// 取一次性挑战并签名,组装 `X-Agendum-Auth` 头（每次调用消耗一个 nonce）。
  Future<String> authHeader(Handler h) async {
    final res = await h(
      Request(
        'GET',
        Uri(
          scheme: 'http',
          host: 's',
          path: '/v1/auth/challenge',
          queryParameters: {'device_id': deviceId},
        ),
      ),
    );
    if (res.statusCode != 200) {
      throw StateError('挑战获取失败 HTTP ${res.statusCode}');
    }
    final challenge = AuthChallenge.fromJson(
      (jsonDecode(await res.readAsString()) as Map).cast<String, Object?>(),
    );
    return signAuthHeader(challenge.nonceB64);
  }

  /// 用既有 nonce 组装鉴权头（重放用例直接复用）。
  Future<String> signAuthHeader(String nonceB64) async {
    final sig = await keys.sign(
      utf8.encode(authSignatureMessage(deviceId, nonceB64)),
    );
    return buildAuthHeader(
      deviceId: deviceId,
      nonceB64: nonceB64,
      sigB64: base64Encode(sig.bytes),
    );
  }
}

/// 走真实注册端点：生成密钥对、正确签名与 uid 归属证明，
/// 绑定 [deviceId] → [tenant] 派生出的 uid。
Future<RegisteredDevice> registerDevice(
  Handler h, {
  required String deviceId,
  required String tenant,
}) async {
  final keys = await DeviceKeys.generate();
  final uid = await tenantUidOf(tenant);
  final sig = await keys.sign(
    utf8.encode(registerSignatureMessage(keys.fingerprint)),
  );
  final res = await h(
    Request(
      'POST',
      Uri.parse('http://s/v1/devices/register'),
      body: jsonEncode({
        'device_id': deviceId,
        'algorithm': DeviceKeys.algorithm,
        'public_key': keys.publicKeyB64,
        'fingerprint': keys.fingerprint,
        'uid': uid,
        'uid_proof': await tenantProofB64(tenant),
        'pubkey_b64': keys.publicKeyB64,
        'sig_b64': base64Encode(sig.bytes),
      }),
    ),
  );
  if (res.statusCode != 200) {
    throw StateError(
      '注册失败 HTTP ${res.statusCode}: ${await res.readAsString()}',
    );
  }
  return RegisteredDevice(keys: keys, deviceId: deviceId, uid: uid);
}

/// 带 [RegisteredDevice] 鉴权头的 GET。
Future<Response> getAs(Handler h, RegisteredDevice d, String path) async {
  return h(
    Request(
      'GET',
      Uri.parse('http://s$path'),
      headers: {authHeaderName: await d.authHeader(h)},
    ),
  );
}

/// 带 [RegisteredDevice] 鉴权头的 POST（JSON body）。
/// [header] 覆盖默认的自动取挑战签名（重放/缺头用例用）。
Future<Response> postAs(
  Handler h,
  RegisteredDevice d,
  String path,
  Object? body, {
  String? header,
}) async {
  return postAsRaw(h, d, path, jsonEncode(body), header: header);
}

/// 带 [RegisteredDevice] 鉴权头的 POST（原样字符串 body,坏 JSON 用例用）。
Future<Response> postAsRaw(
  Handler h,
  RegisteredDevice d,
  String path,
  String body, {
  String? header,
}) async {
  return h(
    Request(
      'POST',
      Uri.parse('http://s$path'),
      headers: {authHeaderName: header ?? await d.authHeader(h)},
      body: body,
    ),
  );
}

Future<Map<String, Object?>> bodyMap(Response res) async =>
    (jsonDecode(await res.readAsString()) as Map).cast<String, Object?>();
