/// 风格样板 widget 测试:捕获→解析→入库→完成的公理 1 闭环。
/// S05 起 store 由 Drift 内存库支撑(与生产同代码路径)。
library;

import 'dart:io';

import 'package:agendum_client/main.dart';
import 'package:agendum_client/views/store.dart';
import 'package:agendum_db/agendum_db.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(TaskStore store) => AgendumApp(store: store); // 主题跟随测试平台亮度

  Future<TaskStore> newStore({bool seed = false}) =>
      TaskStore.open(executor: NativeDatabase.memory(), seedIfEmpty: seed);

  testWidgets('捕获条输入自然语言 → 解析预览 → 回车入收件箱', (tester) async {
    final store = await newStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '买牛奶 明天 30分钟');
    await tester.pump();
    // 解析预览出现(真实 nlp 引擎):标题与时长 chip。
    expect(find.textContaining('30 分钟'), findsWidgets);
    expect(find.textContaining('→ 买牛奶'), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(store.inboxTasks.single.title, '买牛奶');
    expect(store.inboxTasks.single.estimateMinutes, 30);
    expect(find.text('买牛奶'), findsWidgets);
    await store.close();
  });

  testWidgets('点勾选完成 → 删除线；再点恢复（领域状态机）', (tester) async {
    final store = await newStore(seed: true);
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    // 在库内建一个纯净任务，避开 rich seed 遗留的 done 任务。
    await store.addManual('纯净测试任务');
    await tester.pumpAndSettle();
    final t = store.inboxTasks.firstWhere((x) => x.title == '纯净测试任务');
    expect(t.isDone, isFalse);
    await tester.tap(find.byKey(ValueKey('check-${t.id}')));
    await tester.pumpAndSettle();
    expect(store.byId(t.id).isDone, isTrue);
    expect(find.text(t.title), findsOneWidget); // 完成后保留在收件箱(删除线)

    await tester.tap(find.byKey(ValueKey('check-${t.id}')));
    await tester.pumpAndSettle();
    expect(store.byId(t.id).isDone, isFalse, reason: 'done → next 回退路径');
    await store.close();
  });

  testWidgets('今日视图显示"现在，做这件事"与种子任务', (tester) async {
    final store = await newStore(seed: true);
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    // 切到今日 tab（窄屏 NavigationBar）。
    await tester.tap(find.text('今日').last);
    await tester.pumpAndSettle();

    expect(find.text('现在，做这件事'), findsOneWidget);
    expect(find.text('给司机发合同'), findsOneWidget);
    expect(find.text('接下来'), findsOneWidget);
    await store.close();
  });

  testWidgets('宽屏使用 NavigationRail 切换视图', (tester) async {
    final store = await newStore(seed: true);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('今日').last);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('现在，做这件事'), findsOneWidget);
    await store.close();
  });

  test('SQLite 文件库重启后数据仍在(本地权威)', () async {
    final tmp = await Directory.systemTemp.createTemp('agendum_test');
    addTearDown(() => tmp.delete(recursive: true));
    final path = '${tmp.path}${Platform.pathSeparator}t.sqlite';

    final s1 = await TaskStore.open(executor: openNativeFileExecutor(path));
    await s1.addFromCapture(
      const ParsedCapture(title: '买牛奶', estimateMinutes: 15, confidence: 1),
    );
    await s1.close();

    final s2 = await TaskStore.open(executor: openNativeFileExecutor(path));
    expect(s2.inboxTasks.single.title, '买牛奶');
    expect(s2.inboxTasks.single.estimateMinutes, 15);
    await s2.close();
  });
}
