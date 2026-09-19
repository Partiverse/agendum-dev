/// GTD 任务状态与状态机（03 文档 DDL：`tasks.status`，报告 §5.2）。
///
/// 流转规则是领域红线：任何写路径必须经 [transition]，禁止直改字段绕过校验。
library;

/// 任务状态。命名与数据库枚举值保持一致（snake_case 字符串）。
enum TaskStatus {
  inbox('inbox'),
  next('next'),
  waiting('waiting'),
  someday('someday'),
  done('done'),
  trashed('trashed');

  const TaskStatus(this.value);

  final String value;

  static TaskStatus fromValue(String value) => TaskStatus.values.firstWhere(
    (s) => s.value == value,
    orElse: () => throw ArgumentError.value(value, 'value', '未知任务状态'),
  );

  /// 终态：不再出现在任何"待办"透视中。
  bool get isTerminal => this == done || this == trashed;

  /// 是否计入"活跃项目缺少下一步"检查（报告 §5.3 引擎 3）。
  bool get isActionable => this == inbox || this == next;

  @override
  String toString() => value;
}

/// 允许的状态流转（含回退路径，如重新打开、从废纸篓恢复）。
const Map<TaskStatus, Set<TaskStatus>> _allowedTransitions = {
  TaskStatus.inbox: {
    TaskStatus.next,
    TaskStatus.waiting,
    TaskStatus.someday,
    TaskStatus.done,
    TaskStatus.trashed,
  },
  TaskStatus.next: {
    TaskStatus.inbox,
    TaskStatus.waiting,
    TaskStatus.someday,
    TaskStatus.done,
    TaskStatus.trashed,
  },
  TaskStatus.waiting: {
    TaskStatus.next,
    TaskStatus.someday,
    TaskStatus.done,
    TaskStatus.trashed,
  },
  TaskStatus.someday: {
    TaskStatus.inbox,
    TaskStatus.next,
    TaskStatus.done,
    TaskStatus.trashed,
  },
  TaskStatus.done: {TaskStatus.inbox, TaskStatus.next, TaskStatus.trashed},
  TaskStatus.trashed: {TaskStatus.inbox},
};

bool canTransition(TaskStatus from, TaskStatus to) =>
    from == to || _allowedTransitions[from]!.contains(to);

/// 非法流转的领域错误（抛出即 bug，不应静默吞掉）。
class IllegalTransitionError extends Error {
  IllegalTransitionError(this.from, this.to);

  final TaskStatus from;
  final TaskStatus to;

  @override
  String toString() => 'IllegalTransitionError: $from → $to 不被允许';
}

/// 执行状态流转。同状态重复流转视为幂等成功。
TaskStatus transition(TaskStatus from, TaskStatus to) {
  if (!canTransition(from, to)) {
    throw IllegalTransitionError(from, to);
  }
  return to;
}
