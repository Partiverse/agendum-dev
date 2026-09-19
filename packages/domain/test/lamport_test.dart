import 'package:agendum_domain/agendum_domain.dart';
import 'package:test/test.dart';

void main() {
  group('LamportClock', () {
    test('tick 单调递增', () {
      final c = LamportClock();
      expect(c.tick(), 1);
      expect(c.tick(), 2);
      expect(c.value, 2);
    });

    test('observe：远端更大则对齐再 +1', () {
      final c = LamportClock(value: 5);
      expect(c.observe(10), 11);
      expect(c.value, 11);
    });

    test('observe：远端更小仍 +1', () {
      final c = LamportClock(value: 10);
      expect(c.observe(3), 11);
    });

    test('时钟回拨不影响单调性（混沌场景 4 的域内保证）', () {
      final c = LamportClock(value: 100);
      final before = c.value;
      c.observe(-5);
      expect(c.value, greaterThan(before));
    });

    test('两设备交互序列收敛到一致的因果关系', () {
      final a = LamportClock();
      final b = LamportClock();
      final a1 = a.tick();
      final b1 = b.observe(a1); // b 收到 a 的写
      expect(b1, greaterThan(a1));
      final a2 = a.observe(b1); // a 收到 b 的写
      expect(a2, greaterThan(b1));
    });
  });
}
