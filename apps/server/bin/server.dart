import 'dart:io';

import 'package:agendum_server/agendum_server.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(buildHandler(), InternetAddress.anyIPv4, port);
  stdout.writeln('agendum-server listening on ${server.port}');
}
