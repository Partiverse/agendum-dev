/// 纯展示格式化助手（无 DOM 依赖，可单测）。
library;

import 'package:agendum_domain/agendum_domain.dart';

const List<String> weekdayZh = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String formatEpochDay(int day) {
  final d = dateFromEpochDay(day);
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd ${weekdayZh[d.weekday - 1]}';
}

String formatHm(int? msSinceEpoch) {
  if (msSinceEpoch == null) return '';
  final d = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
  return '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

/// date input 的 value（YYYY-MM-DD）→ epoch days。
int epochDayFromInputValue(String value) =>
    epochDayOf(DateTime.parse('$value 00:00:00'));
