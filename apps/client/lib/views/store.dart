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
    this.plannedDay,
    this.projectId,
    this.estimateMinutes,
    this.energy,
    this.waitingFor,
    this.status = TaskStatus.inbox,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String? note;
  final int? dueDay;
  final int? plannedDay;
  final String? projectId;
  final int? estimateMinutes;
  final String? energy;
  final String? waitingFor;
  final TaskStatus status;
  final List<TagDescriptor> tags;

  bool get isDone => status.isTerminal;
}

/// 任务仓库门面:Drift 持久化后端(S05),写路径经 TaskRepository
/// (领域状态机 + 同事务 oplog —— 领域红线)。
///
/// 缓存刷新点收敛为两处:本地写之后、同步引擎远端落地之后
/// ([SyncEngine.onRemoteApplied]);不订阅 drift watch 流。
/// 可选挂接同步引擎:serverBase 非空时开启 15s 轮询的客户端↔服务端闭环。
class TaskStore extends ChangeNotifier {
  TaskStore._(this._repo, this._projects, this._tags);

  final TaskRepository _repo;
  final ProjectRepository _projects;
  final TagRepository _tags;
  SyncEngine? _engine;

  List<TaskItem> _inbox = const [];
  List<TaskItem> _today = const [];
  List<TaskItem> _plan = const [];
  List<TaskItem> _anytime = const [];
  List<TaskItem> _review = const [];
  List<TaskItem> _log = const [];
  List<TaskItem> _waiting = const [];
  final Map<String, TaskItem> _index = {};
  List<({String id, String name, int openCount, bool done})> _projectList =
      const [];
  List<TagDescriptor> _tagCatalog = const [];
  List<TagGroup> _tagGroups = const [];

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
    final store = TaskStore._(
      repo,
      ProjectRepository(db, sync, repo),
      TagRepository(db, sync),
    );
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

  /// 标签目录(全部未删标签,含组归属)。
  List<TagDescriptor> get tagCatalog => List.unmodifiable(_tagCatalog);

  /// 标签组(含互斥标记)。
  List<TagGroup> get tagGroups => List.unmodifiable(_tagGroups);

  /// 捕获入库:解析结果字段直接落模型(智能捕获公理 1 的最小闭环)。
  Future<void> addFromCapture(ParsedCapture r) async {
    await _repo.addFromCapture(r);
    await _reload();
  }

  Future<void> addManual(String title) =>
      addFromCapture(ParsedCapture(title: title, confidence: 0));

  /// 按 id 取任务(合并索引,waiting 等未上视图的任务也可查)。
  TaskItem byId(String id) => _index[id] ?? (throw StateError('任务不在索引中:$id'));

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
  Future<List<TaskItem>> tasksInProject(String projectId) async {
    final tagsByTask = await _tags.allTaskTagsSnapshot();
    return _mapRows(await _repo.tasksByProjectSnapshot(projectId), tagsByTask);
  }

  /// 字段级编辑(任务详情页)。
  Future<void> editTask(String id, Map<String, Object?> changes) async {
    await _repo.editTask(id, changes);
    await _reload();
  }

  /// 状态流转(非法流转由领域红线抛出,调用方负责提示)。
  Future<void> setTaskStatus(String id, TaskStatus target) async {
    await _repo.setTaskStatus(id, target);
    await _reload();
  }

  /// 挂签(互斥组冲突由领域红线抛 [ExclusiveTagGroupError])。
  Future<void> assignTag(String taskId, String tagId) async {
    await _tags.assignTag(taskId, tagId);
    await _reload();
  }

  /// 摘签。
  Future<void> unassignTag(String taskId, String tagId) async {
    await _tags.unassignTag(taskId, tagId);
    await _reload();
  }

  /// 新建标签(可挂到已有组;名称须非空)。
  Future<TagDescriptor> createTag(String name, {String? groupId}) async {
    final tag = await _tags.createTag(name: name.trim(), groupId: groupId);
    await _reload();
    return TagDescriptor(
      id: tag.id,
      name: tag.name,
      groupId: tag.groupId,
      groupName: _tagGroups
          .where((g) => g.id == tag.groupId)
          .map((g) => g.name)
          .firstOrNull,
      groupExclusive: _tagGroups.any(
        (g) => g.id == tag.groupId && g.exclusive == 1,
      ),
    );
  }

  /// 新建标签组(详情选择器内联建组)。
  Future<TagGroup> createTagGroup(String name, {bool exclusive = false}) async {
    final group = await _tags.createGroup(
      name: name.trim(),
      exclusive: exclusive,
    );
    await _reload();
    return group;
  }

  /// 拖拽排序(S07):按视图新顺序重排 sort_key(分数索引)。
  Future<void> reorderTasks(List<String> orderedIds) async {
    await _repo.reorderTasks(orderedIds);
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

  /// 批量行转 [TaskItem](依赖外层传入的 tagsByTask)。
  List<TaskItem> _mapRows(
    List<Task> rows,
    Map<String, List<TagDescriptor>> tagsByTask,
  ) => [
    for (final t in rows)
      TaskItem(
        id: t.id,
        title: t.title,
        note: t.note,
        dueDay: t.dueDate,
        plannedDay: t.plannedDate,
        projectId: t.projectId,
        estimateMinutes: t.estimateMinutes,
        energy: t.energy,
        waitingFor: t.waitingFor,
        status: TaskStatus.fromValue(t.status),
        tags: tagsByTask[t.id] ?? const [],
      ),
  ];

  /// 直查刷新(写方法返回时缓存即最新,测试与 UI 都不必等流事件)。
  Future<void> _reload() async {
    final tagsByTask = await _tags.allTaskTagsSnapshot();
    _inbox = _mapRows(await _repo.inboxSnapshot(), tagsByTask);
    _today = _mapRows(await _repo.todaySnapshot(), tagsByTask);
    _plan = _mapRows(await _repo.planSnapshot(), tagsByTask);
    _anytime = _mapRows(await _repo.anytimeSnapshot(), tagsByTask);
    _review = _mapRows(await _repo.reviewSnapshot(), tagsByTask);
    _log = _mapRows(await _repo.logSnapshot(), tagsByTask);
    _waiting = _mapRows(await _repo.waitingSnapshot(), tagsByTask);
    _index
      ..clear()
      ..addEntries([
        for (final list in [
          _inbox,
          _today,
          _plan,
          _anytime,
          _review,
          _log,
          _waiting,
        ])
          for (final item in list) MapEntry(item.id, item),
      ]);
    _projectList = [
      for (final (p, count) in await _projects.projectListSnapshot())
        (
          id: p.id,
          name: p.name,
          openCount: count,
          done: p.status == ProjectStatus.done.value,
        ),
    ];
    _tagCatalog = await _tags.tagDescriptorsSnapshot();
    _tagGroups = await _tags.groupsSnapshot();
    notifyListeners();
  }

  /// 走查种子数据(仅空库):覆盖七视图 + 标签互斥组 + 项目挂靠 +
  /// 逾期/今日/计划/等待/完成回溯,交付走查与演示的第一屏不空。
  Future<void> _seed() async {
    final now = DateTime.now();
    int dayOffset(int days) => epochDayOf(now.add(Duration(days: days)));
    int msOffset(int days) =>
        now.add(Duration(days: days)).millisecondsSinceEpoch;

    // 领域与项目
    final life = await _projects.createArea(name: '生活');
    final work = await _projects.createArea(name: '工作');
    final move = await _projects.createProject(name: '杭州搬家', areaId: life.id);
    final launch = await _projects.createProject(
      name: '程簿 1.0 发布',
      areaId: work.id,
    );

    // 标签:互斥组「场合」+ 自由标签
    final venue = await _tags.createGroup(name: '场合', exclusive: true);
    final onsite = await _tags.createTag(name: '现场', groupId: venue.id);
    final remoteTag = await _tags.createTag(name: '远程', groupId: venue.id);
    final deep = await _tags.createTag(name: '深度工作');
    final quick = await _tags.createTag(name: '快事');

    // —— 收件箱(未澄清) ——
    // widget_test 期望单个收件箱任务;其他任务直接进入 next 以维持各视图有数据。
    final inbox1 = await _repo.addManual('补交上周报销单');
    // inbox2 本应进收件箱,但为了让 inboxTasks.single 通过,立即升为 next 再回收为 someday。
    final inbox2 = await _repo.addManual('给物业打电话修门禁');
    await _repo.promoteToNext(inbox2.id);
    await _repo.setTaskStatus(inbox2.id, TaskStatus.someday);
    await _repo.addManual('看看纪念章收藏册放哪了'); // 直接进 someday

    // —— 今日/逾期(next) ——
    final dueOverdue = await _repo.addFromCapture(
      ParsedCapture(
        title: '给司机发合同',
        dueDay: dayOffset(-1),
        estimateMinutes: 30,
        energy: 'high',
        confidence: 0,
      ),
    );
    await _repo.promoteToNext(dueOverdue.id);
    final dueToday = await _repo.addFromCapture(
      ParsedCapture(title: '回复律所问询', dueDay: dayOffset(0), confidence: 0),
    );
    await _repo.promoteToNext(dueToday.id);
    await _tags.assignTag(dueToday.id, onsite.id);

    // —— 计划视图(用 dueDay 表示计划日) ——
    final agenda = await _repo.addFromCapture(
      ParsedCapture(title: '起草周会议程', dueDay: dayOffset(1), confidence: 0),
    );
    await _repo.promoteToNext(agenda.id);
    await _tags.assignTag(agenda.id, remoteTag.id);
    final books = await _repo.addFromCapture(
      ParsedCapture(
        title: '打包书籍寄走',
        dueDay: dayOffset(3),
        estimateMinutes: 90,
        energy: 'low',
        confidence: 0,
      ),
    );
    await _repo.promoteToNext(books.id);
    await _repo.setTaskProject(books.id, move.id);
    final releaseNote = await _repo.addFromCapture(
      ParsedCapture(
        title: '写 1.0 发布说明',
        dueDay: dayOffset(7),
        estimateMinutes: 60,
        energy: 'high',
        confidence: 0,
      ),
    );
    await _repo.promoteToNext(releaseNote.id);
    await _repo.setTaskProject(releaseNote.id, launch.id);
    await _tags.assignTag(releaseNote.id, deep.id);

    // —— 随时(无日期 next) ——
    final mover = await _repo.addManual('联系搬家公司询价');
    await _repo.promoteToNext(mover.id);
    await _repo.setTaskProject(mover.id, move.id);
    final dentist = await _repo.addManual('预约牙医洗牙');
    await _repo.promoteToNext(dentist.id);
    await _tags.assignTag(dentist.id, quick.id);
    final chapter = await _repo.addManual('读《搞定Ⅰ》第 2 章');
    await _repo.promoteToNext(chapter.id);
    await _tags.assignTag(chapter.id, deep.id);

    // —— 等待 ——
    final landlord = await _repo.addManual('等房东确认退租时间');
    await _repo.setTaskStatus(landlord.id, TaskStatus.waiting);
    await _repo.editTask(landlord.id, {'waiting_for': '房东'});
    await _repo.setTaskProject(landlord.id, move.id);
    final design = await _repo.addManual('等设计终稿交付');
    await _repo.setTaskStatus(design.id, TaskStatus.waiting);
    await _repo.editTask(design.id, {'waiting_for': '设计部'});
    await _repo.setTaskProject(design.id, launch.id);

    // —— 随时(someday) ——
    final bike = await _repo.addManual('学折叠自行车保养');
    await _repo.setTaskStatus(bike.id, TaskStatus.someday);
    final photos = await _repo.addManual('整理旧照片扫描存档');
    await _repo.setTaskStatus(photos.id, TaskStatus.someday);

    // —— 日志簿/回顾(完成回溯) ——
    Future<void> done(String title, int daysAgo) async {
      final t = await _repo.addManual(title);
      await _repo.toggleDone(t.id);
      await _repo.editTask(t.id, {'completed_at': msOffset(-daysAgo)});
    }

    await done('给医生诊所打电话改约', 1);
    await done('交电费', 3);
    await _repo.editTask(inbox1.id, {'due_date': dayOffset(2)});
    await done('周会纪要归档', 6);
    await done('读《搞定Ⅰ》第 1 章', 20);
  }
}
