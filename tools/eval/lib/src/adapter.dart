/// 被测引擎适配器。接入云端模型时实现此接口并走 record/replay
/// （04 文档 §6.2），本地规则适配器用于 CI 零成本回归。
library;

import 'package:agendum_nlp/agendum_nlp.dart';

abstract interface class CaptureAdapter {
  String get name;

  ParsedCapture parse(String input, DateTime now);
}

/// 本地规则引擎适配器（packages/nlp）。
final class LocalRuleAdapter implements CaptureAdapter {
  DateTime _currentNow = DateTime.now();

  @override
  String get name => 'local-rules-v0';

  @override
  ParsedCapture parse(String input, DateTime now) {
    _currentNow = now;
    return CaptureParser(now: () => _currentNow).parse(input);
  }
}
