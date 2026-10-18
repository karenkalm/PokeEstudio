import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../cache/json_cache.dart';
import '../errors/app_failure.dart';
import 'api_config.dart';

/// Recorta un JSON antes de guardarlo (por ejemplo, quitar `moves`).
typedef JsonReducer = Map<String, dynamic> Function(Map<String, dynamic> json);

/// Espera antes del reintento número [attempt] (1, 2, …).
typedef RetryDelay = Duration Function(int attempt);

Duration _defaultRetryDelay(int attempt) => Duration(milliseconds: 450 * attempt * attempt);

/// Decodifica bytes UTF-8 a JSON. Es de nivel superior para poder usarse con
/// `compute` (otro isolate).
Object? _decodeUtf8Json(Uint8List bytes) => jsonDecode(utf8.decode(bytes));

/// Único punto de acceso HTTP a PokéAPI.
///
/// * Lee primero de la caché ([JsonCache]); si la copia está vigente, no hay red.
/// * Deduplica: si dos pantallas piden lo mismo a la vez, se hace una sola petición.
/// * Reintenta errores transitorios (sin red, timeout, 5xx, 429) con espera creciente.
/// * No reintenta 404 ni respuestas mal formadas.
/// * Si la red falla y existe una copia vieja, devuelve la copia (los datos de
///   PokéAPI casi nunca cambian, y son datos reales, no inventados).
class PokeApiClient {
  PokeApiClient({
    required http.Client httpClient,
    required JsonCache cache,
    Uri? baseUri,
    Duration timeout = ApiConfig.requestTimeout,
    int maxRetries = ApiConfig.maxRetries,
    RetryDelay retryDelay = _defaultRetryDelay,
    int backgroundDecodeThreshold = ApiConfig.backgroundDecodeThresholdBytes,
  })  : _http = httpClient,
        _cache = cache,
        _baseUri = baseUri ?? ApiConfig.baseUri,
        _timeout = timeout,
        _maxRetries = maxRetries,
        _retryDelay = retryDelay,
        _backgroundDecodeThreshold = backgroundDecodeThreshold;

  final http.Client _http;
  final JsonCache _cache;
  final Uri _baseUri;
  final Duration _timeout;
  final int _maxRetries;
  final RetryDelay _retryDelay;
  final int _backgroundDecodeThreshold;

  final Map<String, Future<Map<String, dynamic>>> _inFlight = <String, Future<Map<String, dynamic>>>{};

  /// Número de peticiones HTTP realizadas (útil en pruebas y diagnósticos).
  int get networkRequestCount => _networkRequestCount;
  int _networkRequestCount = 0;

  /// Obtiene un recurso JSON de PokéAPI.
  ///
  /// [pathOrUrl] admite `pokemon/25`, `/api/v2/pokemon/25/` o la URL completa.
  Future<Map<String, dynamic>> getJson(
    String pathOrUrl, {
    JsonReducer? reduce,
    Duration maxAge = ApiConfig.defaultMaxAge,
    bool forceRefresh = false,
  }) async {
    final key = ApiPath.normalize(pathOrUrl);
    final cached = await _cache.read(key);
    if (!forceRefresh && cached != null && cached.isFresh(maxAge, _cache.now())) {
      return cached.data;
    }

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _fetchAndStore(key, reduce);
    _inFlight[key] = future;
    try {
      return await future;
    } on AppFailure catch (failure) {
      final canUseStale = failure is NetworkFailure || failure is TimeoutFailure || failure is ServerFailure;
      if (cached != null && canUseStale) return cached.data;
      rethrow;
    } finally {
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    }
  }

  void close() => _http.close();

  Future<Map<String, dynamic>> _fetchAndStore(String key, JsonReducer? reduce) async {
    final uri = ApiPath.resolve(key, base: _baseUri);
    var attempt = 0;
    while (true) {
      try {
        final json = await _fetchOnce(uri);
        final result = reduce == null ? json : reduce(json);
        await _cache.write(key, result);
        return result;
      } on AppFailure catch (failure) {
        if (!_isTransient(failure) || attempt >= _maxRetries) rethrow;
        attempt++;
        await Future<void>.delayed(_retryDelay(attempt));
      }
    }
  }

  bool _isTransient(AppFailure failure) {
    return switch (failure) {
      NetworkFailure() || TimeoutFailure() => true,
      ServerFailure(:final statusCode) => statusCode == null || statusCode >= 500 || statusCode == 429,
      _ => false,
    };
  }

  Future<Map<String, dynamic>> _fetchOnce(Uri uri) async {
    _networkRequestCount++;
    final http.Response response;
    try {
      response = await _http.get(uri, headers: const <String, String>{'Accept': 'application/json'}).timeout(_timeout);
    } on TimeoutException catch (error) {
      throw TimeoutFailure('GET $uri: $error');
    } on http.ClientException catch (error) {
      throw NetworkFailure('GET $uri: $error');
    } on Exception catch (error) {
      // TLS, proxy y otros fallos de transporte.
      throw NetworkFailure('GET $uri: $error');
    }

    final status = response.statusCode;
    if (status == 404) {
      throw NotFoundFailure('GET $uri → 404');
    }
    if (status < 200 || status >= 300) {
      throw ServerFailure('GET $uri → $status', statusCode: status);
    }

    try {
      final bytes = response.bodyBytes;
      final Object? decoded = bytes.length >= _backgroundDecodeThreshold
          ? await compute(_decodeUtf8Json, bytes)
          : _decodeUtf8Json(bytes);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('La respuesta no es un objeto JSON.');
      }
      return decoded;
    } on FormatException catch (error) {
      throw ParseFailure('GET $uri: $error');
    }
  }
}
