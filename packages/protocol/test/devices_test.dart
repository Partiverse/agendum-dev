import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:test/test.dart';

void main() {
  final keyB64 = base64Encode(List<int>.generate(32, (i) => i));
  final sigB64 = base64Encode(List<int>.generate(64, (i) => i % 8));

  group('DeviceRegistrationRequest(R1 §3 扩展)', () {
    test('往返:既有字段 + uid/pubkey_b64/sig_b64', () {
      final req = DeviceRegistrationRequest(
        deviceId: 'd1',
        algorithm: deviceKeyAlgorithm,
        publicKeyB64: keyB64,
        fingerprint: 'AB12',
        uid: 'dev-plain',
        pubkeyB64: keyB64,
        sigB64: sigB64,
      );
      final json = req.toJson();
      expect(json.keys.toSet(), {
        // 既有键(语义不变)
        'device_id', 'algorithm', 'public_key', 'fingerprint',
        // R1 §3 新增键
        'uid', 'pubkey_b64', 'sig_b64',
        // ADR-016 §6:uid_proof 可选(dev-plain 豁免)→ 缺省不出现
      });
      expect(json.containsKey('uid_proof'), isFalse);
      final back = DeviceRegistrationRequest.fromJson(json);
      expect(back.deviceId, 'd1');
      expect(back.algorithm, 'ed25519');
      expect(back.publicKeyB64, keyB64);
      expect(back.fingerprint, 'AB12');
      expect(back.uid, 'dev-plain');
      expect(back.pubkeyB64, keyB64);
      expect(back.sigB64, sigB64);
      expect(back.uidProofB64, isNull);
    });

    test('往返:uid_proof(ADR-016 §6)随请求携带', () {
      final proofB64 = base64Encode(
        List<int>.generate(uidProofBytes, (i) => i),
      );
      final req = DeviceRegistrationRequest(
        deviceId: 'd1',
        algorithm: deviceKeyAlgorithm,
        publicKeyB64: keyB64,
        fingerprint: 'AB12',
        uid: 'aabb',
        pubkeyB64: keyB64,
        sigB64: sigB64,
        uidProofB64: proofB64,
      );
      final json = req.toJson();
      expect(json['uid_proof'], proofB64);
      final back = DeviceRegistrationRequest.fromJson(json);
      expect(back.uidProofB64, proofB64);
    });

    test('uid_proof 非 32 字节 → FormatException(ADR-016 §6)', () {
      Map<String, Object?> base() => {
        'device_id': 'd1',
        'algorithm': 'ed25519',
        'public_key': keyB64,
        'fingerprint': 'AB12',
        'uid': 'aabb',
        'pubkey_b64': keyB64,
        'sig_b64': sigB64,
      };
      expect(
        () => DeviceRegistrationRequest.fromJson(
          base()..['uid_proof'] = base64Encode(List<int>.filled(16, 1)),
        ),
        throwsFormatException,
        reason: '证明必须 32 字节',
      );
      expect(
        () => DeviceRegistrationRequest.fromJson(base()..['uid_proof'] = '!!'),
        throwsFormatException,
        reason: '非法 base64',
      );
    });

    test('缺 uid/pubkey_b64/sig_b64 任一拒绝', () {
      Map<String, Object?> base() => {
        'device_id': 'd1',
        'algorithm': 'ed25519',
        'public_key': keyB64,
        'fingerprint': 'AB12',
        'uid': 'dev-plain',
        'pubkey_b64': keyB64,
        'sig_b64': sigB64,
      };
      for (final k in ['uid', 'pubkey_b64', 'sig_b64']) {
        final json = base()..remove(k);
        expect(
          () => DeviceRegistrationRequest.fromJson(json),
          throwsFormatException,
        );
      }
    });

    test('pubkey_b64/sig_b64 非法 base64 拒绝', () {
      Map<String, Object?> base() => {
        'device_id': 'd1',
        'algorithm': 'ed25519',
        'public_key': keyB64,
        'fingerprint': 'AB12',
        'uid': 'dev-plain',
        'pubkey_b64': keyB64,
        'sig_b64': sigB64,
      };
      expect(
        () => DeviceRegistrationRequest.fromJson(base()..['pubkey_b64'] = '!!'),
        throwsFormatException,
      );
      expect(
        () => DeviceRegistrationRequest.fromJson(base()..['sig_b64'] = '!!'),
        throwsFormatException,
      );
    });

    test('既有校验保持:public_key/device_id 非法仍拒绝', () {
      expect(
        () => DeviceRegistrationRequest.fromJson({
          'device_id': '',
          'algorithm': 'ed25519',
          'public_key': keyB64,
          'fingerprint': 'AB12',
          'uid': 'u',
          'pubkey_b64': keyB64,
          'sig_b64': sigB64,
        }),
        throwsFormatException,
      );
    });
  });
}
