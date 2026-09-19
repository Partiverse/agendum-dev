/// 客户端本地助手（无 UI 依赖，便于测试）。
library;

import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_nlp/agendum_nlp.dart';

String formatDueDay(int day) {
  final d = dateFromEpochDay(day);
  const wd = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return '${d.month}/${d.day} ${wd[d.weekday - 1]}';
}

/// 供捕获条与页面共用的解析入口（packages/nlp 真实引擎）。
ParsedCapture parseCapture(String input) => CaptureParser().parse(input);
