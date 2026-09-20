/// S06 七视图导航骨架 + 键盘流 v1(⌘N 新建、⏎ 完成、⌫ 入收件箱)。
library;

import 'package:agendum_client/main.dart';
import 'package:agendum_client/views/store.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<TaskStore> newStore({bool seed = false}) =>
      TaskStore.open(executor: NativeDatabase.memory(), seedIfEmpty: seed);

  // 七个目的地的 rail 标签按序切换(宽屏测试面 800x600 出 NavigationRail)。
  Future<void> goTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
  }

  // IndexedStack 非活动子树默认被 finder 跳过:捕获条在收件箱页,需关掉 skipOffstage。
  TextField captureField(WidgetTester tester) => tester.widget<TextField>(
    find.byType(TextField, skipOffstage: false).first,
  );

  testWidgets('七视图导航骨架:七个目的地均可切换且空态可见', (tester) async {
    final store = await newStore();
    await tester.pumpWidget(AgendumApp(store: store));
    await tester.pumpAndSettle();

    for (final entry in {
      '计划': '近期没有带日期的任务',
      '随时': '随时可做的事都清空了',
      '回顾': '这周还没有完成记录',
      '日志': '日志簿还是空的',
    }.entries) {
      await goTab(tester, entry.key);
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
    }
    await goTab(tester, '项目');
    expect(find.textContaining('还没有项目'), findsOneWidget);
    await store.close();
  });

  testWidgets('⌘N 从任意视图聚焦收件箱捕获条', (tester) async {
    final store = await newStore();
    await tester.pumpWidget(AgendumApp(store: store));
    await tester.pumpAndSettle();

    await goTab(tester, '日志');
    expect(captureField(tester).focusNode!.hasFocus, isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(
      captureField(tester).focusNode!.hasFocus,
      isTrue,
      reason: '⌘N 应聚焦捕获条',
    );
    await store.close();
  });

  testWidgets('键盘流:⏎ 完成聚焦行,⌫ 回收进收件箱', (tester) async {
    final store = await newStore(seed: true);
    await tester.pumpWidget(AgendumApp(store: store));
    await tester.pumpAndSettle();

    // rich seed 的今日透视含已完成任务(createdAt 倒序在前),取首个活跃任务。
    final nextTask = store.todayTasks.firstWhere((t) => !t.isDone);
    await goTab(tester, '今日');

    // ⏎ 完成。
    tester
        .widget<Focus>(find.byKey(ValueKey('row-focus-${nextTask.id}')))
        .focusNode!
        .requestFocus();
    await tester.pump(); // 让 focus 稳定后再发按键事件
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(store.byId(nextTask.id).isDone, isTrue);

    // ⌫ 入收件箱(done → inbox 回退路径)。
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump(); // 让 moveToInbox 微任务完成
    await tester.pumpAndSettle();
    expect(store.byId(nextTask.id).status.value, 'inbox');
    expect(
      store.inboxTasks.any((t) => t.id == nextTask.id),
      isTrue,
      reason: '⌫ 后任务应出现在收件箱',
    );
    await store.close();
  });

  testWidgets('项目视图:内联建项目 → 任务挂入项目展开可见', (tester) async {
    final store = await newStore();
    await tester.pumpWidget(AgendumApp(store: store));
    await tester.pumpAndSettle();

    await store.addFromCapture(ParsedCapture(title: '选瓷砖', confidence: 0));
    await tester.pumpAndSettle();
    final task = store.inboxTasks.single;

    await goTab(tester, '项目');
    await tester.enterText(find.byType(TextField).first, '装修');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(store.projectList.single.name, '装修');

    await tester.tap(find.text('装修'));
    await tester.pumpAndSettle();
    await store.setTaskProject(task.id, store.projectList.single.id);
    await tester.pumpAndSettle();
    expect(store.projectList.single.openCount, 1);
    expect(find.text('选瓷砖'), findsOneWidget);
    await store.close();
  });

  testWidgets('收件箱拖拽排序:长按拖动写回 sort_key,顺序持久', (tester) async {
    final store = await newStore();
    await tester.pumpWidget(AgendumApp(store: store));
    await tester.pumpAndSettle();

    for (final title in ['甲', '乙', '丙']) {
      await store.addFromCapture(ParsedCapture(title: title, confidence: 0));
    }
    await tester.pumpAndSettle();
    // 头插语义:新任务在最上 → 丙/乙/甲。
    expect(store.inboxTasks.map((t) => t.title), ['丙', '乙', '甲']);

    // 长按首行(丙)进入拖拽,向下拖过其余两行。
    final firstRow = find.byKey(
      ValueKey('reorder-${store.inboxTasks.first.id}'),
    );
    final gesture = await tester.startGesture(tester.getCenter(firstRow));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(store.inboxTasks.length, 3);
    expect(
      store.inboxTasks.first.title,
      isNot('丙'),
      reason: '丙 拖离首位后应由 乙 或 甲 占首位',
    );
    await store.close();
  });
}
