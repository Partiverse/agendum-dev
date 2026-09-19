/// 重复规则：RFC 5545 RRULE 受控子集（ADR-012）。
///
/// 支持 FREQ=DAILY/WEEKLY/MONTHLY、INTERVAL、BYDAY（周）、BYMONTHDAY（月）、
/// COUNT、UNTIL。覆盖 95% GTD 场景，解析失败抛 FormatException（数据坏即报，
/// 不静默降级）。语义：start 本身是第一次出现；[nextAfter] 返回严格晚于 after
/// 的下一次出现，供"完成即展开下一个"使用。
library;

import 'dates.dart';

enum RecurrenceFreq { daily, weekly, monthly }

const Map<String, int> _weekdayByName = {
  'MO': DateTime.monday,
  'TU': DateTime.tuesday,
  'WE': DateTime.wednesday,
  'TH': DateTime.thursday,
  'FR': DateTime.friday,
  'SA': DateTime.saturday,
  'SU': DateTime.sunday,
};

class RecurrenceRule {
  RecurrenceRule({
    required this.freq,
    this.interval = 1,
    Iterable<int>? byWeekdays,
    Iterable<int>? byMonthDays,
    this.count,
    this.untilDay,
  }) : byWeekdays = _sorted(byWeekdays),
       byMonthDays = _sorted(byMonthDays) {
    if (interval < 1) throw ArgumentError.value(interval, 'interval', '≥1');
    if (count != null && count! < 1) {
      throw ArgumentError.value(count, 'count', '≥1');
    }
    if (freq == RecurrenceFreq.weekly && this.byWeekdays.isEmpty) {
      throw ArgumentError('WEEKLY 需要 BYDAY（缺省按 start 星期展开不可靠）');
    }
    if (freq == RecurrenceFreq.monthly && this.byMonthDays.isEmpty) {
      throw ArgumentError('MONTHLY 需要 BYMONTHDAY');
    }
  }

  final RecurrenceFreq freq;
  final int interval;
  final Set<int> byWeekdays; // DateTime.monday(1)..sunday(7)
  final Set<int> byMonthDays; // 1..31
  final int? count;
  final int? untilDay; // epoch days（含当日）

  /// 解析如 `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;COUNT=10`。
  factory RecurrenceRule.parse(String rrule) {
    final parts = rrule
        .toUpperCase()
        .split(';')
        .map((p) => p.split('='))
        .where((kv) => kv.length == 2 && kv[0].isNotEmpty && kv[1].isNotEmpty)
        .map((kv) => MapEntry(kv[0].trim(), kv[1].trim()));
    RecurrenceFreq? freq;
    var interval = 1;
    final weekdays = <int>{};
    final monthDays = <int>{};
    int? count;
    int? untilDay;
    for (final e in parts) {
      switch (e.key) {
        case 'FREQ':
          freq = switch (e.value) {
            'DAILY' => RecurrenceFreq.daily,
            'WEEKLY' => RecurrenceFreq.weekly,
            'MONTHLY' => RecurrenceFreq.monthly,
            _ => throw FormatException('不支持的 FREQ: ${e.value}（ADR-012 子集）'),
          };
        case 'INTERVAL':
          interval = int.parse(e.value);
        case 'BYDAY':
          for (final w in e.value.split(',')) {
            weekdays.add(
              _weekdayByName[w] ?? (throw FormatException('不支持的 BYDAY: $w')),
            );
          }
        case 'BYMONTHDAY':
          for (final d in e.value.split(',')) {
            final v = int.parse(d);
            if (v < 1 || v > 31) throw FormatException('BYMONTHDAY 越界: $v');
            monthDays.add(v);
          }
        case 'COUNT':
          count = int.parse(e.value);
        case 'UNTIL':
          if (e.value.length != 8) throw FormatException('UNTIL 须为 yyyymmdd');
          final y = int.parse(e.value.substring(0, 4));
          final m = int.parse(e.value.substring(4, 6));
          final d = int.parse(e.value.substring(6, 8));
          untilDay = epochDayOf(DateTime(y, m, d));
        default:
          throw FormatException('不支持的 RRULE 键: ${e.key}（ADR-012 子集）');
      }
    }
    if (freq == null) throw FormatException('RRULE 缺少 FREQ');
    return RecurrenceRule(
      freq: freq,
      interval: interval,
      byWeekdays: weekdays,
      byMonthDays: monthDays,
      count: count,
      untilDay: untilDay,
    );
  }

  static Set<int> _sorted(Iterable<int>? v) {
    if (v == null || v.isEmpty) return const {};
    final list = v.toList()..sort();
    return Set.of(list);
  }

  /// 返回严格晚于 [afterDay]（epoch days）的下一次出现；无（COUNT 耗尽 /
  /// 越过 UNTIL / 5 年安全帽）返回 null。
  int? nextAfter({required int startDay, required int afterDay}) {
    final until = untilDay;
    var scanned = 0;
    var ordinal = 0;
    final safetyCap = startDay + 366 * 5; // 5 年安全帽
    for (var d = startDay; d <= safetyCap; d++) {
      if (until != null && d > until) return null;
      if (_matches(startDay, d)) {
        ordinal++;
        if (count != null && ordinal > count!) return null;
        if (d > afterDay) return d;
      }
      if (++scanned > 4000) {
        throw StateError('RRULE 展开超过安全迭代上限');
      }
    }
    return null;
  }

  bool _matches(int startDay, int day) {
    final date = dateFromEpochDay(day);
    final start = dateFromEpochDay(startDay);
    return switch (freq) {
      RecurrenceFreq.daily => (day - startDay) % interval == 0,
      RecurrenceFreq.weekly =>
        byWeekdays.contains(date.weekday) &&
            (_weekIndex(startDay, day) % interval == 0),
      RecurrenceFreq.monthly =>
        byMonthDays.contains(date.day) &&
            _monthDiff(start, date) % interval == 0,
    };
  }

  /// 以周一为锚的周序差（非负）。
  int _weekIndex(int startDay, int day) {
    final a = _mondayOf(dateFromEpochDay(startDay));
    final b = _mondayOf(dateFromEpochDay(day));
    return (epochDayOf(b) - epochDayOf(a)) ~/ 7;
  }

  static DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  static int _monthDiff(DateTime a, DateTime b) =>
      (b.year - a.year) * 12 + (b.month - a.month);

  @override
  String toString() {
    final b = StringBuffer('FREQ=${freq.name.toUpperCase()}');
    if (interval != 1) b.write(';INTERVAL=$interval');
    if (byWeekdays.isNotEmpty) {
      final names = byWeekdays.map(
        (w) => _weekdayByName.entries.firstWhere((e) => e.value == w).key,
      );
      b.write(';BYDAY=${names.join(',')}');
    }
    if (byMonthDays.isNotEmpty) {
      b.write(';BYMONTHDAY=${byMonthDays.join(',')}');
    }
    if (count != null) b.write(';COUNT=$count');
    if (untilDay != null) {
      final d = dateFromEpochDay(untilDay!);
      b.write(
        ';UNTIL=${d.year.toString().padLeft(4, '0')}'
        '${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}',
      );
    }
    return b.toString();
  }
}
