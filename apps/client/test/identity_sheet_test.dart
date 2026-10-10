/// 身份面板实机回归:点钥匙图标 → 面板打开 → 显示恢复短语(实机发现的
/// null check 崩溃在此复现定位)。
library;

import 'package:agendum_client/main.dart';
import 'package:agendum_client/views/store.dart';
import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('身份面板:打开 → 显示恢复短语 → 12 词可见', (tester) async {
    final store = await TaskStore.open(
      executor: NativeDatabase.memory(),
      keyStore: InMemoryKeyStore(),
      autoSync: false,
    );
    addTearDown(store.close);

    await tester.pumpWidget(AgendumApp(store: store));
    await tester.pump();

    await tester.tap(byTooltip('身份与恢复'));
    await tester.pumpAndSettle();

    expect(find.text('身份与恢复'), findsWidgets);
    expect(find.text('显示恢复短语'), findsOneWidget);

    await tester.tap(find.text('显示恢复短语'));
    await tester.pumpAndSettle();

    final phrase = store.recoveryPhrase!;
    expect(phrase.split(' '), hasLength(12), reason: 'BIP39 12 词');
    expect(find.textContaining(phrase.split(' ').first), findsOneWidget);
  });
}

Finder byTooltip(String message) => find.byTooltip(message);
