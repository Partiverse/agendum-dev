/// 同步存储接口（03 文档 §4.4）。
///
/// 服务端职责：**序号分配 + op 存储/转发 + 字段裁决表维护**——永不接触
/// 明文负载语义（E2EE 模式下 payload 为密文）。客户端最终一致性由
/// packages/sync 的 resolveEntry 重放保证，裁决表只用于 ack 与快照优化。
library;

import 'package:agendum_protocol/agendum_protocol.dart';

abstract interface class SyncStore {
  /// 分配全局单调 server_seq，维护 (entity, entity_id, field) 裁决表。
  /// accepted = 本次写入在裁决表上胜出（幂等重放同源同 op 亦视为 accepted）。
  Future<PushResponse> push(PushRequest req);

  /// 返回 seq > since 的 op（至多 limit 条），cursor 为最后返回条目的 seq。
  Future<PullResponse> pull({required int since, required int limit});

  Future<void> close();
}
