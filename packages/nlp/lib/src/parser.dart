/// 捕获解析规则引擎 v0。
///
/// 设计（04 文档 §4 优先级链的第一层）：
/// - 纯规则、零依赖、离线、确定性，命中即可信；
/// - 置信度不足或含歧义时返回部分结果，由上层决定是否回落
///   （系统检测器 / 云端），**永不丢数据**——剩余文本总是完整保留为 title；
/// - 时间基准由调用方注入（可测试），语义以"本地日历"为准。
///
/// v0 语义约定：
/// - 日期+时刻 → 截止（dueAt）；仅日期 → 截止日；仅时刻 → 今日提醒；
/// - "…前" 标记 deadline 语义，不改变字段；
/// - 多个日期取第一个，其余记入 ambiguities。
library;

import 'package:agendum_domain/agendum_domain.dart';

import 'parsed_capture.dart';

final class CaptureParser {
  CaptureParser({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static final _energyRe = RegExp(
    r'!\s*(high|low|高|低)(?:精力)?',
    caseSensitive: false,
  );
  static final _durationMinutesRe = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:分钟|mins?|min\b)',
  );
  static final _durationHoursRe = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:小时|hours?\b|hr?s?\b)',
  );
  static final _durationHalfHourRe = RegExp('半小时');
  static final _tagRe = RegExp(r'#([^\s#@，。,、！!?？;；]+)');
  static final _projectRe = RegExp(r'@([^\s#@，。,、！!?？;；]+)');

  // ---- 日期短语（中英） ----
  static final _relDayRe = RegExp('(今天|今日|今晚|今早|明早|明晚|明天|明日|后天|大后天)');
  static final _weekDayRe = RegExp('(下下个|下个|下下|下|本|这)?(?:周|星期|礼拜)([一二三四五六日天])');
  static final _monthDayRe = RegExp('(\\d{1,2})月(\\d{1,2})[日号]');
  static final _nextMonthRe = RegExp('下个?月(\\d{1,2})[日号]');
  static final _inDaysRe = RegExp('(\\d+)天(?:之)?后');
  static final _enRelDayRe = RegExp(
    r'\b(the day after tomorrow|tomorrow|tmr|today|tonight)\b',
    caseSensitive: false,
  );
  static final _enNextWeekRe = RegExp(
    r'\bnext\s+(mon(day)?|tue(s(day)?)?|wed(nes(day)?)?|thu(r(s(day)?)?)?|fri(day)?|sat(ur(day)?)?|sun(day)?)\b',
    caseSensitive: false,
  );
  static final _enWeekRe = RegExp(
    r'\b(mon(day)?|tue(s(day)?)?|wed(nes(day)?)?|thu(r(s(day)?)?)?|fri(day)?|sat(ur(day)?)?|sun(day)?)\b',
    caseSensitive: false,
  );
  static final _enInDaysRe = RegExp(
    r'\bin\s+(\d+)\s+days?\b',
    caseSensitive: false,
  );
  static final _enSlashDateRe = RegExp(r'\b(\d{1,2})/(\d{1,2})\b');

  // ---- 时刻短语 ----
  static final _zhTimeRe = RegExp(
    '(凌晨|清晨|早上|上午|中午|午后|下午|傍晚|晚上|夜里)?\\s*'
    '(\\d{1,2})\\s*[点时]\\s*(?:(\\d{1,2})\\s*分?|(半))?\\s*前?',
  );
  static final _colonTimeRe = RegExp(r'\b(\d{1,2}):(\d{2})\b');
  static final _enTimeRe = RegExp(
    r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
    caseSensitive: false,
  );

  static const _zhWeekday = {
    '一': DateTime.monday,
    '二': DateTime.tuesday,
    '三': DateTime.wednesday,
    '四': DateTime.thursday,
    '五': DateTime.friday,
    '六': DateTime.saturday,
    '日': DateTime.sunday,
    '天': DateTime.sunday,
  };

  static const _enWeekday = {
    'mon': DateTime.monday,
    'tue': DateTime.tuesday,
    'wed': DateTime.wednesday,
    'thu': DateTime.thursday,
    'fri': DateTime.friday,
    'sat': DateTime.saturday,
    'sun': DateTime.sunday,
  };

  static const _relDayOffset = {
    '今天': 0,
    '今日': 0,
    '今晚': 0,
    '今早': 0,
    'tonight': 0,
    'today': 0,
    '明天': 1,
    '明日': 1,
    '明早': 1,
    '明晚': 1,
    'tomorrow': 1,
    'tmr': 1,
    '后天': 2,
    'the day after tomorrow': 2,
    '大后天': 3,
  };

  /// 口语时段词 → 标准时段词：紧跟时刻时保留给时刻解析用
  /// （"今晚11点半" → 日期=今天 + "晚上11点半" → 23:30，而非 11:30）。
  static const _periodCarry = {'今晚': '晚上', '明晚': '晚上', '今早': '早上', '明早': '早上'};

  /// 解析自然语言输入。永不抛出（规则引擎层不因输入而失败）。
  ParsedCapture parse(String input) {
    final now = _now();
    final ambiguities = <String>[];
    var text = input.replaceAll('明儿', '明天'); // 北方口语归一化
    String? energy;
    int? estimateMinutes;
    final tags = <String>[];
    String? projectHint;
    int? dueDay;
    int? dueAtMs;
    int? reminderAtMs;
    var isDeadline = false;

    // 1. 精力
    final energyM = _energyRe.firstMatch(text);
    if (energyM != null) {
      final g = energyM.group(1)!.toLowerCase();
      energy = (g == 'high' || g == '高') ? 'high' : 'low';
      text = _blank(text, energyM);
    }

    // 2. 时长
    final half = _durationHalfHourRe.firstMatch(text);
    if (half != null) {
      estimateMinutes = 30;
      text = _blank(text, half);
    } else {
      final minutes = _durationMinutesRe.firstMatch(text);
      final hours = _durationHoursRe.firstMatch(text);
      final RegExpMatch? m;
      if (minutes == null) {
        m = hours;
      } else if (hours == null) {
        m = minutes;
      } else {
        m = minutes.start <= hours.start ? minutes : hours;
      }
      if (m != null) {
        final n = double.parse(m.group(1)!);
        final isHours = identical(m.pattern, _durationHoursRe);
        estimateMinutes = (n * (isHours ? 60 : 1)).round();
        text = _blank(text, m);
      }
    }

    // 3. 标签 / 项目
    for (final m in _tagRe.allMatches(text).toList()) {
      final t = m.group(1)!;
      if (!tags.contains(t)) tags.add(t);
      text = _blank(text, m);
    }
    final projMatches = _projectRe.allMatches(text).toList();
    for (var i = 0; i < projMatches.length; i++) {
      final m = projMatches[i];
      text = _blank(text, m);
      if (i == 0) {
        projectHint = m.group(1)!;
      } else {
        ambiguities.add('多个项目路由：仅取第一个');
      }
    }

    // 4. 日期：循环提取，第一个生效，其余记歧义
    var dateCount = 0;
    while (true) {
      final m = _earliestMatch(text, [
        _relDayRe,
        _weekDayRe,
        _nextMonthRe,
        _monthDayRe,
        _inDaysRe,
        _enRelDayRe,
        _enNextWeekRe,
        _enInDaysRe,
        _enSlashDateRe,
        _enWeekRe,
      ]);
      if (m == null) break;
      final word = m.group(0)!;
      final day = _resolveDateMatch(m, now, ambiguities);
      // "今晚/明早…"紧跟时刻：记日期后把时段词转成标准词留给时刻解析。
      final carry = _periodCarry[word];
      final followedByTime = RegExp(
        r'\s*\d{1,2}\s*[点时]',
      ).hasMatch(text.substring(m.end));
      if (carry != null && followedByTime && day != null) {
        text = text.replaceRange(m.start, m.end, carry);
      } else {
        text = _blank(text, m);
      }
      // "日期…前"：截止语义标记（与时刻"…前"同义）。
      if (day != null && RegExp(r'^\s*前').hasMatch(text.substring(m.start))) {
        isDeadline = true;
      }
      if (day == null) continue;
      dateCount++;
      if (dateCount == 1) {
        dueDay = day;
      } else {
        ambiguities.add('第 $dateCount 个日期被忽略（仅取第一个）');
      }
    }

    // 5. 时刻：第一个生效；与日期合并为截止，否则视为今日提醒
    var timeCount = 0;
    int? hour;
    int? minute;
    while (true) {
      final m = _earliestMatch(text, [_zhTimeRe, _enTimeRe, _colonTimeRe]);
      if (m == null) break;
      final hm = _resolveTimeMatch(m);
      if (identical(m.pattern, _zhTimeRe) && m.group(0)!.contains('前')) {
        isDeadline = true;
      }
      text = _blank(text, m);
      if (hm == null) continue;
      timeCount++;
      if (timeCount == 1) {
        hour = hm.$1;
        minute = hm.$2;
      } else {
        ambiguities.add('第 $timeCount 个时刻被忽略（仅取第一个）');
      }
    }

    if (hour != null) {
      final dayBase = dueDay ?? epochDayOf(now); // 孤立时刻 → 今日提醒
      final base = dateFromEpochDay(dayBase);
      final at = DateTime(
        base.year,
        base.month,
        base.day,
        hour,
        minute ?? 0,
      ).millisecondsSinceEpoch;
      if (dueDay != null) {
        dueAtMs = at;
        reminderAtMs = at;
      } else {
        reminderAtMs = at;
        ambiguities.add('仅有时刻无日期：按今日提醒处理');
      }
    }

    // 6. 剩余文本为标题
    final title = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^[，。、,、.!！?？\s]+'), '')
        .replaceAll(RegExp(r'[，。、,、.!！?？\s]+$'), '');

    return ParsedCapture(
      title: title.isEmpty ? input.trim() : title,
      confidence: _confidence(
        hasDue: dueDay != null || dueAtMs != null,
        hasTime: dueAtMs != null,
        hasEstimate: estimateMinutes != null,
        hasEnergy: energy != null,
        hasTags: tags.isNotEmpty,
        hasProject: projectHint != null,
        ambiguityCount: ambiguities.length,
      ),
      dueDay: dueDay,
      dueAtMs: dueAtMs,
      reminderAtMs: reminderAtMs,
      estimateMinutes: estimateMinutes,
      energy: energy,
      tags: List.unmodifiable(tags),
      projectHint: projectHint,
      isDeadline: isDeadline,
      ambiguities: List.unmodifiable(ambiguities),
    );
  }

  // ---- 内部实现 ----

  RegExpMatch? _earliestMatch(String text, List<RegExp> patterns) {
    RegExpMatch? best;
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null && (best == null || m.start < best.start)) {
        best = m;
      }
    }
    return best;
  }

  int? _resolveDateMatch(
    RegExpMatch m,
    DateTime now,
    List<String> ambiguities,
  ) {
    final s = m.group(0)!.toLowerCase();
    final today = DateTime(now.year, now.month, now.day);

    if (_relDayRe.hasMatch(s) && _relDayOffset.containsKey(s)) {
      return epochDayOf(today.add(Duration(days: _relDayOffset[s]!)));
    }
    if (_enRelDayRe.hasMatch(s) && _relDayOffset.containsKey(s)) {
      return epochDayOf(today.add(Duration(days: _relDayOffset[s]!)));
    }
    if (s.startsWith('next ')) {
      final wd = _enWeekday[s.split(' ')[1].substring(0, 3)];
      return _weekOffsetDay(today, wd!, 1);
    }
    if (s.contains('天') && s.endsWith('后') || s.startsWith('in ')) {
      final n = int.parse(RegExp(r'(\d+)').firstMatch(s)!.group(1)!);
      return epochDayOf(today.add(Duration(days: n)));
    }
    if (s.contains('月')) {
      // 下个月X号
      final nm = RegExp('下个?月(\\d{1,2})[日号]').firstMatch(m.group(0)!);
      if (nm != null) {
        final day = int.parse(nm.group(1)!);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        return epochDayOf(DateTime(nextMonth.year, nextMonth.month, day));
      }
      final md = _monthDayRe.firstMatch(m.group(0)!)!;
      final month = int.parse(md.group(1)!);
      final day = int.parse(md.group(2)!);
      final y = now.year;
      var target = DateTime(y, month, day);
      if (target.isBefore(today)) {
        target = DateTime(y + 1, month, day);
        ambiguities.add('日期已过去：按明年解析');
      }
      return epochDayOf(target);
    }
    // 周几（中/英）
    final zhWeek = _weekDayRe.firstMatch(m.group(0)!);
    if (zhWeek != null) {
      final prefix = zhWeek.group(1) ?? '';
      final wd = _zhWeekday[zhWeek.group(2)!]!;
      final offset = switch (prefix) {
        '下下' || '下下个' => 2,
        '下' || '下个' => 1,
        _ => 0,
      };
      if (offset == 0) return _upcomingWeekday(today, wd);
      return _weekOffsetDay(today, wd, offset);
    }
    final enNext = RegExp(r'(mon|tue|wed|thu|fri|sat|sun)').firstMatch(s);
    if (enNext != null) {
      return _upcomingWeekday(today, _enWeekday[enNext.group(1)!]!);
    }
    final slash = _enSlashDateRe.firstMatch(m.group(0)!);
    if (slash != null) {
      final month = int.parse(slash.group(1)!);
      final day = int.parse(slash.group(2)!);
      var target = DateTime(now.year, month, day);
      if (target.isBefore(today)) {
        target = DateTime(now.year + 1, month, day);
        ambiguities.add('日期已过去：按明年解析');
      }
      return epochDayOf(target);
    }
    return null;
  }

  (int, int)? _resolveTimeMatch(RegExpMatch m) {
    final s = m.group(0)!.toLowerCase();
    if (s.contains('am') || s.contains('pm')) {
      final en = _enTimeRe.firstMatch(m.group(0)!)!;
      var h = int.parse(en.group(1)!);
      final min = int.tryParse(en.group(2) ?? '') ?? 0;
      final isPm = s.contains('pm');
      h = isPm ? (h % 12) + 12 : h % 12;
      return _validTime(h, min);
    }
    if (s.contains(':')) {
      final c = _colonTimeRe.firstMatch(m.group(0)!)!;
      return _validTime(int.parse(c.group(1)!), int.parse(c.group(2)!));
    }
    final zh = _zhTimeRe.firstMatch(m.group(0)!)!;
    var h = int.parse(zh.group(2)!);
    final min = zh.group(3) != null
        ? int.parse(zh.group(3)!)
        : (zh.group(4) == '半' ? 30 : 0);
    final period = zh.group(1);
    if (period != null) {
      const pmPeriods = {'午后', '下午', '傍晚', '晚上', '夜里'};
      if (pmPeriods.contains(period) && h < 12) h += 12;
      if (period == '凌晨' && h == 12) h = 0;
    }
    return _validTime(h, min);
  }

  (int, int)? _validTime(int h, int min) {
    if (h < 0 || h > 23 || min < 0 || min > 59) return null;
    return (h, min);
  }

  /// 本周或将来最近的一个 `weekday`（含今天）。
  int _upcomingWeekday(DateTime today, int weekday) {
    var delta = weekday - today.weekday;
    if (delta < 0) delta += 7;
    return epochDayOf(today.add(Duration(days: delta)));
  }

  /// 以周一为锚：weekOffset 周后的 `weekday`。
  int _weekOffsetDay(DateTime today, int weekday, int weekOffset) {
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return epochDayOf(monday.add(Duration(days: weekOffset * 7 + weekday - 1)));
  }

  double _confidence({
    required bool hasDue,
    required bool hasTime,
    required bool hasEstimate,
    required bool hasEnergy,
    required bool hasTags,
    required bool hasProject,
    required int ambiguityCount,
  }) {
    var c = 0.40;
    if (hasDue) c += 0.20;
    if (hasTime) c += 0.10;
    if (hasEstimate) c += 0.10;
    if (hasEnergy) c += 0.05;
    if (hasTags) c += 0.05;
    if (hasProject) c += 0.05;
    c -= 0.15 * ambiguityCount;
    return c.clamp(0.0, 0.95);
  }

  /// 把命中区间替换为空格，保留词边界。
  String _blank(String text, RegExpMatch m) =>
      text.replaceRange(m.start, m.end, ' ' * (m.end - m.start));
}
