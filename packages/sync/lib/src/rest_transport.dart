/// REST 传输实现(03 文档 §4.2:`POST /v1/sync/push`、`GET /v1/sync/pull`)。
library;

import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:http/http.dart' as http;

import 'sync_engine.dart';

class RestSyncTransport implements SyncTransport {
  RestSyncTransport({
    required this.base,
    http.Client? client,
    Map<String, String>? headers,
  }) : _client = client ?? http.Client(),
       _headers = headers ?? const {};

  final String base;
  final http.Client _client;
  final Map<String, String> _headers;

  @override
  Future<PushResponse> push(PushRequest req) async {
    final resp = await _client.post(
      Uri.parse('$base/v1/sync/push'),
      headers: {..._headers, 'content-type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );
    return PushResponse.fromJson(_decode(resp, 'push'));
  }

  @override
  Future<PullResponse> pull({required int since, required int limit}) async {
    final resp = await _client.get(
      Uri.parse('$base/v1/sync/pull?since=$since&limit=$limit'),
      headers: _headers,
    );
    return PullResponse.fromJson(_decode(resp, 'pull'));
  }

  Map<String, Object?> _decode(http.Response resp, String api) {
    if (resp.statusCode != 200) {
      throw SyncTransportException(
        '$api 失败 HTTP ${resp.statusCode}: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }
    return (jsonDecode(resp.body) as Map).cast<String, Object?>();
  }
}

/// 传输层错误(网络失败/非 200 响应);引擎捕获后等下一轮重试。
class SyncTransportException implements Exception {
  SyncTransportException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'SyncTransportException: $message';
}
