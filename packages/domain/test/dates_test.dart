import 'package:agendum_domain/agendum_domain.dart';
import 'package:test/test.dart';

void main() {
  group('epochDayOf / dateFromEpochDay', () {
    test('往返一致', () {
      final now = DateTime.now();
      final day = epochDayOf(now);
      final back = dateFromEpochDay(day);
      expect(back.year, now.year);
      expect(back.month, now.month);
      expect(back.day, now.day);
    });

    test('同一天内任意时刻映射到同一 epoch day', () {
      final d = epochDayOf(DateTime(2026, 9, 19, 0, 0));
      expect(epochDayOf(DateTime(2026, 9, 19, 23, 59)), d);
    });
  });

  group('isOverdue', () {
    test('截止日早于今天且未终态 = 逾期', () {
      expect(isOverdue(dueDay: 100, todayDay: 101, isTerminal: false), isTrue);
      expect(
        isOverdue(dueDay: 101, todayDay: 101, isTerminal: false),
        isFalse,
        reason: '当日不算逾期',
      );
      expect(
        isOverdue(dueDay: 100, todayDay: 101, isTerminal: true),
        isFalse,
        reason: '终态任务不再报逾期',
      );
      expect(
        isOverdue(dueDay: null, todayDay: 101, isTerminal: false),
        isFalse,
      );
    });
  });
}
