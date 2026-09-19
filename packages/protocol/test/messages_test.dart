import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:test/test.dart';

SyncOp op(int lamport, {SyncOpType type = SyncOpType.set}) => SyncOp(
  deviceId: 'd1',
  lamport: lamport,
  entity: 'task',
  entityId: 't1',
  field: 'title',
  type: type,
  value: type == SyncOpType.set ? const OpValue(OpValueTypes.str, '买牛奶') : null,
);

void main() {
  group('PushRequest/Response', () {
    test('往返', () {
      final req = PushRequest(deviceId: 'd1', ops: [op(1), op(2)]);
      final back = PushRequest.fromJson(req.toJson());
      expect(back.deviceId, 'd1');
      expect(back.ops.length, 2);

      final resp = PushResponse(
        serverSeq: 10440,
        results: [
          const PushOpResult(index: 0, accepted: true),
          const PushOpResult(index: 1, accepted: false, reason: 'stale'),
        ],
      );
      final rBack = PushResponse.fromJson(resp.toJson());
      expect(rBack.serverSeq, 10440);
      expect(rBack.results[1].reason, 'stale');
    });

    test('超过单批上限拒绝', () {
      expect(
        () => PushRequest.fromJson({
          'device_id': 'd1',
          'ops': List.generate(
            PushRequest.maxBatchSize + 1,
            (i) => op(i).toJson(),
          ),
        }),
        throwsFormatException,
      );
    });
  });

  group('PullResponse', () {
    test('往返', () {
      final resp = PullResponse(cursor: 10441, ops: [op(7)], hasMore: false);
      final back = PullResponse.fromJson(resp.toJson());
      expect(back.cursor, 10441);
      expect(back.ops.single.lamport, 7);
      expect(back.hasMore, isFalse);
    });

    test('字段缺失抛 FormatException', () {
      expect(() => PullResponse.fromJson({'cursor': 1}), throwsFormatException);
    });
  });

  test('protocolVersion', () {
    expect(protocolVersion, 'v1');
  });
}
