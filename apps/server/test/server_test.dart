import 'dart:convert';

import 'package:agendum_server/agendum_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  final handler = buildHandler();

  Future<Map<String, Object?>> get(String path) async {
    final res = await handler(Request('GET', Uri.parse('http://s$path')));
    return jsonDecode(await res.readAsString()) as Map<String, Object?>;
  }

  Future<Map<String, Object?>> post(String path) async {
    final res = await handler(
      Request('POST', Uri.parse('http://s$path'), body: '{}'),
    );
    return jsonDecode(await res.readAsString()) as Map<String, Object?>;
  }

  test('GET /v1/health 返回服务与协议版本', () async {
    final body = await get('/v1/health');
    expect(body['ok'], true);
    expect(body['service'], 'agendum-server');
    expect(body['protocol'], 'v1');
  });

  test('POST /v1/sync/push 契约占位返回 501', () async {
    final body = await post('/v1/sync/push');
    expect(body['error'], 'not_implemented');
  });

  test('GET /v1/sync/pull 契约占位返回 501', () async {
    final body = await get('/v1/sync/pull');
    expect(body['error'], 'not_implemented');
  });

  test('未知路由 404', () async {
    final res = await handler(Request('GET', Uri.parse('http://s/nope')));
    expect(res.statusCode, 404);
  });
}
