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
}
