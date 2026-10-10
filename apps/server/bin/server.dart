import 'dart:io';

import 'package:agendum_server/agendum_server.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final dbUrl = Platform.environment['DATABASE_URL'];
  // R1 §6：信封存储与同步存储同源装配——PG 部署落 vault_envelopes 表,
  // 内存模式随进程生存（开发/演示用）。
  // ADR-016 §1：nonce 挑战表随部署形态——PG 部署用共享表（多实例负载均衡
  // 下单次有效,红线 2）;内存表仅在单实例/开发部署安全。
  final (
    SyncStore store,
    VaultEnvelopeStore envelopes,
    NonceStore nonces,
  ) = dbUrl == null || dbUrl.isEmpty
      ? (MemorySyncStore(), MemoryVaultEnvelopeStore(), NonceTable())
      : (
          await PgSyncStore.open(dbUrl),
          await PgVaultEnvelopeStore.open(dbUrl),
          await PgNonceStore.open(dbUrl),
        );
  final server = await io.serve(
    buildHandler(store: store, envelopes: envelopes, nonces: nonces),
    InternetAddress.anyIPv4,
    port,
  );
  stdout.writeln(
    'agendum-server listening on ${server.port} '
    '(store=${store.runtimeType}, envelopes=${envelopes.runtimeType}, '
    'nonces=${nonces.runtimeType})',
  );
}
