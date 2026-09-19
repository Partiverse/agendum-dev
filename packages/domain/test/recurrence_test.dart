import 'package:agendum_domain/agendum_domain.dart';
import 'package:test/test.dart';

int d(int y, int m, int day) => epochDayOf(DateTime(y, m, day));

void main() {
  group('parse', () {
    test('全字段往返', () {
      final r = RecurrenceRule.parse(
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;COUNT=10',
      );
      expect(r.freq, RecurrenceFreq.weekly);
      expect(r.interval, 2);
      expect(r.byWeekdays, {DateTime.monday, DateTime.wednesday});
      expect(r.count, 10);
      expect(r.toString(), 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;COUNT=10');
    });

    test('UNTIL 解析与序列化', () {
      final r = RecurrenceRule.parse('FREQ=DAILY;UNTIL=20261231');
      expect(r.untilDay, d(2026, 12, 31));
      expect(r.toString(), 'FREQ=DAILY;UNTIL=20261231');
    });

    test('子集之外的 FREQ/键抛 FormatException', () {
      expect(() => RecurrenceRule.parse('FREQ=YEARLY'), throwsFormatException);
      expect(
        () => RecurrenceRule.parse('FREQ=DAILY;BYSETPOS=3'),
        throwsFormatException,
      );
      expect(() => RecurrenceRule.parse('INTERVAL=2'), throwsFormatException);
    });

    test('WEEKLY 缺 BYDAY、MONTHLY 缺 BYMONTHDAY 抛错', () {
      expect(() => RecurrenceRule.parse('FREQ=WEEKLY'), throwsArgumentError);
      expect(() => RecurrenceRule.parse('FREQ=MONTHLY'), throwsArgumentError);
    });
  });

  group('nextAfter（start 本身是第一次出现）', () {
    test('DAILY interval=1', () {
      final r = RecurrenceRule.parse('FREQ=DAILY');
      final start = d(2026, 9, 19);
      expect(r.nextAfter(startDay: start, afterDay: start), d(2026, 9, 20));
      expect(
        r.nextAfter(startDay: start, afterDay: d(2026, 9, 20)),
        d(2026, 9, 21),
      );
    });

    test('DAILY interval=3 跳日', () {
      final r = RecurrenceRule.parse('FREQ=DAILY;INTERVAL=3');
      final start = d(2026, 9, 19);
      expect(r.nextAfter(startDay: start, afterDay: start), d(2026, 9, 22));
      expect(
        r.nextAfter(startDay: start, afterDay: d(2026, 9, 22)),
        d(2026, 9, 25),
      );
    });

    test('WEEKLY BYDAY=MO,WE：周三之后是下周一', () {
      final r = RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,WE');
      final start = d(2026, 9, 14); // 周一
      expect(r.nextAfter(startDay: start, afterDay: start), d(2026, 9, 16));
      expect(
        r.nextAfter(startDay: start, afterDay: d(2026, 9, 16)),
        d(2026, 9, 21),
      );
    });

    test('WEEKLY interval=2：跳过整周', () {
      final r = RecurrenceRule.parse('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE');
      final start = d(2026, 9, 14);
      expect(
        r.nextAfter(startDay: start, afterDay: d(2026, 9, 16)),
        d(2026, 9, 28),
      );
      expect(
        r.nextAfter(startDay: start, afterDay: d(2026, 9, 28)),
        d(2026, 9, 30),
      );
    });

    test('MONTHLY BYMONTHDAY=15', () {
      final r = RecurrenceRule.parse('FREQ=MONTHLY;BYMONTHDAY=15');
      final start = d(2026, 1, 15);
      expect(r.nextAfter(startDay: start, afterDay: start), d(2026, 2, 15));
    });

    test('MONTHLY interval=2 隔月', () {
      final r = RecurrenceRule.parse('FREQ=MONTHLY;INTERVAL=2;BYMONTHDAY=15');
      final start = d(2026, 1, 15);
      expect(
        r.nextAfter(startDay: start, afterDay: d(2026, 2, 20)),
        d(2026, 3, 15),
        reason: '2 月不在隔月序列内',
      );
    });

    test('COUNT 耗尽返回 null', () {
      final r = RecurrenceRule.parse('FREQ=DAILY;COUNT=3');
      final start = d(2026, 9, 19); // 出现：19、20、21
      expect(r.nextAfter(startDay: start, afterDay: d(2026, 9, 21)), isNull);
      expect(
        r.nextAfter(startDay: start, afterDay: d(2026, 9, 20)),
        d(2026, 9, 21),
      );
    });

    test('UNTIL 边界含当日', () {
      final r = RecurrenceRule.parse('FREQ=DAILY;UNTIL=20260920');
      final start = d(2026, 9, 19);
      expect(r.nextAfter(startDay: start, afterDay: start), d(2026, 9, 20));
      expect(r.nextAfter(startDay: start, afterDay: d(2026, 9, 20)), isNull);
    });

    test('重复任务"完成即展开"的典型路径', () {
      final r = RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO');
      final start = d(2026, 9, 14);
      final next = r.nextAfter(startDay: start, afterDay: d(2026, 9, 14));
      expect(next, d(2026, 9, 21));
    });
  });
}
