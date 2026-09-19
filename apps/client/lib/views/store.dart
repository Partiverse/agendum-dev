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
  TaskStore._(this._repo, this._projects);

  final TaskRepository _repo;
  final ProjectRepository _projects;
  SyncEngine? _engine;

  List<TaskItem> _inbox = const [];
  List<TaskItem> _today = const [];
  List<TaskItem> _plan = const [];
  List<TaskItem> _anytime = const [];
  List<TaskItem> _review = const [];
  List<TaskItem> _log = const [];
  List<({String id, String name, int openCount, bool done})> _projectList =
      const [];

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
    final sync = await DriftLocalSyncStore.open(db);
    final repo = TaskRepository(db, sync);
    final store = TaskStore._(repo, ProjectRepository(db, sync));
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

  /// 计划视图:带 planned/due 日期的活跃任务。
  List<TaskItem> get planTasks => List.unmodifiable(_plan);

  /// 随时视图:someday + 无日期的 next。
  List<TaskItem> get anytimeTasks => List.unmodifiable(_anytime);

  /// 回顾视图:近 7 天完成。
  List<TaskItem> get reviewTasks => List.unmodifiable(_review);

  /// 日志簿:全部已完成。
  List<TaskItem> get logTasks => List.unmodifiable(_log);

  /// 项目列表(含未完成任务数)。
  List<({String id, String name, int openCount, bool done})> get projectList =>
      List.unmodifiable(_projectList);

  /// 捕获入库:解析结果字段直接落模型(智能捕获公理 1 的最小闭环)。
  Future<void> addFromCapture(ParsedCapture r) async {
    await _repo.addFromCapture(r);
    await _reload();
  }

  Future<void> addManual(String title) =>
      addFromCapture(ParsedCapture(title: title, confidence: 0));

  TaskItem byId(String id) =>
      _inbox.firstWhere((t) => t.id == id, orElse: () => _anyTask(id));

  TaskItem _anyTask(String id) {
    for (final list in [_today, _plan, _anytime, _review, _log]) {
      for (final t in list) {
        if (t.id == id) return t;
      }
    }
    throw StateError('任务不在任何视图缓存中:$id');
  }

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

  /// 回收进收件箱(⌫ 键盘流;非法流转由领域红线抛出)。
  Future<void> moveToInbox(String id) async {
    await _repo.moveToInbox(id);
    await _reload();
  }

  /// 新建项目(项目视图内联创建)。
  Future<void> addProject(String name) async {
    if (name.trim().isEmpty) return;
    await _projects.createProject(name: name.trim());
    await _reload();
  }

  /// 任务挂到项目/移出项目。
  Future<void> setTaskProject(String taskId, String? projectId) async {
    await _repo.setTaskProject(taskId, projectId);
    await _reload();
  }

  /// 项目内任务(项目详情展开用)。
  Future<List<TaskItem>> tasksInProject(String projectId) async =>
      TaskStore._mapAll(await _repo.tasksByProjectSnapshot(projectId));

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
    _plan = _mapAll(await _repo.planSnapshot());
    _anytime = _mapAll(await _repo.anytimeSnapshot());
    _review = _mapAll(await _repo.reviewSnapshot());
    _log = _mapAll(await _repo.logSnapshot());
    _projectList = [
      for (final (p, count) in await _projects.projectListSnapshot())
        (
          id: p.id,
          name: p.name,
          openCount: count,
          done: p.status == ProjectStatus.done.value,
        ),
    ];
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
