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

  group('rebalancedSortKeys', () {
    test('空列表与非法入参', () {
      expect(rebalancedSortKeys(0), isEmpty);
      expect(() => rebalancedSortKeys(-1), throwsArgumentError);
    });

    test('单键居中且可向两端扩展', () {
      final keys = rebalancedSortKeys(1);
      expect(keys, hasLength(1));
      expect(prependSortKey(keys.first).compareTo(keys.first), lessThan(0));
      expect(appendSortKey(keys.first).compareTo(keys.first), greaterThan(0));
    });

    test('全序且等距（字典序 = 序）', () {
      for (final n in [2, 5, 61, 62, 100, 3843]) {
        final keys = rebalancedSortKeys(n);
        expect(keys, hasLength(n), reason: 'n=$n');
        for (var i = 1; i < n; i++) {
          expect(
            keys[i - 1].compareTo(keys[i]),
            lessThan(0),
            reason: 'n=$n keys[$i-1] < keys[$i]',
          );
        }
      }
    });

    test('键长不超过 maxSortKeyLength', () {
      for (final k in rebalancedSortKeys(1000)) {
        expect(k.length, lessThanOrEqualTo(maxSortKeyLength));
      }
    });

    test('宽度跨越 62 的幂时仍留间隙（首键 > 空、末键 < 满）', () {
      final keys = rebalancedSortKeys(62);
      expect(keys.first.compareTo(''), greaterThan(0));
      // 定宽 2 位：末键必须小于最大两位串 'zz'，否则后续 prepend 无空间。
      expect(keys.last.compareTo('zz'), lessThan(0));
    });

    test('可作为 midpointSortKey 的界继续插入', () {
      final keys = rebalancedSortKeys(10);
      final head = midpointSortKey(null, keys.first);
      expect(head.compareTo(keys.first), lessThan(0));
      final tail = midpointSortKey(keys.last, null);
      expect(tail.compareTo(keys.last), greaterThan(0));
      final mid = midpointSortKey(keys[3], keys[4]);
      expect(mid.compareTo(keys[3]), greaterThan(0));
      expect(mid.compareTo(keys[4]), lessThan(0));
    });
  });
}
