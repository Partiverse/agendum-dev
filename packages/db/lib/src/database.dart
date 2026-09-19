/// 本地数据库入口(迁移策略随 schema 版本演进:v1 tasks+同步基建,v2 +areas/projects)。
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tasks, Areas, Projects, Oplog, SyncState, FieldLamport])
class AgendumDatabase extends _$AgendumDatabase {
  AgendumDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(areas);
        await m.createTable(projects);
      }
    },
  );
}

/// 内存库(测试/演示用,随进程销毁)。
AgendumDatabase openInMemoryDb() => AgendumDatabase(NativeDatabase.memory());

/// 文件库执行器(客户端主入口用):后台 isolate 执行,懒打开。
QueryExecutor openNativeFileExecutor(String path) => LazyDatabase(() async {
  final file = File(path);
  await file.parent.create(recursive: true);
  return NativeDatabase.createInBackground(file);
});
