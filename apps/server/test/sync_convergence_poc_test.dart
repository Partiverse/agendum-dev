/// 同步引擎 PoC 核心验收（05 文档 W5–6 / 06 文档 S06）：
/// 两个模拟客户端经真实 HTTP handler（内存存储）并发写入，
/// 验证最终收敛符合 03 文档 §5 冲突细则。
library;

import 'dart:convert';

import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_server/agendum_server.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// 模拟客户端：本地写 → push；pull 增量 → resolveEntry 重放。
final class _Client {
  _Client(this.id, this._handler);

  final String id;
  final Handler _handler;
  final state = EntitySyncState();
  final seen = <String>{};
  final clock = LamportClock();
  var cursor = 0;

  static String _key(SyncOp op) => '${op.deviceId}#${op.lamport}#${op.field}';

  Future<PushResponse> write(String field, String? value) async {
    final op = SyncOp(
      deviceId: id,
      lamport: clock.tick(),
      entity: 'task',
      entityId: 'demo-1',
      field: field,
      type: value == null ? SyncOpType.del : SyncOpType.set,
      value: value == null ? null : OpValue(OpValueTypes.str, value),
    );
    seen.add(_key(op));
    state.apply(op);
    final res = await _handler(
      Request(
        'POST',
        Uri.parse('http://s/v1/sync/push'),
        body: jsonEncode(PushRequest(deviceId: id, ops: [op]).toJson()),
      ),
    );
    return PushResponse.fromJson(
      (jsonDecode(await res.readAsString()) as Map).cast<String, Object?>(),
    );
  }

  Future<int> pullOnce({int limit = 500}) async {
    final res = await _handler(
      Request(
        'GET',
        Uri.parse('http://s/v1/sync/pull?since=$cursor&limit=$limit'),
      ),
    );
    final pr = PullResponse.fromJson(
      (jsonDecode(await res.readAsString()) as Map).cast<String, Object?>(),
    );
    for (final op in pr.ops) {
      if (seen.add(_key(op))) {
        clock.observe(op.lamport);
        state.apply(op);
      }
    }
    cursor = pr.cursor;
    return pr.ops.length;
  }

  Future<void> pullUntilQuiet({int limit = 500}) async {
    while (await pullOnce(limit: limit) > 0) {}
  }
}

void main() {
  Handler newServer() => buildHandler();

  test('PoC 场景 1：并发同字段不同 lamport → 双端收敛到高者', () async {
    final h = newServer();
    final a = _Client('设备A', h);
    final b = _Client('设备B', h);

    // 三次写互不感知（并发）：A 连写两版（lamport 1→2），B 写一版（lamport 1）。
    await a.write('title', '第一版');
    await a.write('title', '第二版');
    await b.write('title', 'B的版本');

    await a.pullUntilQuiet();
    await b.pullUntilQuiet();

    final ta = a.state.field('title')!;
    final tb = b.state.field('title')!;
    expect(ta.value!.value, '第二版');
    expect(tb.value!.value, '第二版');
    expect(ta.version.origin, '设备A');
    expect(tb, ta, reason: '两副本字段状态完全一致（确定性收敛）');
  });

  test('PoC 场景 2：等时钟并发写 → origin 字典序破平，双端一致', () async {
    final h = newServer();
    final a = _Client('设备A', h);
    final b = _Client('设备B', h);

    await a.write('title', '来自A');
    await b.write('title', '来自B');
    await a.pullUntilQuiet();
    await b.pullUntilQuiet();

    expect(a.state.field('title')!.version.origin, '设备B');
    expect(b.state.field('title')!.version.origin, '设备B');
    expect(a.state.field('title')!.value!.value, '来自B');
    expect(b.state.field('title')!.value!.value, '来自B');
  });

  test('PoC 场景 3：并发改/删（等时钟）→ 双端收敛为墓碑', () async {
    final h = newServer();
    final a = _Client('设备A', h);
    final b = _Client('设备B', h);

    await a.write('title', null); // A 删除
    await b.write('title', 'B 还在改'); // B 并发修改

    await a.pullUntilQuiet();
    await b.pullUntilQuiet();

    expect(a.state.field('title')!.isTombstone, isTrue);
    expect(b.state.field('title')!.isTombstone, isTrue);
    expect(a.state.field('title'), b.state.field('title'));
  });

  test('PoC 场景 4：更晚的 set 复活已删除实体（合法恢复）', () async {
    final h = newServer();
    final a = _Client('设备A', h);
    final b = _Client('设备B', h);

    await a.write('title', null); // A 删除（lamport 1）
    // B 先看到删除再写入：时钟观察到 1 → 本地写 lamport=2 → 更高胜出。
    await b.pullUntilQuiet();
    await b.write('title', '恢复');

    await a.pullUntilQuiet();
    await b.pullUntilQuiet();

    expect(a.state.field('title')!.value!.value, '恢复');
    expect(b.state.field('title')!.value!.value, '恢复');
  });

  test('PoC 场景 5：离线累积 + 小分页 pull → 不丢不重', () async {
    final h = newServer();
    final a = _Client('设备A', h);
    final b = _Client('设备B', h);

    // A 离线写 5 个字段；B 全程离线。
    for (var i = 1; i <= 5; i++) {
      await a.write('f$i', '值$i');
    }
    // B 以 limit=2 分页追平。
    await b.pullUntilQuiet(limit: 2);

    for (var i = 1; i <= 5; i++) {
      expect(b.state.field('f$i')!.value!.value, '值$i');
    }
    // 再拉一次确认游标推进后无重复回放。
    final extra = await b.pullOnce(limit: 2);
    expect(extra, 0);
  });

  test('PoC 场景 6：服务端裁决 ack —— stale op 返回 accepted=false', () async {
    final h = newServer();
    final a = _Client('设备A', h);
    final b = _Client('设备B', h);

    await a.write('title', '新值'); // A: lamport 1
    await a.pullUntilQuiet();
    // B 看到了 A 的 lamport=1，自己钟表推进后写入 → 胜出。
    final okResp = await b.write('title', 'B 的新值');
    expect(okResp.results.single.accepted, isTrue);

    // B 再写一次把裁决头抬到更高 lamport，随后 stale op 必被拒。
    await b.write('title', 'B 再写一次');

    // 手工构造 stale op（lamport 落后）→ 服务端 ack 拒绝。
    final stale = SyncOp(
      deviceId: '设备C',
      lamport: 1,
      entity: 'task',
      entityId: 'demo-1',
      field: 'title',
      type: SyncOpType.set,
      value: const OpValue(OpValueTypes.str, '过期写入'),
    );
    final res = await h(
      Request(
        'POST',
        Uri.parse('http://s/v1/sync/push'),
        body: jsonEncode(PushRequest(deviceId: '设备C', ops: [stale]).toJson()),
      ),
    );
    final pr = PushResponse.fromJson(
      (jsonDecode(await res.readAsString()) as Map).cast<String, Object?>(),
    );
    expect(pr.results.single.accepted, isFalse);
  });
}
