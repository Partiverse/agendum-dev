import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:test/test.dart';

FieldEntry setEntry(int lamport, String origin, String v) => FieldEntry(
  version: FieldVersion(lamport: lamport, origin: origin),
  type: SyncOpType.set,
  value: OpValue(OpValueTypes.str, v),
);

FieldEntry delEntry(int lamport, String origin) => FieldEntry(
  version: FieldVersion(lamport: lamport, origin: origin),
  type: SyncOpType.del,
);

SyncOp op({
  required int lamport,
  required String origin,
  required String field,
  SyncOpType type = SyncOpType.set,
  String? value,
}) => SyncOp(
  deviceId: origin,
  lamport: lamport,
  entity: 'task',
  entityId: 't1',
  field: field,
  type: type,
  value: type == SyncOpType.set ? OpValue(OpValueTypes.str, value ?? '') : null,
);

void main() {
  group('resolveEntry —— 对应 02 文档 §7.2 混沌场景（域内单测版）', () {
    test('场景1：同字段并发写，lamport 高者胜', () {
      final a = setEntry(10, 'dvc_a', '来自 A');
      final b = setEntry(12, 'dvc_b', '来自 B');
      expect(resolveEntry(a, b), b);
      expect(resolveEntry(b, a), b, reason: '交换律：顺序无关');
    });

    test('场景2：等 lamport 不同设备，origin 字典序大者胜（确定性）', () {
      final a = setEntry(10, 'dvc_a', 'A');
      final b = setEntry(10, 'dvc_b', 'B');
      expect(resolveEntry(a, b), b);
      expect(resolveEntry(b, a), b);
    });

    test('场景3：并发改/删等时钟 → 删除胜', () {
      final s = setEntry(10, 'dvc_a', '还在吗');
      final del = delEntry(10, 'dvc_b');
      expect(resolveEntry(s, del), del);
      expect(resolveEntry(del, s), del);
    });

    test('场景3b：更晚的 set 复活已删除实体（合法恢复路径）', () {
      final del = delEntry(10, 'dvc_a');
      final revive = setEntry(11, 'dvc_b', '恢复');
      expect(resolveEntry(del, revive), revive);
      expect(resolveEntry(revive, del), revive);
    });

    test('场景3c：更晚的 del 覆盖 set', () {
      final s = setEntry(10, 'dvc_a', 'x');
      final del = delEntry(11, 'dvc_b');
      expect(resolveEntry(s, del), del);
    });

    test('场景4：墙钟无关——lamport 相同时不比较任何时间戳', () {
      // 人为构造"时钟回拨"：后写的 lamport 更小，则仍按 lamport 判旧。
      final earlier = setEntry(20, 'dvc_a', '先写');
      final laterButStale = setEntry(5, 'dvc_b', '后写但时钟旧');
      expect(resolveEntry(earlier, laterButStale), earlier);
    });

    test('幂等：同一条写重放不变', () {
      final s = setEntry(10, 'dvc_a', 'x');
      expect(resolveEntry(s, s), s);
    });
  });

  group('EntitySyncState', () {
    test('场景1b：不同字段并发写互不覆盖', () {
      final s1 = EntitySyncState();
      s1.apply(op(lamport: 1, origin: 'dvc_a', field: 'title', value: '标题A'));
      s1.apply(
        op(lamport: 1, origin: 'dvc_b', field: 'due_date', value: '20650'),
      );

      final s2 = EntitySyncState();
      s2.apply(
        op(lamport: 1, origin: 'dvc_b', field: 'due_date', value: '20650'),
      );
      s2.apply(op(lamport: 1, origin: 'dvc_a', field: 'title', value: '标题A'));

      s1.mergeInto(s2);
      expect(s1.field('title')!.value!.value, '标题A');
      expect(s1.field('due_date')!.value!.value, '20650');
    });

    test('同一实体两副本按不同顺序重放收敛一致', () {
      final ops = [
        op(lamport: 1, origin: 'dvc_a', field: rowCreateField, value: 'row'),
        op(lamport: 2, origin: 'dvc_a', field: 'title', value: '第一版'),
        op(lamport: 3, origin: 'dvc_b', field: 'title', value: '第二版'),
        op(lamport: 2, origin: 'dvc_b', field: 'note', value: '备注'),
      ];
      final s1 = EntitySyncState();
      for (final o in ops) {
        s1.apply(o);
      }
      final s2 = EntitySyncState();
      for (final o in ops.reversed) {
        s2.apply(o);
      }
      expect(s1.field('title')!.version.origin, 'dvc_b');
      expect(s2.field('title')!.version.origin, 'dvc_b');
      expect(s1.field('note')!.value!.value, '备注');
      expect(s1.field('note'), s2.field('note'));
    });

    test('整行墓碑使实体标记删除', () {
      final s = EntitySyncState();
      s.apply(
        op(lamport: 1, origin: 'dvc_a', field: rowCreateField, value: 'row'),
      );
      expect(s.isDeleted, isFalse);
      s.apply(
        op(
          lamport: 2,
          origin: 'dvc_a',
          field: rowCreateField,
          type: SyncOpType.del,
        ),
      );
      expect(s.isDeleted, isTrue);
    });

    test('重放已应用的同一条 op 不产生回退', () {
      final s = EntitySyncState();
      s.apply(op(lamport: 5, origin: 'dvc_a', field: 'title', value: '新'));
      s.apply(op(lamport: 3, origin: 'dvc_b', field: 'title', value: '旧'));
      expect(s.field('title')!.value!.value, '新');
    });
  });
}
