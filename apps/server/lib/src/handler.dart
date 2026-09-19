/// 路由与处理器。
///
/// W1 只冻结契约形状（03 文档 §4.2）；业务实现于 S05（同步打通）与
/// S08（E2EE）。所有错误响应统一 JSON。
library;

import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Response _json(Object? body, {int status = 200}) => Response(
  status,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Handler buildHandler({String version = '0.0.1'}) {
  final router = Router()
    ..get(
      '/v1/health',
      (Request req) => _json({
        'ok': true,
        'service': 'agendum-server',
        'version': version,
        'protocol': protocolVersion,
      }),
    )
    ..post(
      '/v1/sync/push',
      (Request req) => _json({
        'error': 'not_implemented',
        'hint': 'S05 落地；契约见 docs/03-数据模型与同步协议.md §4',
      }, status: 501),
    )
    ..get(
      '/v1/sync/pull',
      (Request req) => _json({
        'error': 'not_implemented',
        'hint': 'S05 落地；契约见 docs/03-数据模型与同步协议.md §4',
      }, status: 501),
    );

  return router.call;
}
