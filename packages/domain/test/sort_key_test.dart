import 'package:agendum_domain/agendum_domain.dart';
import 'package:test/test.dart';

void main() {
  group('midpointSortKey', () {
    test('两端无界返回初始键', () {
      expect(midpointSortKey(null, null), firstSortKey());
    });

    test('结果严格介于两端（字典序）', () {
      expect(
        midpointSortKey('a1', 'a3').compareTo('a1'),
        greaterThan(0),
        reason: '> before',
      );
      expect(
        midpointSortKey('a1', 'a3').compareTo('a3'),
        lessThan(0),
        reason: '< after',
      );
    });

    test('有界端与无界端混合', () {
      final head = midpointSortKey(null, 'V'); // 列表头插入
      expect(head.compareTo('V'), lessThan(0));
      final tail = midpointSortKey('V', null); // 列表尾追加
      expect(tail.compareTo('V'), greaterThan(0));
      expect(midpointSortKey('a1', 'a1a').compareTo('a1'), greaterThan(0));
    });

    test('相邻前缀键可继续细分（重复头插不碰撞）', () {
      final first = midpointSortKey(null, '0abc');
      final second = midpointSortKey(first, '0abc');
      expect(first.compareTo(second), isNot(0));
      expect(second.compareTo('0abc'), lessThan(0));
      expect(first.compareTo(second), lessThan(0));
    });

    test('逐段深入：相等前缀下探到更深位', () {
      final k = midpointSortKey('a1', 'a2');
      expect(k.startsWith('a1'), isTrue);
      expect(k.compareTo('a1'), greaterThan(0));
      expect(k.compareTo('a2'), lessThan(0));
    });

    test('顺序链式插入 100 次保持全序（属性冒烟）', () {
      var last = firstSortKey();
      final keys = [last];
      for (var i = 0; i < 100; i++) {
        last = midpointSortKey(last, null);
        keys.add(last);
      }
      for (var i = 1; i < keys.length; i++) {
        expect(
          keys[i - 1].compareTo(keys[i]),
          lessThan(0),
          reason: 'keys[$i-1]=${keys[i - 1]} < keys[$i]=${keys[i]}',
        );
      }
    });

    test('before ≥ after 抛错', () {
      expect(() => midpointSortKey('b', 'a'), throwsArgumentError);
      expect(() => midpointSortKey('a', 'a'), throwsArgumentError);
    });

    test('非 base62 字符抛错', () {
      // 'a+' 与 'ab'：首字符相同，第二位的 '+' 必被触达。
      expect(() => midpointSortKey('a+', 'ab'), throwsArgumentError);
      expect(() => midpointSortKey('a', 'a?'), throwsArgumentError);
    });
  });

  group('append/prepend', () {
    test('append 在 last 之后；prepend 在 first 之前', () {
      final first = firstSortKey();
      final second = appendSortKey(first);
      expect(second.compareTo(first), greaterThan(0));
      final zeroth = prependSortKey(first);
      expect(zeroth.compareTo(first), lessThan(0));
    });
  });
}
