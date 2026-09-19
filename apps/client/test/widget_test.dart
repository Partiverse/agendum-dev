/// 风格样板 widget 测试：捕获→解析→入库→完成的公理 1 闭环。
library;

import 'package:agendum_client/main.dart';
import 'package:agendum_client/views/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(TaskStore store) => AgendumApp(store: store); // 主题跟随测试平台亮度

  testWidgets('捕获条输入自然语言 → 解析预览 → 回车入收件箱', (tester) async {
    final store = TaskStore();
    await tester.pumpWidget(app(store));

    await tester.enterText(find.byType(TextField), '买牛奶 明天 30分钟');
    await tester.pump();
    // 解析预览出现（真实 nlp 引擎）：标题与时长 chip。
    expect(find.textContaining('30 分钟'), findsWidgets);
    expect(find.textContaining('→ 买牛奶'), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(store.inboxTasks.single.title, '买牛奶');
    expect(store.inboxTasks.single.estimateMinutes, 30);
    expect(find.text('买牛奶'), findsWidgets);
  });

  testWidgets('点击任务行完成 → 删除线；再点恢复（领域状态机）', (tester) async {
    final store = TaskStore.withSeed();
    await tester.pumpWidget(app(store));

    final t = store.inboxTasks.single; // '读《搞定Ⅰ》第 2 章'
    expect(t.isDone, isFalse);
    await tester.tap(find.text(t.title));
    await tester.pump();
    expect(t.isDone, isTrue);

    await tester.tap(find.text(t.title));
    await tester.pump();
    expect(t.isDone, isFalse, reason: 'done → next 回退路径');
  });

  testWidgets('今日视图显示"现在，做这件事"与种子任务', (tester) async {
    final store = TaskStore.withSeed();
    await tester.pumpWidget(app(store));

    // 切到今日 tab（窄屏 NavigationBar）。
    await tester.tap(find.text('今日').last);
    await tester.pumpAndSettle();

    expect(find.text('现在，做这件事'), findsOneWidget);
    expect(find.text('给司机发合同'), findsOneWidget);
    expect(find.text('接下来'), findsOneWidget);
  });

  testWidgets('宽屏使用 NavigationRail 切换视图', (tester) async {
    final store = TaskStore.withSeed();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(store));

    await tester.tap(find.text('今日').last);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('现在，做这件事'), findsOneWidget);
  });
}
