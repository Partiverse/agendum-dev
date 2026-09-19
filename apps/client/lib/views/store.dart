import 'dart:async';

import 'package:agendum_db/agendum_db.dart';
import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:flutter/foundation.dart';

/// 一条任务在本地视图模型(S05 起由 Drift 行映射,只读;变更走 [TaskStore])。
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.note,
    this.dueDay,
    this.estimateMinutes,
    this.energy,
    this.status = TaskStatus.inbox,
  });

  final String id;
  final String title;
  final String? note;
  final int? dueDay;
  final int? estimateMinutes;
  final String? energy;
  final TaskStatus status;

  bool get isDone => status.isTerminal;
}

/// 任务仓库门面:Drift 持久化后端(S05),写路径经 TaskRepository
/// (领域状态机 + 同事务 oplog —— 领域红线)。
///
/// 缓存刷新点收敛为两处:本地写之后、同步引擎远端落地之后
/// ([SyncEngine.onRemoteApplied]);不订阅 drift watch 流。
/// 可选挂接同步引擎:serverBase 非空时开启 15s 轮询的客户端↔服务端闭环。
class TaskStore extends ChangeNotifier {
  TaskStore._(this._repo);

  final TaskRepository _repo;
  SyncEngine? _engine;

  List<TaskItem> _inbox = const [];
  List<TaskItem> _today = const [];

  /// 打开:传入 executor(测试用内存库;主入口传文件库)。
  /// [serverBase] 非空时创建同步引擎;[autoSync] 开启 15s 轮询,
  /// 关闭则仅手动 [syncNow](测试确定性用)。
  static Future<TaskStore> open({
    required QueryExecutor executor,
    bool seedIfEmpty = false,
    String? serverBase,
    bool autoSync = true,
  }) async {
    final db = AgendumDatabase(executor);
    final repo = TaskRepository(db, await DriftLocalSyncStore.open(db));
    final store = TaskStore._(repo);
    if (serverBase != null) {
      store._engine = SyncEngine(
        store: repo.sync,
        transport: RestSyncTransport(base: serverBase),
        onTrace: debugPrint,
        onRemoteApplied: () {
          unawaited(store._reload());
        },
      );
    }
    if (seedIfEmpty && await repo.count() == 0) {
      await store._seed();
    }
    await store._reload();
    if (autoSync) store._engine?.startPolling();
    return store;
  }

  /// 收件箱:未澄清的 + 已完成的(完成后保留显示删除线,Things 行为)。
  List<TaskItem> get inboxTasks => List.unmodifiable(_inbox);

  /// 今日视图:next 状态 + 截止日未过的任务(样板期简化语义)。
  List<TaskItem> get todayTasks => List.unmodifiable(_today);

  /// 捕获入库:解析结果字段直接落模型(智能捕获公理 1 的最小闭环)。
  Future<void> addFromCapture(ParsedCapture r) async {
    await _repo.addFromCapture(r);
    await _reload();
  }

  Future<void> addManual(String title) =>
      addFromCapture(ParsedCapture(title: title, confidence: 0));

  TaskItem byId(String id) => _inbox.firstWhere(
    (t) => t.id == id,
    orElse: () => _today.firstWhere((t) => t.id == id),
  );

  /// 完成/恢复(领域状态机)。
  Future<void> toggleDone(String id) async {
    await _repo.toggleDone(id);
    await _reload();
  }

  /// 收件箱 → 下一步。
  Future<void> promoteToNext(String id) async {
    await _repo.promoteToNext(id);
    await _reload();
  }

  /// 手动触发一轮同步(push + pull)。
  Future<void> syncNow() async {
    await _engine?.syncNow();
    await _reload();
  }

  Future<void> close() async {
    _engine?.stopPolling();
    await _repo.sync.close();
  }

  // ---- 内部 ----

  /// 直查刷新(写方法返回时缓存即最新,测试与 UI 都不必等流事件)。
  Future<void> _reload() async {
    _inbox = _mapAll(await _repo.inboxSnapshot());
    _today = _mapAll(await _repo.todaySnapshot());
    notifyListeners();
  }

  static List<TaskItem> _mapAll(List<Task> rows) => [
    for (final t in rows)
      TaskItem(
        id: t.id,
        title: t.title,
        note: t.note,
        dueDay: t.dueDate,
        estimateMinutes: t.estimateMinutes,
        energy: t.energy,
        status: TaskStatus.fromValue(t.status),
      ),
  ];

  /// 走查种子数据(仅空库)。
  Future<void> _seed() async {
    final tomorrow = epochDayOf(DateTime.now().add(const Duration(days: 1)));
    final t1 = await _repo.addFromCapture(
      ParsedCapture(
        title: '给司机发合同',
        dueDay: tomorrow,
        estimateMinutes: 30,
        energy: 'high',
        confidence: 0,
      ),
    );
    await _repo.promoteToNext(t1.id);
    final t2 = await _repo.addFromCapture(
      ParsedCapture(
        title: '整理收件箱积压',
        estimateMinutes: 45,
        energy: 'low',
        confidence: 0,
      ),
    );
    await _repo.promoteToNext(t2.id);
    await _repo.addManual('读《搞定Ⅰ》第 2 章');
  }
}
