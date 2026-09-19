import 'package:agendum_eval/agendum_eval.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:test/test.dart';

final class _FixedAdapter implements CaptureAdapter {
  _FixedAdapter(this._results);

  final Map<String, ParsedCapture> _results;
  var calls = 0;

  @override
  String get name => 'fixed-test';

  @override
  ParsedCapture parse(String input, DateTime now) {
    calls++;
    return _results[input]!;
  }
}

EvalCase caseOf(String id, String input, Map<String, Object?> expect) =>
    EvalCase(
      id: id,
      input: input,
      now: DateTime.parse('2026-09-19T09:00:00'),
      expect: expect,
      tags: const [],
    );

void main() {
  test('字段命中率与用例级通过率分开统计', () {
    final adapter = _FixedAdapter({
      'a': const ParsedCapture(
        title: 'X',
        confidence: 0.9,
        dueDay: 20000,
        energy: 'high',
      ),
      'b': const ParsedCapture(title: 'Y', confidence: 0.2),
    });
    final report = runEval([
      caseOf('a', 'a', {
        'due_date': '2024-10-04', // epochDayOf = 20000
        'energy': 'high',
      }),
      caseOf('b', 'b', {'energy': 'low'}),
    ], adapter);

    expect(adapter.calls, 2);
    expect(report.totalCases, 2);
    expect(report.passedCases, 1);
    expect(report.fieldStats['due_date']!.rate, 1.0);
    expect(report.fieldStats['energy']!.rate, 0.5);
    expect(report.failures.single, startsWith('b:'));
  });

  test('tags 无序相等', () {
    const r = ParsedCapture(title: 't', confidence: 1, tags: ['采购', '办公']);
    final adapter = _FixedAdapter({'t': r});
    final report = runEval([
      caseOf('t', 't', {
        'tags': ['办公', '采购'],
      }),
    ], adapter);
    expect(report.passedCases, 1);
  });

  test('本地规则适配器贯通 harness（冒烟）', () {
    final adapter = LocalRuleAdapter();
    final report = runEval([
      caseOf('smoke', '明天上午10点开团队会', {
        'due_date': '2026-09-20',
        'due_time': '10:00',
        'title_exact': '开团队会',
      }),
    ], adapter);
    expect(report.passedCases, 1);
    expect(report.caseAccuracy, 1.0);
  });

  test('负期望：null 表示字段应留空', () {
    const r = ParsedCapture(title: '处理收件箱', confidence: 0.4);
    final adapter = _FixedAdapter({'n': r});
    final report = runEval([
      caseOf('n', 'n', {
        'due_date': null,
        'due_time': null,
        'reminder_time': null,
        'estimate_minutes': null,
        'energy': null,
        'project_hint': null,
        'tags': null,
      }),
    ], adapter);
    expect(report.passedCases, 1);
  });

  test('负期望：字段被过度填充时判负', () {
    const r = ParsedCapture(title: 'x', confidence: 1, energy: 'high');
    final adapter = _FixedAdapter({'x': r});
    final report = runEval([
      caseOf('x', 'x', {'energy': null}),
    ], adapter);
    expect(report.passedCases, 0);
  });

  test('is_deadline 断言', () {
    const r = ParsedCapture(title: 'x', confidence: 1, isDeadline: true);
    final adapter = _FixedAdapter({'x': r});
    final report = runEval([
      caseOf('x', 'x', {'is_deadline': true}),
    ], adapter);
    expect(report.passedCases, 1);
  });

  test('分层通过率按标签聚合', () {
    final adapter = _FixedAdapter({
      'a': const ParsedCapture(title: 'a', confidence: 1),
      'b': const ParsedCapture(title: 'b', confidence: 1),
    });
    final c1 = EvalCase(
      id: 'a',
      input: 'a',
      now: DateTime.parse('2026-09-19T09:00:00'),
      expect: const {'title_exact': 'a'},
      tags: const ['rule_solvable', '对抗'],
    );
    final c2 = EvalCase(
      id: 'b',
      input: 'b',
      now: DateTime.parse('2026-09-19T09:00:00'),
      expect: const {'title_exact': 'WRONG'},
      tags: const ['needs_cloud'],
    );
    final report = runEval([c1, c2], adapter);
    final byTag = report.accuracyByTag();
    expect(byTag['rule_solvable'], 1.0);
    expect(byTag['对抗'], 1.0);
    expect(byTag['needs_cloud'], 0.0);
  });
}
