import 'dart:collection';
import 'dart:convert';
import 'dart:io';

/// Un JSON guardado junto con el momento en que se guardó.
class CachedJson {
  const CachedJson({required this.data, required this.savedAt});

  final Map<String, dynamic> data;
  final DateTime savedAt;

  bool isFresh(Duration maxAge, DateTime now) => now.difference(savedAt) <= maxAge;
}

/// Caché de respuestas JSON en dos niveles: memoria (LRU) y disco.
///
/// * La memoria evita releer archivos mientras la app está abierta.
/// * El disco permite consultar fichas ya vistas sin conexión.
///
/// Si no se indica [directory] (por ejemplo en pruebas), solo usa memoria.
class JsonCache {
  JsonCache({this.directory, this.memoryCapacity = 160, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Directory? directory;
  final int memoryCapacity;
  final DateTime Function() _clock;

  final LinkedHashMap<String, CachedJson> _memory = LinkedHashMap<String, CachedJson>();
  int _tmpCounter = 0;

  DateTime now() => _clock();

  /// Devuelve la entrada guardada para [key], fresca o no. Quien llama decide
  /// si le sirve según su vigencia.
  Future<CachedJson?> read(String key) async {
    final inMemory = _memory.remove(key);
    if (inMemory != null) {
      _memory[key] = inMemory; // la mueve al final (más reciente)
      return inMemory;
    }
    final file = _fileFor(key);
    if (file == null) return null;
    try {
      if (!await file.exists()) return null;
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final savedAtMs = raw['savedAt'];
      final data = raw['data'];
      if (savedAtMs is! int || data is! Map<String, dynamic>) return null;
      final entry = CachedJson(
        data: data,
        savedAt: DateTime.fromMillisecondsSinceEpoch(savedAtMs),
      );
      _remember(key, entry);
      return entry;
    } on Object {
      // Un archivo dañado no debe romper la app: se ignora y se descarga de nuevo.
      return null;
    }
  }

  Future<void> write(String key, Map<String, dynamic> data) async {
    final entry = CachedJson(data: data, savedAt: _clock());
    _remember(key, entry);
    final file = _fileFor(key);
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      final tmp = File('${file.path}.${_tmpCounter++}.tmp');
      await tmp.writeAsString(
        jsonEncode(<String, Object?>{
          'savedAt': entry.savedAt.millisecondsSinceEpoch,
          'data': data,
        }),
        flush: true,
      );
      await tmp.rename(file.path); // reemplazo atómico
    } on Object {
      // Sin espacio o sin permisos: la memoria sigue funcionando.
    }
  }

  Future<void> remove(String key) async {
    _memory.remove(key);
    final file = _fileFor(key);
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  /// Borra todo: memoria y disco.
  Future<void> clear() async {
    _memory.clear();
    final dir = directory;
    if (dir != null && await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Espacio ocupado en disco, en bytes.
  Future<int> diskUsageBytes() async {
    final dir = directory;
    if (dir == null || !await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  void _remember(String key, CachedJson entry) {
    _memory.remove(key);
    _memory[key] = entry;
    while (_memory.length > memoryCapacity) {
      _memory.remove(_memory.keys.first);
    }
  }

  File? _fileFor(String key) {
    final dir = directory;
    if (dir == null) return null;
    return File('${dir.path}${Platform.pathSeparator}${fileNameFor(key)}');
  }

  /// Convierte una clave (`pokemon/25`, `pokemon-species?limit=1`) en un
  /// nombre de archivo seguro.
  static String fileNameFor(String key) {
    final safe = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]+'), '_');
    return '$safe.json';
  }
}
