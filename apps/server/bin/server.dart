import 'dart:io';

import 'package:agendum_server/agendum_server.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final dbUrl = Platform.environment['DATABASE_URL'];
  final store = dbUrl == null || dbUrl.isEmpty
      ? MemorySyncStore()
      : await PgSyncStore.open(dbUrl);
  final server = await io.serve(
    buildHandler(store: store),
    InternetAddress.anyIPv4,
    port,
  );
  stdout.writeln(
    'agendum-server listening on ${server.port} '
    '(store=${store.runtimeType})',
  );
}
