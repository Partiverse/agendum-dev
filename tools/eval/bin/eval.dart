/// 黄金评估集 CLI（04 文档 §6.2）。
///
/// ```sh
/// dart run tools/eval/bin/eval.dart run --engine parse --min 0.75
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:agendum_eval/agendum_eval.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand(
      'run',
      ArgParser()
        ..addOption('engine', allowed: ['parse'], defaultsTo: 'parse')
        ..addOption('min', defaultsTo: '0.75', help: '用例级通过率门槛')
        ..addOption(
          'dir',
          defaultsTo: 'tools/golden/parse',
          help: '评估集目录（仓库根相对路径）',
        ),
    );

  final results = parser.parse(arguments);
  final cmd = results.command?.name;
  if (cmd != 'run') {
    stderr.writeln('用法: eval.dart run --engine parse --min 0.75 [--dir …]');
    exit(64);
  }
  final opts = results.command!;
  final minRate = double.tryParse(opts['min'] as String);
  if (minRate == null || minRate <= 0 || minRate > 1) {
    stderr.writeln('--min 须在 (0, 1] 内');
    exit(64);
  }

  final cases = loadCases(opts['dir'] as String);
  final CaptureAdapter adapter;
  switch (opts['engine'] as String) {
    case 'parse':
      adapter = LocalRuleAdapter();
    default:
      stderr.writeln('未知 engine: ${opts['engine']}');
      exit(64);
  }

  final report = runEval(cases, adapter);

  stdout.writeln('程簿黄金评估集 · ${opts['engine']} · adapter=${report.adapterName}');
  stdout.writeln(
    '用例级全字段通过: ${report.passedCases}/${report.totalCases}'
    ' (${(report.caseAccuracy * 100).toStringAsFixed(1)}%)',
  );
  stdout.writeln('字段命中率:');
  final names = report.fieldStats.keys.toList()..sort();
  for (final name in names) {
    final s = report.fieldStats[name]!;
    stdout.writeln(
      '  ${name.padRight(18)} ${s.matched.toString().padLeft(3)}/${s.total.toString().padLeft(3)}'
      ' ${(s.rate * 100).toStringAsFixed(1)}%',
    );
  }
  if (report.failures.isNotEmpty) {
    stdout.writeln('未通过用例:');
    for (final f in report.failures) {
      stdout.writeln('  ✗ $f');
    }
  }

  final pass = report.caseAccuracy >= minRate;
  stdout.writeln(
    '门槛 ${((minRate * 100).toStringAsFixed(1))}%: ${pass ? 'PASS' : 'FAIL'}',
  );
  exit(pass ? 0 : 1);
}
