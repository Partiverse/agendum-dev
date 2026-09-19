/// 云端解析适配器接口（04 文档 §4 优先级链的第三层回落）。
///
/// 当前内置服务端规则适配器（同一 packages/nlp 代码，用于联调与演示）；
/// 云端模型适配器实现本接口后，经 record/replay（tools/eval）接入评估体系。
library;

import 'package:agendum_nlp/agendum_nlp.dart';

abstract interface class CaptureModelAdapter {
  String get name;

  ParsedCapture parse(String input);
}

/// 服务端规则适配器：与端上同一规则引擎（联调/演示/回落兜底）。
final class ServerRulesAdapter implements CaptureModelAdapter {
  @override
  String get name => 'server-rules-v0';

  @override
  ParsedCapture parse(String input) => CaptureParser().parse(input);
}
