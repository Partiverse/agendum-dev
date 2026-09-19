/// 路由与处理器。
///
/// 同步契约（03 文档 §4.2）已在 PoC 中实现：push 分配全局序号并维护
/// 字段裁决表，pull 按 cursor 增量续传。AI 网关（04 文档 §5.2）提供
/// `/v1/ai/parse` 云端回落端点：分级强制 + 额度账本 + 可插拔适配器。
/// 存储经 [SyncStore] 抽象——默认内存实现，设 DATABASE_URL 时用
/// Postgres（bin/server.dart 装配）。E2EE 于 S08 落地。错误响应统一 JSON。
library;

import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ai/adapter.dart';
import 'ai/quota.dart';
import 'ai/routes.dart';
import 'middleware.dart';
import 'store/memory_store.dart';
import 'store/sync_store.dart';

Response _json(Object? body, {int status = 200}) => Response(
  status,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Handler buildHandler({
  SyncStore? store,
  CaptureModelAdapter? aiAdapter,
  QuotaLedger? quotaLedger,
  int aiMonthlyLimit = 30,
  String version = '0.0.1',
}) {
  final sync = store ?? MemorySyncStore();
  final adapter = aiAdapter ?? ServerRulesAdapter();
  final ai = aiRoutes(
    adapter: adapter,
    quota: quotaLedger ?? MemoryQuotaLedger(monthlyLimit: aiMonthlyLimit),
  );

  final router = Router()
    ..get(
      '/v1/health',
      (Request req) => _json({
        'ok': true,
        'service': 'agendum-server',
        'version': version,
        'protocol': protocolVersion,
        'store': sync.runtimeType.toString(),
        'ai_adapter': adapter.name,
      }),
    )
    ..post('/v1/sync/push', (Request req) async {
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
      final PushRequest pushReq;
      try {
        pushReq = PushRequest.fromJson(body);
      } on FormatException catch (e) {
        return _json({
          'error': 'bad_request',
          'message': e.message,
        }, status: 400);
      }
      final resp = await sync.push(pushReq);
      return _json(resp.toJson());
    })
    ..get('/v1/sync/pull', (Request req) async {
      final since = int.tryParse(req.url.queryParameters['since'] ?? '');
      if (since == null || since < 0) {
        return _json({
          'error': 'bad_request',
          'message': 'since 必填且 ≥0',
        }, status: 400);
      }
      final limit =
          int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 2000;
      final resp = await sync.pull(since: since, limit: limit);
      return _json(resp.toJson());
    })
    // catch-all 路由须最后注册，AI 网关内部自带 404 兜底。
    ..mount('/', ai.call);

  return Pipeline().addMiddleware(corsMiddleware()).addHandler(router.call);
}
