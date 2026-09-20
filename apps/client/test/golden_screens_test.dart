/// 交付走查 golden 渲染(加载系统苹方,真实渲染中文)。
/// 运行:`flutter test --update-goldens test/golden_screens_test.dart`
/// 产物:`test/goldens/*.png`(人工走查用;CI 默认跳过,防跨平台渲染差异误报)。
@Skip('golden 走查产物,仅在 --update-goldens 显式运行时生成/比对')
library;

import 'dart:io';
import 'dart:async';

import 'package:agendum_client/main.dart';
import 'package:agendum_client/views/store.dart';
import 'package:agendum_client/views/task_detail.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 注册系统 CJK 字体(测试默认 Ahem 无中文字形,渲染出来全是色块)。
Future<void> _loadSystemFonts() async {
  final icon = File(
    '/Users/nebulaboratories/flutter-sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icon.existsSync()) {
    final bytes = icon.readAsBytesSync();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  }
  final candidates = [
    '/System/Library/Fonts/PingFang.ttc',
    '/System/Library/Fonts/Hiragino Sans GB.ttc',
    '/System/Library/Fonts/Supplemental/Songti.ttc',
    '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
  ];
  for (final path in candidates) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final bytes = f.readAsBytesSync();
    final loader = FontLoader('PingFang')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
    return;
  }
}

void main() {
  setUpAll(_loadSystemFonts);

  Future<TaskStore> pump(WidgetTester tester) async {
    final store = await TaskStore.open(
      executor: NativeDatabase.memory(),
      seedIfEmpty: true,
    );
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1440, 1040);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AgendumApp(store: store, fontFamily: 'PingFang'));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> render(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('收件箱:捕获条 + 种子任务', (tester) async {
    final store = await pump(tester);
    await store.addFromCapture(
      ParsedCapture(title: '给医生诊所打电话改约', confidence: 0),
    );
    await tester.pumpAndSettle();
    await render(tester, '01-inbox');
    await store.close();
  });

  testWidgets('今日:现在做这件事', (tester) async {
    final store = await pump(tester);
    await tester.tap(find.text('今日').first);
    await tester.pumpAndSettle();
    await render(tester, '02-today');
    await store.close();
  });

  testWidgets('任务详情页', (tester) async {
    final store = await pump(tester);
    final task = store.inboxTasks.first;
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(showTaskDetail(context, store, task.id));
    await tester.pumpAndSettle();
    await render(tester, '03-task-detail');
    await store.close();
  });

  testWidgets('项目视图:含项目与展开任务', (tester) async {
    final store = await pump(tester);
    await store.addProject('程簿 1.0 发布');
    final t = store.inboxTasks.first;
    await store.setTaskProject(t.id, store.projectList.single.id);
    await tester.pumpAndSettle();
    await tester.tap(find.text('项目').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('程簿 1.0 发布'));
    await tester.pumpAndSettle();
    await render(tester, '04-projects');
    await store.close();
  });

  testWidgets('计划视图', (tester) async {
    final store = await pump(tester);
    await tester.tap(find.text('计划').first);
    await tester.pumpAndSettle();
    await render(tester, '05-plan');
    await store.close();
  });
}
