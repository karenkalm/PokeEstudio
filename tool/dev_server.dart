// Servidor de desarrollo local de PokéStudio.
//
// Compila la versión web y la sirve en http://localhost:8642 para probarla
// en el navegador. Solo escucha en la propia computadora (127.0.0.1) y solo
// ejecuta una lista fija de comandos de Flutter:
//
//   GET  /__dev/status          → estado de la última tarea (JSON)
//   GET  /__dev/log             → salida de la última tarea (texto)
//   POST /__dev/run?cmd=build   → setup | pub | build | analyze | test
//                                 (con el encabezado x-pokestudio-dev: 1)
//
// La salida y el estado también se guardan en `dev_server.log` y
// `dev_server_status.json`, junto a este proyecto (ignorados por git).
//
// Se inicia con `PokeStudio-dev.bat` (doble clic) y se cierra cerrando la
// ventana. No forma parte de la app.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Primer puerto que se intenta; si está ocupado se prueban los siguientes.
const int firstPort = 8642;
int port = firstPort;

final String flutter = Platform.environment['POKESTUDIO_FLUTTER'] ?? 'flutter';

const Map<String, List<List<String>>> commands = <String, List<List<String>>>{
  'setup': <List<String>>[
    <String>['create', '.', '--platforms=web', '--project-name', 'pokestudio'],
    <String>['pub', 'get'],
  ],
  'pub': <List<String>>[
    <String>['pub', 'get'],
  ],
  'build': <List<String>>[
    <String>['build', 'web', '--release', '--pwa-strategy=none', '--no-wasm-dry-run'],
  ],
  'analyze': <List<String>>[
    <String>['analyze', '--no-fatal-infos', '--no-fatal-warnings'],
  ],
  'test': <List<String>>[
    <String>['test', '--reporter', 'expanded'],
  ],
};

const Map<String, String> mimeTypes = <String, String>{
  'html': 'text/html; charset=utf-8',
  'js': 'text/javascript; charset=utf-8',
  'mjs': 'text/javascript; charset=utf-8',
  'json': 'application/json; charset=utf-8',
  'css': 'text/css; charset=utf-8',
  'wasm': 'application/wasm',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'gif': 'image/gif',
  'svg': 'image/svg+xml',
  'ico': 'image/x-icon',
  'ttf': 'font/ttf',
  'otf': 'font/otf',
  'woff': 'font/woff',
  'woff2': 'font/woff2',
  'wav': 'audio/wav',
  'ogg': 'audio/ogg',
  'mp3': 'audio/mpeg',
  'txt': 'text/plain; charset=utf-8',
  'map': 'application/json; charset=utf-8',
};

final StringBuffer _log = StringBuffer();
Map<String, Object?> _status = <String, Object?>{'state': 'idle'};

/// Estado con la dirección actual (para saber en qué puerto quedó).
Map<String, Object?> _statusJson() =>
    <String, Object?>{..._status, 'url': 'http://localhost:$port', 'busy': _busy, 'queue': _queue};
bool _busy = false;
final List<String> _queue = <String>[];

final File _logFile = File('dev_server.log');
final File _statusFile = File('dev_server_status.json');
bool _dirty = true;

/// Copia el registro y el estado a disco (cada 2 s si hubo cambios).
void _flushToDisk() {
  if (!_dirty) return;
  _dirty = false;
  try {
    _logFile.writeAsStringSync(_log.toString());
    _statusFile.writeAsStringSync(jsonEncode(_statusJson()));
  } on Object catch (error) {
    stdout.writeln('  (no se pudo escribir el registro: $error)');
  }
}

Future<void> main() async {
  Timer.periodic(const Duration(seconds: 2), (_) => _flushToDisk());
  HttpServer? server;
  for (var candidate = firstPort; candidate < firstPort + 10 && server == null; candidate++) {
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, candidate);
      port = candidate;
    } on SocketException {
      // Puerto ocupado (otra ventana del servidor u otro programa): se prueba el siguiente.
    }
  }
  if (server == null) {
    stdout.writeln('No se encontró un puerto libre entre $firstPort y ${firstPort + 9}.');
    _status = <String, Object?>{'state': 'error', 'message': 'sin puerto libre'};
    _flushToDisk();
    exit(1);
  }
  stdout.writeln('');
  stdout.writeln('  PokéStudio · servidor de desarrollo');
  stdout.writeln('  App:     http://localhost:$port');
  stdout.writeln('  Flutter: $flutter');
  stdout.writeln('  Cierra esta ventana para detenerlo.');
  stdout.writeln('');
  server.listen(_handle);
  _enqueue(<String>['setup', 'build']);
}

void _enqueue(List<String> names) {
  _queue.addAll(names.where(commands.containsKey));
  _dirty = true;
  if (!_busy) unawaited(_drain());
}

Future<void> _drain() async {
  _busy = true;
  while (_queue.isNotEmpty) {
    await _run(_queue.removeAt(0));
  }
  _busy = false;
}

Future<void> _run(String name) async {
  final started = DateTime.now();
  _log
    ..clear()
    ..writeln('== $name (${started.toIso8601String()})');
  _status = <String, Object?>{'state': 'running', 'command': name, 'startedAt': started.toIso8601String()};
  _dirty = true;
  stdout.writeln('> $name…');
  var exitCode = 0;
  for (final args in commands[name]!) {
    _log.writeln('\$ flutter ${args.join(' ')}');
    try {
      final process = await Process.start(flutter, args, runInShell: true, workingDirectory: Directory.current.path);
      final out = process.stdout.transform(const Utf8Decoder(allowMalformed: true)).listen(_append).asFuture<void>();
      final err = process.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen(_append).asFuture<void>();
      exitCode = await process.exitCode;
      await Future.wait(<Future<void>>[out, err]).timeout(const Duration(seconds: 5), onTimeout: () => <void>[]);
    } on Object catch (error) {
      _append('\nNo se pudo ejecutar Flutter ($flutter): $error\n');
      exitCode = -1;
    }
    if (exitCode != 0) break;
  }
  final finished = DateTime.now();
  _status = <String, Object?>{
    'state': exitCode == 0 ? 'ok' : 'error',
    'command': name,
    'exitCode': exitCode,
    'startedAt': started.toIso8601String(),
    'finishedAt': finished.toIso8601String(),
    'seconds': finished.difference(started).inSeconds,
    'queued': List<String>.of(_queue),
  };
  _dirty = true;
  _flushToDisk();
  stdout.writeln('  $name → ${exitCode == 0 ? 'listo' : 'error ($exitCode)'} en ${finished.difference(started).inSeconds} s');
}

void _append(String text) {
  _log.write(text);
  _dirty = true;
  if (_log.length > 400000) {
    final keep = _log.toString().substring(_log.length - 300000);
    _log
      ..clear()
      ..write(keep);
  }
}

Future<void> _handle(HttpRequest request) async {
  final response = request.response;
  response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
  try {
    final path = request.uri.path;
    if (path == '/__dev/status') {
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode(_statusJson()));
    } else if (path == '/__dev/log') {
      response.headers.contentType = ContentType.text;
      response.write(_log.toString());
    } else if (path == '/__dev/run' && request.method == 'POST' && request.headers.value('x-pokestudio-dev') == '1') {
      // El encabezado propio impide que otras páginas del navegador disparen
      // compilaciones (requeriría una verificación CORS que aquí no se acepta).
      final names = (request.uri.queryParameters['cmd'] ?? '').split(',').map((s) => s.trim()).toList();
      _enqueue(names);
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode(<String, Object?>{'queued': _queue, 'busy': _busy}));
    } else {
      await _serveFile(path, response);
    }
  } on Object catch (error) {
    response.statusCode = HttpStatus.internalServerError;
    response.write('$error');
  }
  await response.close();
}

Future<void> _serveFile(String path, HttpResponse response) async {
  final root = Directory('build/web');
  var relative = Uri.decodeComponent(path);
  if (relative.endsWith('/')) relative = '${relative}index.html';
  if (relative.contains('..')) {
    response.statusCode = HttpStatus.forbidden;
    return;
  }
  var file = File('${root.path}$relative');
  if (!file.existsSync()) {
    if (!File('${root.path}/index.html').existsSync()) {
      response.headers.contentType = ContentType.html;
      response.write('<meta charset="utf-8"><body style="font-family:sans-serif;padding:2rem;background:#FFF7E8">'
          '<h2>PokéStudio se está compilando…</h2><p>Estado: ${const HtmlEscape().convert(jsonEncode(_status))}</p>'
          '<script>setTimeout(()=>location.reload(),4000)</script>');
      return;
    }
    file = File('${root.path}/index.html');
  }
  final extension = file.path.split('.').last.toLowerCase();
  response.headers.set(HttpHeaders.contentTypeHeader, mimeTypes[extension] ?? 'application/octet-stream');
  await response.addStream(file.openRead());
}
