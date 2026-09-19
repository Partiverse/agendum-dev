/// 日期工具：任务日期按"用户本地日"存储为 epoch days，时刻为 epoch ms
/// （02 文档 §4.2 时区规则）。
///
/// epoch day 的定义：**本地日历日午夜毫秒 + 该日时区偏移**，再除以一天毫秒数。
/// 即以"时区校正后的 UTC 午夜"计数，保证 [epochDayOf] 与 [dateFromEpochDay]
/// 在任意时区互逆；跨 DST 边界由两步猜测补偿（常规夏令时场景）。
library;

const int msPerDay = 86400000;

int epochDayOf(DateTime d) {
  final local = DateTime(d.year, d.month, d.day);
  return (local.millisecondsSinceEpoch + local.timeZoneOffset.inMilliseconds) ~/
      msPerDay;
}

DateTime dateFromEpochDay(int day) {
  // 目标日的偏移未知，先用当前偏移猜一次，再用猜出日期的偏移修正一次。
  final guess = DateTime.fromMillisecondsSinceEpoch(
    day * msPerDay - DateTime.now().timeZoneOffset.inMilliseconds,
  );
  return DateTime.fromMillisecondsSinceEpoch(
    day * msPerDay - guess.timeZoneOffset.inMilliseconds,
  );
}

bool isOverdue({
  required int? dueDay,
  required int todayDay,
  required bool isTerminal,
}) => dueDay != null && !isTerminal && dueDay < todayDay;
