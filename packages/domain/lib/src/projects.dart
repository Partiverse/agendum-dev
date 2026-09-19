/// 项目/领域状态（03 文档 DDL：`projects.status`）。
///
/// 与任务状态机同构的领域红线：项目状态变更必须经 [transitionProject]，
/// 禁止直改字段绕过校验。Area 无状态字段，仅实体本身。
library;

/// 项目状态。active=推进中, on_hold=搁置, done=完成归档。
enum ProjectStatus {
  active('active'),
  onHold('on_hold'),
  done('done');

  const ProjectStatus(this.value);

  final String value;

  static ProjectStatus fromValue(String value) =>
      ProjectStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => throw ArgumentError.value(value, 'value', '未知项目状态'),
      );

  @override
  String toString() => value;
}

/// 允许的项目状态流转。done 是准终态:重新推进须经 active(先恢复再搁置)。
const Map<ProjectStatus, Set<ProjectStatus>> _allowedTransitions = {
  ProjectStatus.active: {ProjectStatus.onHold, ProjectStatus.done},
  ProjectStatus.onHold: {ProjectStatus.active, ProjectStatus.done},
  ProjectStatus.done: {ProjectStatus.active},
};

bool canTransitionProject(ProjectStatus from, ProjectStatus to) =>
    from == to || _allowedTransitions[from]!.contains(to);

/// 执行项目状态流转。同状态重复流转视为幂等成功。
ProjectStatus transitionProject(ProjectStatus from, ProjectStatus to) {
  if (!canTransitionProject(from, to)) {
    throw ArgumentError('项目状态流转 $from → $to 不被允许');
  }
  return to;
}
