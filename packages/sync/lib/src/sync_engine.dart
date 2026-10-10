/// 同步客户端引擎(03 文档 §4.3):push 未确认 ops → 回填 server_seq;
/// pull 按 cursor 增量,逐条交本地裁决应用。
///
/// 引擎只管队列与游标,**不做合并**——应用逻辑在 [LocalSyncStore] 实现
/// (Drift 实现见 packages/db),与传输通道解耦(测试可注入假通道)。
library;

import 'dart:async';

import 'package:agendum_protocol/agendum_protocol.dart';

/// 一条待推送 op 与其本地 oplog 序号(回填 server_seq 用)。
class PendingOp {
  const PendingOp({required this.localSeq, required this.op});

  final int localSeq;
  final SyncOp op;
}

/// 本地 oplog + 裁决状态的抽象(packages/db 提供Drift 实现)。
abstract interface class LocalSyncStore {
  /// 本设备 ID(push 与 op.device_id 必须一致)。
  String get deviceId;

  /// 租户 uid(R1 §5/§8):push 请求体与 pull 查询参数都携带,服务端
  /// 按 owner=uid 过滤。由上层(Vault 主密钥派生/明文模式固定值)注入,
  /// 本包不理解其内部结构。
  String get uid;

  /// 取未确认(server_seq 为空)的 ops,按 local_seq 升序。
  Future<List<PendingOp>> takePendingOps({int limit});

  /// 推送确认后回填:标记这些 local_seq 已推送。
  /// 被服务端拒绝(stale)的 op 一并标记——重试无意义,本地值等待 pull 覆盖。
  Future<void> markPushed(Iterable<int> localSeqs, int serverSeq);

  /// 拉取游标(已连续应用到的服务端全局序号)。
  Future<int> pullCursor();

  Future<void> setPullCursor(int seq);

  /// 应用一条远端 op:按 (lamport, origin) 裁决,胜出则落实体表并推进
  /// 字段裁决镜像与本设备 lamport 时钟。返回是否实际落地。
  Future<bool> applyRemoteOp(SyncOp op);

  /// 关闭底层资源(数据库连接等)。
  Future<void> close();
}

/// 传输通道(REST 实现见 [RestSyncTransport];测试注入假实现)。
abstract interface class SyncTransport {
  Future<PushResponse> push(PushRequest req);

  /// [uid] 为租户标识(R1 §5):服务端按 owner=uid 过滤,跨 uid 拿不到
  /// 对方任何 op。
  Future<PullResponse> pull({
    required int since,
    required int limit,
    required String uid,
  });
}

/// op 线上编解码钩子(03 文档 §6.2):明文模式恒等;E2EE 密文化由
/// packages/e2ee 提供实现(XChaCha20-Poly1305,AAD 绑定裁决元数据)。
/// 引擎只调钩子,不懂密钥 —— 通道语义不变(服务端仍只做序号与转发)。
abstract interface class OpCodec {
  /// push 前:本地明文 op → 线上形态。
  Future<SyncOp> encodeForWire(SyncOp op);

  /// pull 后、本地裁决应用前:线上形态 → 明文 op。
  Future<SyncOp> decodeFromWire(SyncOp op);
}

/// 恒等编解码(明文开发模式)。
class IdentityOpCodec implements OpCodec {
  const IdentityOpCodec();

  @override
  Future<SyncOp> encodeForWire(SyncOp op) async => op;

  @override
  Future<SyncOp> decodeFromWire(SyncOp op) async => op;
}

class SyncEngine {
  SyncEngine({
    required LocalSyncStore store,
    required SyncTransport transport,
    this.pullLimit = 2000,
    this.onTrace,
    this.onRemoteApplied,
    this.onQuarantined,
    OpCodec? codec,
  }) : _store = store,
       _transport = transport,
       _codec = codec ?? const IdentityOpCodec();

  final LocalSyncStore _store;
  final SyncTransport _transport;
  final OpCodec _codec;

  /// 单次 pull 的条数上限(服务端默认 2000,03 文档 §4.2)。
  final int pullLimit;

  /// 观测钩子(客户端日志/演示页状态条)。
  final void Function(String message)? onTrace;

  /// 远端 op 落地后的通知(每批一次;UI 层借此刷新缓存)。
  final void Function()? onRemoteApplied;

  /// 毒丸 op 死信通知:应用失败的远端 op(字段值非法、解码失败等)被隔离,
  /// 游标照推 —— 单条坏 op 只损失自身,不再卡死该设备之后的全部同步。
  /// 死信持久化与快照补齐属后续演进;当前 op 已越过游标,不会被重拉。
  final void Function(SyncOp op, Object error)? onQuarantined;

  bool _syncing = false;
  Timer? _timer;

  /// 推送全部未确认 ops(分批 ≤[PushRequest.maxBatchSize],直到清空)。
  Future<void> pushPending() async {
    while (true) {
      final batch = await _store.takePendingOps(
        limit: PushRequest.maxBatchSize,
      );
      if (batch.isEmpty) return;
      _trace('push ${batch.length} ops');
      final wireOps = <SyncOp>[];
      for (final p in batch) {
        wireOps.add(await _codec.encodeForWire(p.op));
      }
      final resp = await _transport.push(
        PushRequest(deviceId: _store.deviceId, uid: _store.uid, ops: wireOps),
      );
      await _store.markPushed([
        for (final p in batch) p.localSeq,
      ], resp.serverSeq);
      if (batch.length < PushRequest.maxBatchSize) return;
    }
  }

  /// 按 cursor 增量拉取直到 has_more 为假;逐条本地裁决应用。
  ///
  /// 毒丸隔离:单条 op **应用**失败(字段值非法等)只隔离自身(死信),
  /// 不中断本批、不回退游标 —— 后续 op 照常同步;失败 op 已被游标越过,
  /// 不会重拉。**解码**失败(密钥缺失/密文损坏)不隔离、原样抛出 ——
  /// 那是配置错误,静默跳过等于无声丢掉全部远端数据。
  Future<void> pull() async {
    var since = await _store.pullCursor();
    while (true) {
      final resp = await _transport.pull(
        since: since,
        limit: pullLimit,
        uid: _store.uid,
      );
      var applied = 0;
      for (final wireOp in resp.ops) {
        final op = await _codec.decodeFromWire(wireOp);
        try {
          if (await _store.applyRemoteOp(op)) applied++;
        } catch (error) {
          _quarantine(op, error);
        }
      }
      if (applied > 0) onRemoteApplied?.call();
      since = resp.cursor;
      await _store.setPullCursor(resp.cursor);
      if (resp.ops.isNotEmpty) _trace('pull ${resp.ops.length} ops → $since');
      if (!resp.hasMore) return;
    }
  }

  void _quarantine(SyncOp op, Object error) {
    _trace(
      '死信隔离 ${op.entity}/${op.field}@${op.entityId} '
      'lamport=${op.lamport}:$error',
    );
    onQuarantined?.call(op, error);
  }

  /// 一轮完整同步:先推后拉(推送可能改变服务端序号,先推保序)。
  Future<void> syncNow() async {
    if (_syncing) return; // 轮询与手动触发重入保护
    _syncing = true;
    try {
      await pushPending();
      await pull();
    } finally {
      _syncing = false;
    }
  }

  /// 常驻轮询(Phase 1 用 15s 轮询起步,Phase 2 升 WS,03 文档 §4.3)。
  /// 立即触发一轮,之后每 [every] 一轮;失败不中断轮询(下轮重试)。
  void startPolling({Duration every = const Duration(seconds: 15)}) {
    stopPolling();
    unawaited(syncNow().catchError((Object e) => _trace('sync 失败:$e')));
    _timer = Timer.periodic(every, (_) {
      unawaited(syncNow().catchError((Object e) => _trace('sync 失败:$e')));
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void _trace(String message) => onTrace?.call(message);
}
