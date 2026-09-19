/// 云端网关调用（浏览器 fetch → 服务端 /v1/ai/parse）。
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<Map<String, Object?>> callCloudParse(
  String input, {
  String base = 'http://localhost:8090',
  String deviceId = 'demo-web',
}) async {
  final resp = await web.window
      .fetch(
        '$base/v1/ai/parse'.toJS,
        web.RequestInit(
          method: 'POST',
          headers:
              {'content-type': 'application/json'}.jsify() as web.HeadersInit,
          body: jsonEncode({
            'device_id': deviceId,
            'input': input,
            'level': 'L1',
            'prompt_version': 'v1.0',
          }).toJS,
        ),
      )
      .toDart;
  final json = await resp.json().toDart;
  return (json.dartify() as Map).cast<String, Object?>();
}
