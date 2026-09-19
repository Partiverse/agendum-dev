/// AI 网关测试（04 文档 §5）：分级强制、额度、BYOK、CORS。
library;

import 'dart:convert';

import 'package:agendum_server/agendum_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  Handler handlerWith({int limit = 30}) =>
      buildHandler(quotaLedger: MemoryQuotaLedger(monthlyLimit: limit));

  Future<Map<String, Object?>> post(
    Handler h,
    String path,
    Object? body, {
    String method = 'POST',
  }) async {
    final res = await h(
      Request(method, Uri.parse('http://s$path'), body: jsonEncode(body)),
    );
    return {
      'status': res.statusCode,
      ...(jsonDecode(await res.readAsString()) as Map).cast<String, Object?>(),
    };
  }

  test('L1 默认档：本地适配器解析并扣减额度', () async {
    final h = handlerWith();
    final r = await post(h, '/v1/ai/parse', {
      'device_id': 'dev-1',
      'input': '明天上午10点开团队会',
    });
    expect(r['status'], 200);
    final result = r['result'] as Map;
    expect(result['title'], '开团队会');
    expect(result['due_day'], isNotNull);
    expect(r['adapter'], 'server-rules-v0');
    expect((r['quota'] as Map)['used'], 1);

    final r2 = await post(h, '/v1/ai/parse', {
      'device_id': 'dev-1',
      'input': '买牛奶',
    });
    expect((r2['quota'] as Map)['used'], 2);
  });

  test('L2 越级拒绝；BYOK 通道放行且不计额', () async {
    final h = handlerWith();
    final forbidden = await post(h, '/v1/ai/parse', {
      'device_id': 'dev-1',
      'input': '带笔记正文的任务',
      'level': 'L2',
    });
    expect(forbidden['status'], 403);

    final byok = await post(h, '/v1/ai/parse', {
      'device_id': 'dev-1',
      'input': '买牛奶',
      'level': 'L2',
      'byok': true,
    });
    expect(byok['status'], 200);
    expect((byok['quota'] as Map)['byok'], true, reason: 'BYOK 不计额');
  });

  test('额度耗尽 → 429；BYOK 绕过', () async {
    final h = handlerWith(limit: 2);
    final body = {'device_id': 'dev-1', 'input': '买牛奶'};
    await post(h, '/v1/ai/parse', body);
    await post(h, '/v1/ai/parse', body);
    final blocked = await post(h, '/v1/ai/parse', body);
    expect(blocked['status'], 429);
    expect(blocked['error'], 'quota_exhausted');
    expect((blocked['quota'] as Map)['remaining'], 0);

    final okByok = await post(h, '/v1/ai/parse', {...body, 'byok': true});
    expect(okByok['status'], 200);
  });

  test('缺字段 → 400；非法 level → 400', () async {
    final h = handlerWith();
    final noInput = await post(h, '/v1/ai/parse', {'device_id': 'd'});
    expect(noInput['status'], 400);
    final badLevel = await post(h, '/v1/ai/parse', {
      'device_id': 'd',
      'input': 'x',
      'level': 'L9',
    });
    expect(badLevel['status'], 400);
  });

  test('CORS：POST 响应携带 allow-origin；OPTIONS 预检直接 200', () async {
    final h = handlerWith();
    final preflight = await h(
      Request('OPTIONS', Uri.parse('http://s/v1/ai/parse')),
    );
    expect(preflight.statusCode, 200);
    expect(preflight.headers['access-control-allow-origin'], isNotNull);
    final res = await h(
      Request(
        'POST',
        Uri.parse('http://s/v1/ai/parse'),
        body: jsonEncode({'device_id': 'd', 'input': '买牛奶'}),
      ),
    );
    expect(res.headers['access-control-allow-origin'], '*');
  });

  test('health 暴露 ai_adapter 与同步存储类型', () async {
    final h = handlerWith();
    final res = await h(Request('GET', Uri.parse('http://s/v1/health')));
    final body = (jsonDecode(await res.readAsString()) as Map)
        .cast<String, Object?>();
    expect(body['ai_adapter'], 'server-rules-v0');
    expect(body['store'], 'MemorySyncStore');
  });
}
