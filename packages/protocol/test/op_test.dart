import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('OpValue', () {
    test('JSON 往返', () {
      const v = OpValue(OpValueTypes.date, 20650);
      expect(OpValue.fromJson(v.toJson()), v);
    });

    test('缺类型标签抛 FormatException', () {
      expect(() => OpValue.fromJson({'v': 1}), throwsFormatException);
    });
  });

  group('SyncOp', () {
    final op = SyncOp(
      deviceId: 'dvc_9f2',
      lamport: 1042,
      entity: SyncEntities.task,
      entityId: '01912ab3-0000-7000-8000-000000000000',
      field: 'due_date',
      type: SyncOpType.set,
      value: const OpValue(OpValueTypes.date, 20650),
      baseSeq: 1030,
    );

    test('JSON 键与 03 文档 §4.1 一致（snake_case）', () {
      final j = op.toJson();
      expect(
        j.keys,
        containsAll([
          'device_id',
          'lamport',
          'entity',
          'entity_id',
          'field',
          'op',
          'value',
          'base_seq',
        ]),
      );
    });

    test('JSON 往返相等', () {
      final back = SyncOp.fromJson(op.toJson());
      expect(back.deviceId, op.deviceId);
      expect(back.lamport, op.lamport);
      expect(back.entity, op.entity);
      expect(back.entityId, op.entityId);
      expect(back.field, op.field);
      expect(back.type, op.type);
      expect(back.value, op.value);
      expect(back.baseSeq, op.baseSeq);
    });

    test('del 操作不带 value', () {
      final del = SyncOp(
        deviceId: 'dvc_9f2',
        lamport: 1043,
        entity: SyncEntities.task,
        entityId: 'x',
        field: rowCreateField,
        type: SyncOpType.del,
      );
      final back = SyncOp.fromJson(del.toJson());
      expect(back.type, SyncOpType.del);
      expect(back.value, isNull);
    });

    test('set 缺 value 拒绝', () {
      expect(
        () => SyncOp(
          deviceId: 'd',
          lamport: 1,
          entity: 'task',
          entityId: 'x',
          field: 'title',
          type: SyncOpType.set,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('非法 JSON 缺字段抛 FormatException', () {
      expect(
        () => SyncOp.fromJson({'lamport': 1, 'entity': 'task'}),
        throwsFormatException,
      );
      expect(
        () => SyncOp.fromJson({
          'device_id': 'd',
          'lamport': -1,
          'entity': 'task',
          'entity_id': 'x',
          'field': 'f',
          'op': 'set',
          'value': {'t': 'str', 'v': 'a'},
        }),
        throwsFormatException,
      );
      expect(
        () => SyncOp.fromJson({
          'device_id': 'd',
          'lamport': 1,
          'entity': 'task',
          'entity_id': 'x',
          'field': 'f',
          'op': 'upsert',
        }),
        throwsFormatException,
      );
    });
  });
}
