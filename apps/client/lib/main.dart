import 'package:flutter/material.dart';

import 'theme.dart';
import 'views/agendum_shell.dart';
import 'views/store.dart';

void main() {
  runApp(AgendumApp(store: TaskStore.withSeed()));
}

/// 样板入口：Things 级质感走查的载体（05 文档 W7–8）。
class AgendumApp extends StatelessWidget {
  const AgendumApp({super.key, required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '程簿 Agendum',
      debugShowCheckedModeBanner: false,
      theme: AgendumTheme.light(),
      darkTheme: AgendumTheme.dark(),
      home: AgendumShell(store: store),
    );
  }
}
