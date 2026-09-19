/// 评估集加载、执行与报告（04 文档 §6）。
///
/// 用例 YAML 格式（tools/golden/parse/*.yaml）：
/// ```yaml
/// id: zh-001
/// now: "2026-09-19T09:00:00"     # 可选；缺省用真实时钟
/// input: "下周三下午3点前给司机发合同 30min !高精力"
/// expect:
///   due_date: "2026-09-23"       # YYYY-MM-DD
///   due_time: "15:00"            # HH:mm（来自 dueAt）
///   reminder_time: "15:00"
///   estimate_minutes: 30
///   energy: high
///   tags: [采购]
///   project_hint: 程簿
///   title_contains: "给司机发合同"
///   title_exact: "给司机发合同"
///   ambiguities_min: 1
/// tags: [zh, date]
/// ```
library;

import 'dart:io';

import 'package:agendum_domain/agendum_domain.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:yaml/yaml.dart';

import 'adapter.dart';

final class EvalCase {
  EvalCase({
    required this.id,
    required this.input,
    required this.now,
    required this.expect,
    required this.tags,
  });

  final String id;
  final String input;
  final DateTime now;
  final Map<String, Object?> expect;
  final List<String> tags;
}

final class FieldStat {
  FieldStat(this.name) : matched = 0, total = 0;

  final String name;
  int matched;
  int total;

  double get rate => total == 0 ? 1 : matched / total;
}

final class EvalReport {
  EvalReport({
    required this.adapterName,
    required this.totalCases,
    required this.passedCases,
    required this.fieldStats,
    required this.failures,
  });

  final String adapterName;
  final int totalCases;
  final int passedCases;
  final Map<String, FieldStat> fieldStats;
  final List<String> failures;

  double get caseAccuracy => totalCases == 0 ? 1 : passedCases / totalCases;
}

/// 从目录加载 `*.yaml` 用例；目录为空或字段缺失抛 FormatException。
List<EvalCase> loadCases(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    throw FormatException('评估集目录不存在: $dirPath');
  }
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));
  final cases = <EvalCase>[];
  for (final f in files) {
    final doc = loadYaml(f.readAsStringSync());
    if (doc is! Map) {
      throw FormatException('${f.path}: 根节点须为映射');
    }
    final id = doc['id'];
    final input = doc['input'];
    if (id is! String || input is! String) {
      throw FormatException('${f.path}: 缺少 id/input');
    }
    final expectRaw = doc['expect'];
    if (expectRaw is! Map || expectRaw.isEmpty) {
      throw FormatException('${f.path}: 缺少非空 expect');
    }
    final nowRaw = doc['now'];
    cases.add(
      EvalCase(
        id: id,
        input: input,
        now: nowRaw is String ? DateTime.parse(nowRaw) : DateTime.now(),
        expect: expectRaw.map((k, v) => MapEntry(k.toString(), _plain(v))),
        tags: [
          if (doc['tags'] case final t as List) ...t.map((e) => e.toString()),
        ],
      ),
    );
  }
  if (cases.isEmpty) throw FormatException('$dirPath 中没有用例');
  return cases;
}

Object? _plain(Object? v) => switch (v) {
  final YamlList l => l.map(_plain).toList(),
  final YamlMap m => m.map((k, v) => MapEntry(k.toString(), _plain(v))),
  _ => v,
};

/// 执行评估。字段命中率与用例级"全字段通过率"分开统计
/// （04 文档 §6.2：解析类用字段精确匹配）。
EvalReport runEval(List<EvalCase> cases, CaptureAdapter adapter) {
  final stats = <String, FieldStat>{};
  var passed = 0;
  final failures = <String>[];
  for (final c in cases) {
    final r = adapter.parse(c.input, c.now);
    var allOk = true;
    for (final e in c.expect.entries) {
      final stat = stats.putIfAbsent(e.key, () => FieldStat(e.key));
      stat.total++;
      final ok = _check(e.key, e.value, r);
      if (ok) {
        stat.matched++;
      } else {
        allOk = false;
      }
    }
    if (allOk) {
      passed++;
    } else {
      failures.add('${c.id}: ${_describe(c, r)}');
    }
  }
  return EvalReport(
    adapterName: adapter.name,
    totalCases: cases.length,
    passedCases: passed,
    fieldStats: stats,
    failures: failures,
  );
}

bool _check(String field, Object? expected, ParsedCapture r) => switch (field) {
  'due_date' => _epochDay(expected as String) == r.dueDay,
  'due_time' => _hm(r.dueAtMs) == expected,
  'reminder_time' => _hm(r.reminderAtMs) == expected,
  'estimate_minutes' => r.estimateMinutes == (expected as num).toInt(),
  'energy' => r.energy == expected,
  'tags' => _listEquals(expected as List<Object?>, r.tags),
  'project_hint' => r.projectHint == expected,
  'title_contains' => r.title.contains(expected as String),
  'title_exact' => r.title == expected,
  'ambiguities_min' => r.ambiguities.length >= (expected as num).toInt(),
  _ => throw FormatException('未知 expect 字段: $field'),
};

bool _listEquals(List<Object?> a, List<Object?> b) {
  final sa = a.map((e) => e.toString()).toList()..sort();
  final sb = b.map((e) => e.toString()).toList()..sort();
  if (sa.length != sb.length) return false;
  for (var i = 0; i < sa.length; i++) {
    if (sa[i] != sb[i]) return false;
  }
  return true;
}

int _epochDay(String isoDay) => epochDayOf(DateTime.parse('$isoDay 00:00:00'));

String? _hm(int? msSinceEpoch) {
  if (msSinceEpoch == null) return null;
  final d = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
  return '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

String _describe(EvalCase c, ParsedCapture r) =>
    'input="${c.input}" → title="${r.title}" dueDay=${r.dueDay} '
    'dueAt=${r.dueAtMs} estimate=${r.estimateMinutes} energy=${r.energy} '
    'tags=${r.tags} project=${r.projectHint} amb=${r.ambiguities}';
