/// 交付走查 golden 渲染(加载系统苹方,真实渲染中文)。
/// 运行:`flutter test --update-goldens --no-skip test/golden_screens_test.dart`
/// 产物:`test/goldens/*.png`(人工走查用;CI 默认跳过,防跨平台渲染差异误报)。
@Skip('golden 走查产物,仅在 --update-goldens --no-skip 显式运行时生成/比对')
library;

import 'dart:io';
import 'dart:async';

import 'package:agendum_client/main.dart';
import 'package:agendum_client/views/store.dart';
import 'package:agendum_client/views/task_detail.dart';
import 'package:agendum_e2ee/agendum_e2ee.dart';
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

  Future<TaskStore> pump(WidgetTester tester, {bool dark = false}) async {
    final store = await TaskStore.open(
      executor: NativeDatabase.memory(),
      keyStore: InMemoryKeyStore(), // 测试走内存 KeyStore(R1 §7)
      seedIfEmpty: true,
    );
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1440, 1040);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AgendumApp(
        store: store,
        fontFamily: 'PingFang',
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> render(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('收件箱:捕获条 + 走查数据集', (tester) async {
    final store = await pump(tester);
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

  testWidgets('任务详情页:含标签区', (tester) async {
    final store = await pump(tester);
    // 选一个带标签的种子任务,让标签区在走查里可见。
    final task = store.inboxTasks.firstWhere(
      (t) => t.tags.isNotEmpty,
      orElse: () => store.inboxTasks.first,
    );
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(showTaskDetail(context, store, task.id));
    await tester.pumpAndSettle();
    await render(tester, '03-task-detail');
    await store.close();
  });

  testWidgets('项目视图:含项目与展开任务', (tester) async {
    final store = await pump(tester);
    await tester.tap(find.text('项目').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('杭州搬家').first);
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

  testWidgets('随时视图:拖拽排序面', (tester) async {
    final store = await pump(tester);
    await tester.tap(find.text('随时').first);
    await tester.pumpAndSettle();
    await render(tester, '06-anytime');
    await store.close();
  });

  testWidgets('回顾视图:近 7 天完成', (tester) async {
    final store = await pump(tester);
    await tester.tap(find.text('回顾').first);
    await tester.pumpAndSettle();
    await render(tester, '07-review');
    await store.close();
  });

  testWidgets('日志簿:全部完成', (tester) async {
    final store = await pump(tester);
    await tester.tap(find.text('日志').first);
    await tester.pumpAndSettle();
    await render(tester, '08-log');
    await store.close();
  });

  // ---- 暗色走查(05 文档 W7–8 暗色验收) ----

  testWidgets('暗色:收件箱', (tester) async {
    final store = await pump(tester, dark: true);
    await render(tester, 'dark-01-inbox');
    await store.close();
  });

  testWidgets('暗色:今日', (tester) async {
    final store = await pump(tester, dark: true);
    await tester.tap(find.text('今日').first);
    await tester.pumpAndSettle();
    await render(tester, 'dark-02-today');
    await store.close();
  });

  testWidgets('暗色:任务详情页', (tester) async {
    final store = await pump(tester, dark: true);
    final task = store.inboxTasks.firstWhere(
      (t) => t.tags.isNotEmpty,
      orElse: () => store.inboxTasks.first,
    );
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(showTaskDetail(context, store, task.id));
    await tester.pumpAndSettle();
    await render(tester, 'dark-03-task-detail');
    await store.close();
  });
}
