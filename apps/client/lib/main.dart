import 'package:agendum_db/agendum_db.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'secure_key_store.dart';
import 'theme.dart';
import 'views/agendum_shell.dart';
import 'views/store.dart';

/// 同步服务端地址(构建期可覆盖:`--dart-define=AGENDUM_SERVER=…`)。
const _serverBase = String.fromEnvironment(
  'AGENDUM_SERVER',
  defaultValue: 'http://localhost:8090',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final support = await getApplicationSupportDirectory();
  final store = await TaskStore.open(
    executor: openNativeFileExecutor('${support.path}/agendum.sqlite3'),
    // 生产密钥存储:Keychain/libsecret;MK 不落 SQLite(R1 §2/§7)。
    keyStore: SecureStorageKeyStore(),
    // 演示种子只进 demo/测试(显式传 true);生产首启必须是干净的用户库。
    seedIfEmpty: false,
    serverBase: _serverBase,
  );
  runApp(AgendumApp(store: store));
}

/// 客户端入口:Things 级质感走查的载体(05 文档 W7–8)。
class AgendumApp extends StatelessWidget {
  const AgendumApp({
    super.key,
    required this.store,
    this.fontFamily,
    this.themeMode,
  });

  final TaskStore store;

  /// golden 走查注入系统 CJK 字体用(生产为 null 走平台默认)。
  final String? fontFamily;

  /// golden 走查强制明/暗色用(生产为 null 跟随系统)。
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '程簿 Agendum',
      debugShowCheckedModeBanner: false,
      theme: AgendumTheme.light(fontFamily: fontFamily),
      darkTheme: AgendumTheme.dark(fontFamily: fontFamily),
      themeMode: themeMode,
      home: AgendumShell(store: store),
    );
  }
}
