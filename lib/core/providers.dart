import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'cache/json_cache.dart';
import 'network/poke_api_client.dart';

/// Preferencias del dispositivo. Se inicializa en `main()` y se inyecta con
/// `overrideWithValue`; en pruebas se usa `SharedPreferences.setMockInitialValues`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider debe sobrescribirse en main().'),
  name: 'sharedPreferencesProvider',
);

/// Caché JSON. En `main()` se sobrescribe con una que escribe en disco; por
/// defecto (pruebas) solo usa memoria.
final jsonCacheProvider = Provider<JsonCache>(
  (ref) => JsonCache(),
  name: 'jsonCacheProvider',
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}, name: 'httpClientProvider');

final pokeApiClientProvider = Provider<PokeApiClient>((ref) {
  return PokeApiClient(
    httpClient: ref.watch(httpClientProvider),
    cache: ref.watch(jsonCacheProvider),
  );
}, name: 'pokeApiClientProvider');
