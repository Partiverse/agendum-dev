import 'package:agendum_domain/agendum_domain.dart';
import 'package:test/test.dart';

void main() {
  const venue = TagDescriptor(
    id: 't1',
    name: '现场',
    groupId: 'g1',
    groupName: '场合',
    groupExclusive: true,
  );
  const remote = TagDescriptor(
    id: 't2',
    name: '远程',
    groupId: 'g1',
    groupName: '场合',
    groupExclusive: true,
  );
  const deep = TagDescriptor(
    id: 't3',
    name: '深度工作',
    groupId: 'g2',
    groupName: '模式',
    groupExclusive: true,
  );
  const free = TagDescriptor(id: 't4', name: '快事');

  group('checkExclusiveAssign', () {
    test('同互斥组第二个标签拒绝', () {
      expect(
        () => checkExclusiveAssign([venue], remote),
        throwsA(isA<ExclusiveTagGroupError>()),
      );
    });

    test('同组重复添加不在此拦截（仓库层幂等）', () {
      checkExclusiveAssign([venue], venue);
    });

    test('不同互斥组互不影响', () {
      checkExclusiveAssign([venue], deep);
      checkExclusiveAssign([deep], remote);
    });

    test('自由标签不受限', () {
      checkExclusiveAssign([venue], free);
      checkExclusiveAssign([free], free);
    });

    test('空集可加任意标签', () {
      checkExclusiveAssign(const [], remote);
    });

    test('错误信息含组名与双方标签', () {
      try {
        checkExclusiveAssign([venue], remote);
        fail('应抛出');
      } on ExclusiveTagGroupError catch (e) {
        expect(e.toString(), contains('场合'));
        expect(e.toString(), contains('现场'));
        expect(e.toString(), contains('远程'));
      }
    });
  });

  group('withoutTag', () {
    test('移除指定标签，其余保留', () {
      expect(withoutTag([venue, free], venue.id).map((t) => t.id), ['t4']);
    });

    test('移除不存在的标签无变化', () {
      expect(withoutTag([venue], 'nope').length, 1);
    });
  });
}
