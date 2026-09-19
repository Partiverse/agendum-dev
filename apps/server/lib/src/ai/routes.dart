/// AI 网关路由（04 文档 §5.2）。
///
/// `POST /v1/ai/parse`：捕获解析的云端回落端点。
/// 强制数据分级（L2/L3 须 BYOK）→ 额度检查（BYOK 不计额）→ 适配器解析。
/// 提示词版本随请求回显，保证评估与线上行为可对应（04 文档 §7）。
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'adapter.dart';
import 'quota.dart';

Response _json(Object? body, {int status = 200}) => Response(
  status,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Router aiRoutes({
  required CaptureModelAdapter adapter,
  required QuotaLedger quota,
  String defaultPromptVersion = 'v1.0',
}) {
  return Router()..post('/v1/ai/parse', (Request req) async {
    final Map<String, Object?> body;
    try {
      body = (jsonDecode(await req.readAsString()) as Map)
          .cast<String, Object?>();
    } on FormatException {
      return _json({
        'error': 'bad_request',
        'message': 'body 不是合法 JSON',
      }, status: 400);
    }

    final deviceId = body['device_id'];
    final input = body['input'];
    if (deviceId is! String || deviceId.isEmpty || input is! String) {
      return _json({
        'error': 'bad_request',
        'message': 'device_id 与 input 必填',
      }, status: 400);
    }

    final DataLevel level;
    try {
      level = DataLevel.fromValue((body['level'] ?? 'L1') as String);
    } on ArgumentError catch (e) {
      return _json({'error': 'bad_request', 'message': e.message}, status: 400);
    }
    final byok = body['byok'] == true;

    // 分级强制（04 文档 §1：L2/L3 需 BYOK 或本地模型；越级直接拒绝）。
    if (level != DataLevel.l1 && !byok) {
      return _json({
        'error': 'forbidden',
        'message': 'L2/L3 数据须 BYOK 或本地模型通道',
      }, status: 403);
    }

    // 额度（04 文档 §8：BYOK 不计额）。
    QuotaState? qs;
    if (!byok) {
      if (quota.usage(deviceId).exhausted) {
        return _json({
          'error': 'quota_exhausted',
          'message': '本月云端 AI 额度已用完（升级 Pro 或配置 BYOK）',
          'quota': quota.usage(deviceId).toJson(),
        }, status: 429);
      }
      qs = quota.consume(deviceId);
    }

    final promptVersion =
        (body['prompt_version'] ?? defaultPromptVersion) as String;
    final result = adapter.parse(input);
    return _json({
      'result': result.toJson(),
      'adapter': adapter.name,
      'prompt_version': promptVersion,
      'level': level.value,
      'quota': qs?.toJson() ?? {'byok': true},
    });
  });
}
