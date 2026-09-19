/// 内存实现：本地开发、单测与收敛 PoC 用（语义与 PgSyncStore 完全一致）。
library;

import 'package:agendum_protocol/agendum_protocol.dart';

import 'sync_store.dart';

final class MemorySyncStore implements SyncStore {
  final List<(int, SyncOp)> _log = [];
  final Map<String, (int, String)> _heads = {};
  int _seq = 0;

  int get seq => _seq;

  static String _headKey(SyncOp op) =>
      '${op.entity}|${op.entityId}|${op.field}';

  /// (lamport, origin) 字典序，与 packages/sync resolveEntry 的优先级一致。
  static int _cmp((int, String) a, (int, String) b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    return a.$2.compareTo(b.$2);
  }

  @override
  Future<PushResponse> push(PushRequest req) async {
    final results = <PushOpResult>[];
    var lastSeq = _seq;
    for (final op in req.ops) {
      _seq++;
      lastSeq = _seq;
      _log.add((_seq, op));
      final key = _headKey(op);
      final incoming = (op.lamport, op.deviceId);
      final head = _heads[key];
      final accepted = head == null || _cmp(incoming, head) >= 0;
      if (accepted) {
        _heads[key] = incoming;
      }
      results.add(PushOpResult(index: results.length, accepted: accepted));
    }
    return PushResponse(serverSeq: lastSeq, results: results);
  }

  @override
  Future<PullResponse> pull({required int since, required int limit}) async {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', '≥1');
    }
    final fetched = _log.where((e) => e.$1 > since).take(limit + 1).toList();
    final hasMore = fetched.length > limit;
    final page = hasMore ? fetched.sublist(0, limit) : fetched;
    final cursor = page.isEmpty ? since : page.last.$1;
    return PullResponse(
      cursor: cursor,
      ops: page.map((e) => e.$2).toList(),
      hasMore: hasMore,
    );
  }

  @override
  Future<void> close() async {}
}
