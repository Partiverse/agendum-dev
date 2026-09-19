/// 演示页静态服务（开发用；生产由 Web 层另行托管）。
///
/// ```sh
/// make demo   # = dart2js 编译 + 本服务
/// ```
library;

import 'dart:io';

const _contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.map': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
};

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8181;
  final webRoot = '${File.fromUri(Platform.script).parent.parent.path}/web';

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('程簿演示页: http://localhost:$port  （Ctrl-C 停止）');
  await for (final req in server) {
    try {
      var path = Uri.decodeComponent(req.uri.path);
      if (path == '/' || path.isEmpty) path = '/index.html';
      if (path.contains('..')) {
        req.response.statusCode = 400;
        await req.response.close();
        continue;
      }
      final file = File('$webRoot$path');
      if (!file.existsSync()) {
        req.response.statusCode = 404;
        await req.response.close();
        continue;
      }
      final ext = _extOf(file.path);
      req.response.headers.contentType = ContentType.parse(
        _contentTypes[ext] ?? 'application/octet-stream',
      );
      await req.response.addStream(file.openRead());
      await req.response.close();
    } catch (_) {
      req.response.statusCode = 500;
      await req.response.close();
    }
  }
}

String _extOf(String p) =>
    p.contains('.') ? p.substring(p.lastIndexOf('.')) : '';
