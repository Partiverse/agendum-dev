/// S07 任务详情页:点行打开、改标题/备注、精力、挂项目、状态流转与红线提示。
library;

import 'package:agendum_client/main.dart';
import 'package:agendum_client/views/store.dart';
import 'package:agendum_client/views/task_detail.dart';
import 'package:agendum_nlp/agendum_nlp.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<TaskStore> pumpApp(WidgetTester tester, {bool seed = false}) async {
    final store = await TaskStore.open(
      executor: NativeDatabase.memory(),
      seedIfEmpty: seed,
    );
    await tester.pumpWidget(AgendumApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  // sheet 是后挂的 route,树遍历在其后;标题/备注/捕获条都是 TextField,
  // 必须限定在 TaskDetailSheet 子树内取。
  Finder sheetField(WidgetTester tester, int index) => find
      .descendant(
        of: find.byType(TaskDetailSheet),
        matching: find.byType(TextField),
      )
      .at(index);

  testWidgets('点行打开详情;改标题即存', (tester) async {
    final store = await pumpApp(tester);
    await store.addFromCapture(ParsedCapture(title: '买牛奶', confidence: 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('买牛奶'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailSheet), findsOneWidget);

    await tester.enterText(sheetField(tester, 0), '买两瓶鲜奶');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(store.byId(store.inboxTasks.single.id).title, '买两瓶鲜奶');
    await store.close();
  });

  testWidgets('精力分段控件即改即存', (tester) async {
    final store = await pumpApp(tester);
    await store.addFromCapture(ParsedCapture(title: '深度写作', confidence: 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('深度写作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('高').last);
    await tester.pumpAndSettle();
    expect(store.inboxTasks.single.energy, 'high');

    await tester.tap(find.text('无').last);
    await tester.pumpAndSettle();
    expect(store.inboxTasks.single.energy, isNull);
    await store.close();
  });

  testWidgets('状态 chips 走领域状态机;非法流转弹 SnackBar', (tester) async {
    final store = await pumpApp(tester, seed: true);
    final task = store.inboxTasks.single;

    await tester.tap(find.text(task.title));
    await tester.pumpAndSettle();

    // 收件箱 → 等待:允许。
    await tester.tap(find.text('等待').last);
    await tester.pumpAndSettle();
    expect(store.byId(task.id).status.value, 'waiting');

    // waiting → 收件箱:不在流转表,弹提示且状态不变。
    await tester.tap(find.text('收件箱').last);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(store.byId(task.id).status.value, 'waiting');

    // waiting → 下一步:允许。
    await tester.tap(find.text('下一步').last);
    await tester.pumpAndSettle();
    expect(store.byId(task.id).status.value, 'next');
    await store.close();
  });

  testWidgets('挂项目:下拉选择后 store 记录 project_id', (tester) async {
    final store = await pumpApp(tester);
    await store.addProject('装修');
    await store.addFromCapture(ParsedCapture(title: '选瓷砖', confidence: 0));
    final task = store.inboxTasks.single;
    await tester.pumpAndSettle();

    await tester.tap(find.text('选瓷砖'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('无项目').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('装修').last);
    await tester.pumpAndSettle();

    expect(store.byId(task.id).projectId, store.projectList.single.id);
    await store.close();
  });
}
