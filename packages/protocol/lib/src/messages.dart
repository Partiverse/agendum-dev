/// 同步接口消息（03 文档 §4.2）：
/// `POST /v1/sync/push`、`GET /v1/sync/pull?since&limit`。
library;

import 'op.dart';

/// 协议版本（02 文档 §8.3：服务端向前兼容一个版本）。
const String protocolVersion = 'v1';

class PushRequest {
  const PushRequest({required this.deviceId, required this.ops});

  /// 单批上限（03 文档 §4.2：≤500 条/批）。
  static const int maxBatchSize = 500;

  final String deviceId;
  final List<SyncOp> ops;

  Map<String, Object?> toJson() => {
    'device_id': deviceId,
    'ops': ops.map((o) => o.toJson()).toList(),
  };

  factory PushRequest.fromJson(Map<String, Object?> json) {
    final deviceId = json['device_id'];
    final rawOps = json['ops'];
    if (deviceId is! String || deviceId.isEmpty) {
      throw const FormatException('push.device_id 缺失');
    }
    if (rawOps is! List) throw const FormatException('push.ops 缺失');
    if (rawOps.length > maxBatchSize) {
      throw FormatException('push.ops 超过单批上限 $maxBatchSize');
    }
    return PushRequest(
      deviceId: deviceId,
      ops: [for (final o in rawOps) SyncOp.fromJson(o as Map<String, Object?>)],
    );
  }
}

class PushOpResult {
  const PushOpResult({
    required this.index,
    required this.accepted,
    this.reason,
  });

  final int index;
  final bool accepted;
  final String? reason;

  Map<String, Object?> toJson() => {
    'i': index,
    'accepted': accepted,
    if (reason != null) 'reason': reason,
  };

  factory PushOpResult.fromJson(Map<String, Object?> json) {
    final i = json['i'];
    final accepted = json['accepted'];
    if (i is! int || accepted is! bool) {
      throw const FormatException('push result 字段非法');
    }
    return PushOpResult(
      index: i,
      accepted: accepted,
      reason: json['reason'] as String?,
    );
  }
}

class PushResponse {
  const PushResponse({required this.serverSeq, required this.results});

  final int serverSeq;
  final List<PushOpResult> results;

  Map<String, Object?> toJson() => {
    'server_seq': serverSeq,
    'results': results.map((r) => r.toJson()).toList(),
  };

  factory PushResponse.fromJson(Map<String, Object?> json) {
    final seq = json['server_seq'];
    final raw = json['results'];
    if (seq is! int || raw is! List) {
      throw const FormatException('push response 字段非法');
    }
    return PushResponse(
      serverSeq: seq,
      results: [
        for (final r in raw) PushOpResult.fromJson(r as Map<String, Object?>),
      ],
    );
  }
}

class PullResponse {
  const PullResponse({
    required this.cursor,
    required this.ops,
    required this.hasMore,
  });

  final int cursor; // 服务端全局序号，作为下一次 since
  final List<SyncOp> ops;
  final bool hasMore;

  Map<String, Object?> toJson() => {
    'cursor': cursor,
    'ops': ops.map((o) => o.toJson()).toList(),
    'has_more': hasMore,
  };

  factory PullResponse.fromJson(Map<String, Object?> json) {
    final cursor = json['cursor'];
    final raw = json['ops'];
    final hasMore = json['has_more'];
    if (cursor is! int || raw is! List || hasMore is! bool) {
      throw const FormatException('pull response 字段非法');
    }
    return PullResponse(
      cursor: cursor,
      ops: [for (final o in raw) SyncOp.fromJson(o as Map<String, Object?>)],
      hasMore: hasMore,
    );
  }
}
