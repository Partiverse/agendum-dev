/// REST 传输实现(03 文档 §4.2:`POST /v1/sync/push`、`GET /v1/sync/pull`)。
///
/// R1 §4/§9:每个请求可经 [authHeaders] 钩子附加设备鉴权头
/// (`X-Agendum-Auth`,挑战-签名在调用方组装 —— 本包不依赖 e2ee,避免
/// 依赖成环)。钩子按请求调用:nonce 一次性,每次 push/pull 都要新挑战。
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
    this.authHeaders,
  }) : _client = client ?? http.Client(),
       _headers = headers ?? const {};

  final String base;
  final http.Client _client;
  final Map<String, String> _headers;

  /// 设备鉴权头钩子(R1 §9):每次请求前调用,返回要附加的头
  /// (通常单键 `X-Agendum-Auth`)。为 null 表示不鉴权(旧服务端兼容)。
  /// 抛出即本次请求失败,由引擎的调用方按传输错误重试。
  final Future<Map<String, String>> Function()? authHeaders;

  @override
  Future<PushResponse> push(PushRequest req) async {
    final resp = await _client.post(
      Uri.parse('$base/v1/sync/push'),
      headers: {
        ..._headers,
        ...?await authHeaders?.call(),
        'content-type': 'application/json',
      },
      body: jsonEncode(req.toJson()),
    );
    return PushResponse.fromJson(_decode(resp, 'push'));
  }

  @override
  Future<PullResponse> pull({
    required int since,
    required int limit,
    required String uid,
  }) async {
    final uri = Uri.parse('$base/v1/sync/pull').replace(
      queryParameters: {'since': '$since', 'limit': '$limit', 'uid': uid},
    );
    final resp = await _client.get(
      uri,
      headers: {..._headers, ...?await authHeaders?.call()},
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
