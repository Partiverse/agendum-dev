/// 解析结果（04 文档 §2 引擎 1 输出 schema 的端上子集）。
///
/// 字段语义：日期按 epoch days、时刻按 epoch ms（02 文档 §4.2）。
library;

class ParsedCapture {
  const ParsedCapture({
    required this.title,
    required this.confidence,
    this.dueDay,
    this.dueAtMs,
    this.reminderAtMs,
    this.estimateMinutes,
    this.energy,
    this.tags = const [],
    this.projectHint,
    this.isDeadline = false,
    this.ambiguities = const [],
  });

  /// 剩余文本（去掉被识别的表达后）。
  final String title;

  /// 0..0.95，识别字段越多越高；存在歧义扣减。
  final double confidence;

  /// 截止日（本地日）。
  final int? dueDay;

  /// 截止时刻（日期+时刻同时出现时设置）。
  final int? dueAtMs;

  /// 提醒时刻。v0 规则：日期+时刻 → 与 dueAt 同；孤立时刻（无日期）→
  /// 视为今天该时刻的提醒。
  final int? reminderAtMs;

  /// 预计时长（分钟）。
  final int? estimateMinutes;

  /// high | low。
  final String? energy;

  final List<String> tags;

  /// 项目路由提示（`@项目`）。
  final String? projectHint;

  /// 输入含"…前"（截止语义），v0 仅作标记不改变字段。
  final bool isDeadline;

  /// 歧义与降级说明（如"第二个日期被忽略""日期已过去按明年解析"）。
  final List<String> ambiguities;

  bool get hasDue => dueDay != null || dueAtMs != null;

  /// 网关响应用的 JSON 形态（字段名 snake_case，与协议风格一致）。
  Map<String, Object?> toJson() => {
    'title': title,
    'confidence': confidence,
    if (dueDay != null) 'due_day': dueDay,
    if (dueAtMs != null) 'due_at_ms': dueAtMs,
    if (reminderAtMs != null) 'reminder_at_ms': reminderAtMs,
    if (estimateMinutes != null) 'estimate_minutes': estimateMinutes,
    if (energy != null) 'energy': energy,
    'tags': tags,
    if (projectHint != null) 'project_hint': projectHint,
    'is_deadline': isDeadline,
    'ambiguities': ambiguities,
  };

  @override
  String toString() =>
      'ParsedCapture($title, dueDay=$dueDay, dueAt=$dueAtMs, '
      'estimate=$estimateMinutes, energy=$energy, tags=$tags, '
      'project=$projectHint, conf=$confidence, amb=$ambiguities)';
}
