/// Errores de la app expresados en un lenguaje que la interfaz puede mostrar.
///
/// Las capas de datos convierten excepciones técnicas (sockets, timeouts,
/// JSON mal formado…) en uno de estos tipos. La presentación nunca necesita
/// conocer `http` ni `dart:io`.
sealed class AppFailure implements Exception {
  const AppFailure(this.debugMessage);

  /// Detalle técnico para registros y depuración. No se muestra al usuario.
  final String debugMessage;

  /// Título corto y amable para la interfaz.
  String get title;

  /// Explicación para la interfaz.
  String get message;

  /// Si tiene sentido ofrecer el botón "Reintentar".
  bool get isRetryable => true;

  @override
  String toString() => '$runtimeType: $debugMessage';
}

/// No hubo conexión con el servidor (sin red, DNS, conexión rechazada…).
final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.debugMessage);

  @override
  String get title => 'Sin conexión';

  @override
  String get message =>
      'No pudimos comunicarnos con PokéAPI. Revisa tu conexión a internet e inténtalo de nuevo.';
}

/// El servidor tardó demasiado en responder.
final class TimeoutFailure extends AppFailure {
  const TimeoutFailure(super.debugMessage);

  @override
  String get title => 'PokéAPI tardó demasiado';

  @override
  String get message => 'El servidor no respondió a tiempo. Suele resolverse al reintentar.';
}

/// El recurso no existe (HTTP 404).
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.debugMessage);

  @override
  String get title => 'No encontrado';

  @override
  String get message => 'PokéAPI no tiene información para este elemento.';

  @override
  bool get isRetryable => false;
}

/// El servidor respondió con un error (5xx u otro código inesperado).
final class ServerFailure extends AppFailure {
  const ServerFailure(super.debugMessage, {this.statusCode});

  final int? statusCode;

  @override
  String get title => 'PokéAPI tuvo un problema';

  @override
  String get message =>
      'El servidor respondió con un error${statusCode != null ? ' ($statusCode)' : ''}. Inténtalo en unos minutos.';
}

/// La respuesta no tenía el formato esperado.
final class ParseFailure extends AppFailure {
  const ParseFailure(super.debugMessage);

  @override
  String get title => 'Datos incompletos';

  @override
  String get message =>
      'Recibimos una respuesta incompleta o con un formato inesperado. No mostraremos datos inventados.';
}

/// Cualquier otro error no previsto.
final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.debugMessage);

  @override
  String get title => 'Algo salió mal';

  @override
  String get message => 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}

/// Convierte un error técnico en un [AppFailure] mostrable.
///
/// La capa de presentación desenvuelve antes los `ProviderException` de
/// Riverpod (ver `failureFromError` en `error_retry_view.dart`), así `core` no
/// depende del gestor de estado.
AppFailure toAppFailure(Object error) {
  if (error is AppFailure) return error;
  if (error is FormatException || error is TypeError) {
    return ParseFailure(error.toString());
  }
  return UnknownFailure(error.toString());
}
