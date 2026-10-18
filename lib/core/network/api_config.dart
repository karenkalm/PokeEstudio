/// Configuración central de la conexión con PokéAPI.
abstract final class ApiConfig {
  /// Documentación: https://pokeapi.co/docs/v2
  static final Uri baseUri = Uri.parse('https://pokeapi.co/api/v2/');

  /// Tiempo máximo de espera por petición.
  static const Duration requestTimeout = Duration(seconds: 12);

  /// Reintentos adicionales ante errores transitorios (timeout, 5xx, red).
  static const int maxRetries = 2;

  /// Los datos de PokéAPI son prácticamente estáticos; se cachean 30 días,
  /// como recomienda su política de uso justo.
  static const Duration defaultMaxAge = Duration(days: 30);

  /// Respuestas mayores a este tamaño se decodifican en otro isolate para no
  /// trabar la interfaz.
  static const int backgroundDecodeThresholdBytes = 64 * 1024;
}

/// Utilidades para trabajar con rutas y URLs de PokéAPI.
abstract final class ApiPath {
  static final RegExp _apiPrefix = RegExp(r'^.*?/api/v2/');

  /// Normaliza cualquier forma de referirse a un recurso:
  ///
  /// * `pokemon/25`
  /// * `/api/v2/pokemon/25/`
  /// * `https://pokeapi.co/api/v2/pokemon/25/`
  ///
  /// a `pokemon/25`. Conserva la cadena de consulta (`?limit=1`).
  static String normalize(String pathOrUrl) {
    var value = pathOrUrl.trim();
    final queryIndex = value.indexOf('?');
    var query = '';
    if (queryIndex >= 0) {
      query = value.substring(queryIndex);
      value = value.substring(0, queryIndex);
    }
    value = value.replaceFirst(_apiPrefix, '');
    while (value.startsWith('/')) {
      value = value.substring(1);
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return '$value$query';
  }

  /// Construye la URL final: PokéAPI responde con barra final en los recursos.
  static Uri resolve(String pathOrUrl, {Uri? base}) {
    final normalized = normalize(pathOrUrl);
    final queryIndex = normalized.indexOf('?');
    final path = queryIndex >= 0 ? normalized.substring(0, queryIndex) : normalized;
    final query = queryIndex >= 0 ? normalized.substring(queryIndex + 1) : null;
    final root = base ?? ApiConfig.baseUri;
    return root.resolve('$path/').replace(query: query);
  }

  /// Extrae el identificador numérico final de una URL de recurso.
  /// `https://pokeapi.co/api/v2/ability/9/` → 9.
  static int? idFromUrl(String url) {
    final match = RegExp(r'/(\d+)/?$').firstMatch(url.split('?').first);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
