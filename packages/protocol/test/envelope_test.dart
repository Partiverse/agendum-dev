import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:test/test.dart';

void main() {
  final envelopeB64 = base64Encode(List<int>.generate(48, (i) => i * 3));

  group('VaultEnvelope(R1 §6:/v1/vault/envelope)', () {
    test('往返与 wire 键名(上传体与 GET 响应同形)', () {
      final env = VaultEnvelope(
        uid: 'dev-plain',
        deviceId: 'd1',
        envelopeB64: envelopeB64,
      );
      final json = env.toJson();
      expect(json.keys.toSet(), {'uid', 'device_id', 'envelope_b64'});
      final back = VaultEnvelope.fromJson(json);
      expect(back.uid, 'dev-plain');
      expect(back.deviceId, 'd1');
      expect(back.envelopeB64, envelopeB64);
    });

    test('缺任一字段抛 FormatException', () {
      expect(
        () => VaultEnvelope.fromJson({
          'device_id': 'd1',
          'envelope_b64': envelopeB64,
        }),
        throwsFormatException,
      );
      expect(
        () => VaultEnvelope.fromJson({'uid': 'u', 'envelope_b64': envelopeB64}),
        throwsFormatException,
      );
      expect(
        () => VaultEnvelope.fromJson({'uid': 'u', 'device_id': 'd1'}),
        throwsFormatException,
      );
    });

    test('envelope_b64 非法 base64 拒绝', () {
      expect(
        () => VaultEnvelope.fromJson({
          'uid': 'u',
          'device_id': 'd1',
          'envelope_b64': '!!不是base64!!',
        }),
        throwsFormatException,
      );
    });
  });
}
