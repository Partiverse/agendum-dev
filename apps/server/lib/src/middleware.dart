/// 共享 shelf 中间件。
library;

import 'package:shelf/shelf.dart';

/// 开发期 CORS（演示页 8181 → 服务 8090 跨域）；生产由反向代理统一处理。
Middleware corsMiddleware() {
  const headers = {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers': 'content-type, authorization',
  };
  return (inner) => (req) async {
    if (req.method == 'OPTIONS') {
      return Response.ok('', headers: headers);
    }
    final res = await inner(req);
    return res.change(headers: headers);
  };
}
