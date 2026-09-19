import 'package:flutter/foundation.dart';
import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_nlp/agendum_nlp.dart';

/// 一条任务在样板期的本地视图模型（S05 起由 Drift 仓库层替换）。
class TaskItem {
  TaskItem({
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
  String? note;
  int? dueDay;
  int? estimateMinutes;
  String? energy;
  TaskStatus status;

  bool get isDone => status.isTerminal;

  /// 完成/恢复走领域状态机（任何写路径必须经 transition —— 领域红线）。
  void toggleDone() {
    status = transition(status, isDone ? TaskStatus.next : TaskStatus.done);
  }

  /// 收件箱 → 下一步（走状态机）。
  void promoteToNext() {
    status = transition(status, TaskStatus.next);
  }
}

/// 内存任务仓库：样式走查与 widget 测试用（S05 接 Drift + oplog）。
class TaskStore extends ChangeNotifier {
  TaskStore();

  final List<TaskItem> _tasks = [];
  static String _nextId() =>
      't${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  /// 收件箱：未澄清的 + 已完成的（完成后保留显示删除线，Things 行为）。
  List<TaskItem> get inboxTasks => List.unmodifiable(
    _tasks.where((t) => t.status == TaskStatus.inbox || t.isDone),
  );

  /// 今日视图：next 状态 + 截止日未过的任务（样板期简化语义）。
  List<TaskItem> get todayTasks {
    final today = epochDayOf(DateTime.now());
    return List.unmodifiable(
      _tasks.where(
        (t) =>
            !t.isDone &&
            (t.status == TaskStatus.next ||
                (t.dueDay != null && t.dueDay! <= today)),
      ),
    );
  }

  /// 捕获入库：解析结果字段直接落模型（智能捕获公理 1 的最小闭环）。
  TaskItem addFromCapture(ParsedCapture r) {
    final t = TaskItem(
      id: _nextId(),
      title: r.title,
      dueDay: r.dueDay,
      estimateMinutes: r.estimateMinutes,
      energy: r.energy,
    );
    _tasks.insert(0, t);
    notifyListeners();
    return t;
  }

  TaskItem addManual(String title) =>
      addFromCapture(ParsedCapture(title: title, confidence: 0));

  TaskItem byId(String id) => _tasks.firstWhere((t) => t.id == id);

  void toggleDone(String id) {
    byId(id).toggleDone();
    notifyListeners();
  }

  /// 走查种子数据。
  factory TaskStore.withSeed() {
    final s = TaskStore();
    final tomorrow = epochDayOf(DateTime.now().add(const Duration(days: 1)));
    final t1 = s.addManual('给司机发合同');
    t1
      ..dueDay = tomorrow
      ..estimateMinutes = 30
      ..energy = 'high'
      ..promoteToNext();
    final t2 = s.addManual('整理收件箱积压');
    t2
      ..estimateMinutes = 45
      ..energy = 'low'
      ..promoteToNext();
    s.addManual('读《搞定Ⅰ》第 2 章');
    s.notifyListeners();
    return s;
  }
}
