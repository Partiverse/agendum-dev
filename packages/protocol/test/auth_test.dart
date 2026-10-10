import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:test/test.dart';

void main() {
  final nonce32 = base64Encode(List<int>.generate(32, (i) => i));

  group('AuthChallenge(R1 §2:GET /v1/auth/challenge)', () {
    test('往返与 wire 键名', () {
      final c = AuthChallenge(nonceB64: nonce32, expiresAtMs: 1760000000000);
      final json = c.toJson();
      expect(json.keys.toSet(), {'nonce', 'expires_at_ms'});
      final back = AuthChallenge.fromJson(json);
      expect(back.nonceB64, nonce32);
      expect(back.expiresAtMs, 1760000000000);
    });

    test('nonce 非 32 字节拒绝', () {
      expect(
        () => AuthChallenge.fromJson({
          'nonce': base64Encode(List<int>.filled(31, 1)),
          'expires_at_ms': 1,
        }),
        throwsFormatException,
      );
      expect(
        () => AuthChallenge.fromJson({
          'nonce': base64Encode(List<int>.filled(33, 1)),
          'expires_at_ms': 1,
        }),
        throwsFormatException,
      );
    });

    test('nonce 非法 base64 拒绝', () {
      expect(
        () => AuthChallenge.fromJson({
          'nonce': '!!不是base64!!',
          'expires_at_ms': 1,
        }),
        throwsFormatException,
      );
    });

    test('字段缺失或类型非法抛 FormatException', () {
      expect(
        () => AuthChallenge.fromJson({'nonce': nonce32}),
        throwsFormatException,
      );
      expect(
        () => AuthChallenge.fromJson({'expires_at_ms': 1}),
        throwsFormatException,
      );
      expect(
        () =>
            AuthChallenge.fromJson({'nonce': nonce32, 'expires_at_ms': 'soon'}),
        throwsFormatException,
      );
    });
  });

  group('签名原文(R1 §3/§4 前缀钉死)', () {
    test('注册', () {
      expect(registerSignatureMessage('AB12'), 'agendum/register:AB12');
    });

    test('鉴权', () {
      expect(authSignatureMessage('d1', 'Tg=='), 'agendum/auth:d1:Tg==');
    });
  });

  group('X-Agendum-Auth 头(R1 §4)', () {
    test('常量按契约命名', () {
      expect(authHeaderName, 'X-Agendum-Auth');
      expect(authHeaderScheme, 'v1');
    });

    test('组装格式:v1 <device_id> <nonce_b64> <sig_b64>', () {
      expect(
        buildAuthHeader(deviceId: 'd1', nonceB64: 'Tg==', sigB64: 'c2ln'),
        'v1 d1 Tg== c2ln',
      );
    });

    test('解析往返', () {
      final cred = parseAuthHeader(
        buildAuthHeader(deviceId: 'd1', nonceB64: 'Tg==', sigB64: 'c2ln'),
      );
      expect(cred.deviceId, 'd1');
      expect(cred.nonceB64, 'Tg==');
      expect(cred.sigB64, 'c2ln');
    });

    test('畸形头抛 FormatException', () {
      expect(() => parseAuthHeader('v2 d1 Tg== c2ln'), throwsFormatException);
      expect(() => parseAuthHeader('v1 d1 Tg=='), throwsFormatException);
      expect(
        () => parseAuthHeader('v1 d1 Tg== c2ln 多余'),
        throwsFormatException,
      );
      expect(() => parseAuthHeader(''), throwsFormatException);
    });
  });
}
