/// 共享 shelf 中间件。
library;

import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:shelf/shelf.dart';

import 'auth.dart';
import 'store/devices.dart';

/// 开发期 CORS（演示页 8181 → 服务 8090 跨域）；生产由反向代理统一处理。
Middleware corsMiddleware() {
  const headers = {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers':
        'content-type, authorization, $authHeaderName',
  };
  return (inner) => (req) async {
    if (req.method == 'OPTIONS') {
      return Response.ok('', headers: headers);
    }
    final res = await inner(req);
    return res.change(headers: headers);
  };
}

/// 401 响应（R1 §4：无签名/验签失败/nonce 重放/uid 不符一律 401）。
Response unauthorized(String message) => Response(
  401,
  body: jsonEncode({'error': 'unauthorized', 'message': message}),
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// 设备鉴权守卫（R1 §4）：包装 push/pull/envelope 路由。
///
/// 校验顺序（语义见 ADR-016）：
/// 1. 解析 `X-Agendum-Auth: v1 <device_id> <nonce_b64> <sig_b64>`；
/// 2. 查设备注册记录（未注册 → 401）；
/// 3. 用注册公钥验签 `agendum/auth:<device_id>:<nonce_b64>`（失败 → 401）；
/// 4. **验签通过立即消费 nonce**（单次有效；重放/过期 → 401）——先于 uid
///    比对消费，防「拿截获头改 uid 试探后原头仍可用」的重放窗口；
/// 5. 通过后把 [AuthedDevice] 写入 `Request.context`，租户一致性
///    （请求 uid == 注册 uid）由各路由在解析自身参数后校验。
Middleware deviceAuthMiddleware({
  required DeviceDirectory devices,
  required NonceStore nonces,
}) =>
    (inner) => (req) async {
      final header = req.headers[authHeaderName];
      if (header == null) {
        return unauthorized('缺少 $authHeaderName 鉴权头');
      }
      final AuthCredentials creds;
      try {
        creds = parseAuthHeader(header);
      } on FormatException catch (e) {
        return unauthorized(e.message);
      }
      final record = await devices.byId(creds.deviceId);
      if (record == null) {
        return unauthorized('设备未注册: ${creds.deviceId}');
      }
      final sigOk = await verifyEd25519(
        message: utf8.encode(
          authSignatureMessage(creds.deviceId, creds.nonceB64),
        ),
        publicKeyB64: record.publicKeyB64,
        sigB64: creds.sigB64,
      );
      if (!sigOk) {
        return unauthorized('鉴权签名验证失败');
      }
      if (!await nonces.consume(creds.nonceB64)) {
        return unauthorized('nonce 无效（已用过或已过期）');
      }
      return inner(
        req.change(
          context: {
            ...req.context,
            authedDeviceContextKey: AuthedDevice(
              deviceId: record.deviceId,
              uid: record.uid,
            ),
          },
        ),
      );
    };
