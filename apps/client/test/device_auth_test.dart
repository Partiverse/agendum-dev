/// R1 §2/§3/§4/§9:客户端侧设备鉴权组装 —— 挑战获取、nonce 缓存、
/// Ed25519 签名头、注册请求。用 stub http.Client,不依赖服务端新行为。
library;

import 'dart:convert';

import 'package:agendum_client/device_auth.dart';
import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {
  late DeviceKeys keys;
  late DeviceAuthService auth;
  late List<String> challengeDeviceIds;
  late Map<String, Object?>? lastRegisterBody;
  var registerStatus = 200;

  // 测试租户:走与 IdentityVault 相同的 MK → proof → uid 派生链
  // (ADR-016 §6 注册准入),不是任意字符串。
  final mk = List<int>.filled(32, 11);
  final uid = await tenantUid(mk);
  final uidProofB64 = base64Encode(await uidProof(mk));

  // 挑战端点命中次数(每 GET 一次 +1,nonce 随序号变化,各不相同)。
  var challengesServed = 0;

  /// 新鲜挑战响应体(读取计数,不自增 —— 由各 stub 统一计数)。
  http.Response freshChallenge() {
    final nonce = List<int>.generate(32, (i) => (i + challengesServed) % 256);
    return http.Response(
      jsonEncode({
        'nonce': base64Encode(nonce),
        // 5 分钟 TTL(R1 §2 服务端内存表),远未到期。
        'expires_at_ms': DateTime.now().millisecondsSinceEpoch + 5 * 60 * 1000,
      }),
      200,
    );
  }

  setUp(() async {
    keys = await DeviceKeys.generate();
    challengeDeviceIds = [];
    lastRegisterBody = null;
    registerStatus = 200;
    challengesServed = 0;
    auth = DeviceAuthService(
      base: 'http://stub',
      deviceId: 'dvc_test',
      keys: keys,
      uid: uid,
      uidProofB64: uidProofB64,
      client: MockClient((req) async {
        if (req.url.path == '/v1/auth/challenge') {
          challengeDeviceIds.add(req.url.queryParameters['device_id']!);
          challengesServed++;
          return freshChallenge();
        }
        if (req.url.path == '/v1/devices/register') {
          lastRegisterBody = (jsonDecode(req.body) as Map)
              .cast<String, Object?>();
          return http.Response(
            jsonEncode({
              'ok': true,
              'device_id': lastRegisterBody!['device_id'],
              'fingerprint': lastRegisterBody!['fingerprint'],
              'created': true,
              'registered_at': DateTime.now().millisecondsSinceEpoch,
            }),
            registerStatus,
          );
        }
        fail('意外请求:${req.url}');
      }),
    );
  });

  group('鉴权头组装(R1 §4)', () {
    test('格式 v1 <device_id> <nonce_b64> <sig_b64>,可用注册公钥验签', () async {
      final headers = await auth.authHeaders();

      expect(headers.keys, [authHeaderName]);
      final creds = parseAuthHeader(headers[authHeaderName]!);
      expect(creds.deviceId, 'dvc_test');
      expect(
        base64Decode(creds.nonceB64),
        hasLength(32),
        reason: 'R1 §2:nonce 为 32 字节',
      );
      // 验签:原文 = agendum/auth:<device_id>:<nonce_b64>,公钥 = 注册公钥。
      final ok = await DeviceKeys.verifyB64(
        message: utf8.encode(authSignatureMessage('dvc_test', creds.nonceB64)),
        sigB64: creds.sigB64,
        publicKeyB64: keys.publicKeyB64,
      );
      expect(ok, isTrue);
    });

    test('签名与原文绑定:换 nonce/设备即验不过', () async {
      final creds = parseAuthHeader(
        (await auth.authHeaders())[authHeaderName]!,
      );
      expect(
        await DeviceKeys.verifyB64(
          message: utf8.encode(
            authSignatureMessage('dvc_other', creds.nonceB64),
          ),
          sigB64: creds.sigB64,
          publicKeyB64: keys.publicKeyB64,
        ),
        isFalse,
        reason: 'device_id 不符验不过',
      );
      expect(
        await DeviceKeys.verifyB64(
          message: utf8.encode(
            authSignatureMessage('dvc_test', '${creds.nonceB64}x'),
          ),
          sigB64: creds.sigB64,
          publicKeyB64: keys.publicKeyB64,
        ),
        isFalse,
        reason: 'nonce 不符验不过',
      );
    });

    test('挑战按 device_id 获取;两次请求各取新 nonce(单次有效不复用)', () async {
      final h1 = await auth.authHeaders();
      final h2 = await auth.authHeaders();

      expect(challengeDeviceIds, ['dvc_test', 'dvc_test']);
      final n1 = parseAuthHeader(h1[authHeaderName]!).nonceB64;
      final n2 = parseAuthHeader(h2[authHeaderName]!).nonceB64;
      expect(n1, isNot(n2), reason: 'nonce 单次有效:每请求新挑战');
    });

    test('挑战获取非 200 → SyncTransportException(带状态码)', () async {
      final failing = DeviceAuthService(
        base: 'http://stub',
        deviceId: 'dvc_test',
        keys: keys,
        uid: uid,
        uidProofB64: uidProofB64,
        client: MockClient((req) async => http.Response('nope', 404)),
      );
      await expectLater(
        failing.authHeaders(),
        throwsA(
          isA<SyncTransportException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });
  });

  group('nonce 缓存(R1 §9)', () {
    test('prefetch 后首个请求不再取挑战,消费后下一请求重新取', () async {
      await auth.prefetch();
      expect(challengesServed, 1);

      await auth.authHeaders();
      expect(challengesServed, 1, reason: '预取 nonce 被复用一次');

      await auth.authHeaders();
      expect(challengesServed, 2, reason: '缓存已消费,取新挑战(单次有效)');
    });

    test('过期预取挑战不使用,直接取新挑战', () async {
      final expiredNonce = base64Encode(List.filled(32, 1));
      // 首个挑战回过期 nonce(模拟预取后搁置超过 TTL)。
      final auth2 = DeviceAuthService(
        base: 'http://stub',
        deviceId: 'dvc_test',
        keys: keys,
        uid: uid,
        uidProofB64: uidProofB64,
        client: MockClient((req) async {
          if (req.url.path == '/v1/devices/register') {
            return http.Response(
              jsonEncode({'ok': true, 'device_id': 'dvc_test'}),
              200,
            );
          }
          challengesServed++;
          if (challengesServed == 1) {
            return http.Response(
              jsonEncode({
                'nonce': expiredNonce,
                'expires_at_ms': DateTime.now().millisecondsSinceEpoch - 1000,
              }),
              200,
            );
          }
          return freshChallenge();
        }),
      );

      await auth2.prefetch();
      final h = await auth2.authHeaders();
      expect(challengesServed, 2, reason: '过期 nonce 弃用,取新挑战');
      expect(parseAuthHeader(h[authHeaderName]!).nonceB64, isNot(expiredNonce));
    });
  });

  group('设备注册(R1 §3)', () {
    test('body 携带 uid/pubkey_b64/sig_b64,签名可用上传公钥验证', () async {
      await auth.register();

      final body = lastRegisterBody!;
      expect(body['device_id'], 'dvc_test');
      expect(body['uid'], uid);
      expect(body['algorithm'], 'ed25519');
      expect(body['pubkey_b64'], keys.publicKeyB64);
      expect(body['fingerprint'], keys.fingerprint);
      // 验签原文 = agendum/register:<fingerprint>,公钥即上传的 pubkey_b64
      // (服务端 R1 §3 验签不过 400 的客户端侧镜像)。
      final ok = await DeviceKeys.verifyB64(
        message: utf8.encode(
          registerSignatureMessage(body['fingerprint']! as String),
        ),
        sigB64: body['sig_b64']! as String,
        publicKeyB64: body['pubkey_b64']! as String,
      );
      expect(ok, isTrue);
      // ADR-016 §6:body 携带 uid_proof,且 uid = hex(HKDF(uid_proof))
      // (与服务端 verifyUidOwnership 同一派生关系)。
      expect(body['uid_proof'], uidProofB64);
      final derived = hexEncode(
        await hkdfSha256(
          base64Decode(body['uid_proof']! as String),
          info: uidInfo,
          outputLength: 16,
        ),
      );
      expect(derived, body['uid']);
    });

    test('非 200 → SyncTransportException', () async {
      registerStatus = 400;
      await expectLater(
        auth.register(),
        throwsA(
          isA<SyncTransportException>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });
  });
}
