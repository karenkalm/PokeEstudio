import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokestudio/core/cache/json_cache.dart';
import 'package:pokestudio/core/errors/app_failure.dart';
import 'package:pokestudio/core/network/api_config.dart';
import 'package:pokestudio/core/network/poke_api_client.dart';
import 'package:pokestudio/shared/models/pokemon_detail.dart';
import 'package:pokestudio/shared/repositories/pokemon_repository.dart';

import 'helpers/test_data.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const <String, String>{'content-type': 'application/json; charset=utf-8'},
    );

PokeApiClient makeClient(http.Client httpClient, {JsonCache? cache}) => PokeApiClient(
      httpClient: httpClient,
      cache: cache ?? JsonCache(),
      retryDelay: (_) => Duration.zero,
    );

void main() {
  group('ApiPath', () {
    test('normaliza rutas, rutas relativas y URLs completas', () {
      expect(ApiPath.normalize('pokemon/25'), 'pokemon/25');
      expect(ApiPath.normalize('/api/v2/pokemon/25/'), 'pokemon/25');
      expect(ApiPath.normalize('https://pokeapi.co/api/v2/pokemon/25/'), 'pokemon/25');
      expect(ApiPath.normalize('pokemon-species?limit=1'), 'pokemon-species?limit=1');
    });

    test('construye la URL con barra final y consulta', () {
      expect(ApiPath.resolve('pokemon/25').toString(), 'https://pokeapi.co/api/v2/pokemon/25/');
      expect(
        ApiPath.resolve('pokemon-species?limit=1').toString(),
        'https://pokeapi.co/api/v2/pokemon-species/?limit=1',
      );
    });

    test('extrae el id de una URL', () {
      expect(ApiPath.idFromUrl('https://pokeapi.co/api/v2/ability/9/'), 9);
      expect(ApiPath.idFromUrl('/api/v2/version/23/'), 23);
      expect(ApiPath.idFromUrl('https://pokeapi.co/api/v2/ability/static/'), isNull);
    });
  });

  group('PokeApiClient', () {
    test('usa la caché: la segunda lectura no toca la red', () async {
      var calls = 0;
      final client = makeClient(MockClient((request) async {
        calls++;
        return jsonResponse(<String, Object>{'id': 1});
      }));
      await client.getJson('pokemon/1');
      await client.getJson('https://pokeapi.co/api/v2/pokemon/1/');
      expect(calls, 1);
    });

    test('deduplica peticiones simultáneas', () async {
      var calls = 0;
      final client = makeClient(MockClient((request) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return jsonResponse(<String, Object>{'id': 2});
      }));
      final results = await Future.wait(<Future<Map<String, dynamic>>>[
        client.getJson('pokemon/2'),
        client.getJson('pokemon/2'),
        client.getJson('/api/v2/pokemon/2/'),
      ]);
      expect(calls, 1);
      expect(results.every((r) => r['id'] == 2), isTrue);
    });

    test('reintenta errores 5xx y luego tiene éxito', () async {
      var calls = 0;
      final client = makeClient(MockClient((request) async {
        calls++;
        return calls < 3 ? http.Response('error', 503) : jsonResponse(<String, Object>{'ok': true});
      }));
      final json = await client.getJson('pokemon/3');
      expect(json['ok'], isTrue);
      expect(calls, 3);
    });

    test('no reintenta un 404', () async {
      var calls = 0;
      final client = makeClient(MockClient((request) async {
        calls++;
        return http.Response('Not Found', 404);
      }));
      await expectLater(client.getJson('pokemon/99999'), throwsA(isA<NotFoundFailure>()));
      expect(calls, 1);
    });

    test('sin conexión y sin copia: NetworkFailure tras los reintentos', () async {
      var calls = 0;
      final client = makeClient(MockClient((request) async {
        calls++;
        throw http.ClientException('Failed host lookup', request.url);
      }));
      await expectLater(client.getJson('pokemon/4'), throwsA(isA<NetworkFailure>()));
      expect(calls, ApiConfig.maxRetries + 1);
    });

    test('sin conexión pero con copia vieja: devuelve la copia', () async {
      var now = DateTime(2026, 1, 1);
      final cache = JsonCache(clock: () => now);
      var online = true;
      final client = makeClient(
        MockClient((request) async {
          if (!online) throw http.ClientException('offline', request.url);
          return jsonResponse(<String, Object>{'id': 5, 'name': 'charmeleon'});
        }),
        cache: cache,
      );
      await client.getJson('pokemon/5');
      online = false;
      now = now.add(const Duration(days: 60)); // la copia ya no está vigente
      final json = await client.getJson('pokemon/5');
      expect(json['name'], 'charmeleon');
    });

    test('JSON mal formado: ParseFailure, sin reintentos', () async {
      var calls = 0;
      final client = makeClient(MockClient((request) async {
        calls++;
        return http.Response('<html>oops</html>', 200);
      }));
      await expectLater(client.getJson('pokemon/6'), throwsA(isA<ParseFailure>()));
      expect(calls, 1);
    });

    test('decodifica UTF-8 aunque el servidor no indique charset', () async {
      final client = makeClient(MockClient((request) async {
        return http.Response.bytes(utf8.encode('{"name":"Código Cero"}'), 200);
      }));
      final json = await client.getJson('pokemon-species/772');
      expect(json['name'], 'Código Cero');
    });

    test('aplica el reductor antes de guardar en caché', () async {
      final cache = JsonCache();
      final client = makeClient(
        MockClient((request) async => jsonResponse(<String, Object>{'id': 7, 'moves': <int>[1, 2, 3]})),
        cache: cache,
      );
      await client.getJson('pokemon/7', reduce: PokemonDetail.reduceForCache);
      final cached = await cache.read('pokemon/7');
      expect(cached!.data.containsKey('moves'), isFalse);
    });
  });

  group('PokemonRepository con datos reales', () {
    test('carga Pikachu, su especie y su habilidad', () async {
      final log = <String>[];
      final repository = PokemonRepository(makeClient(fixtureHttpClient(requestLog: log)));
      final pokemon = await repository.getPokemon(25);
      final species = await repository.getSpecies(25);
      final ability = await repository.getLocalizedResource(pokemon.abilities.first.url);
      expect(pokemon.slug, 'pikachu');
      expect(species.genera['es'], 'Pokémon Ratón');
      expect(ability.displayName.text, 'Electricidad Estática');
      expect(log, <String>['pokemon/25', 'pokemon-species/25', 'ability/9']);
    });

    test('un recurso inexistente produce NotFoundFailure', () async {
      final repository = PokemonRepository(makeClient(fixtureHttpClient()));
      await expectLater(repository.getPokemon(424242), throwsA(isA<NotFoundFailure>()));
    });
  });

  group('JsonCache en disco', () {
    late Directory dir;

    setUp(() async => dir = await Directory.systemTemp.createTemp('pokestudio_cache_test'));
    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('persiste entre instancias y se puede vaciar', () async {
      final first = JsonCache(directory: dir);
      await first.write('pokemon-species/25', <String, dynamic>{'name': 'pikachu'});
      expect(await first.diskUsageBytes(), greaterThan(0));

      final second = JsonCache(directory: dir);
      final entry = await second.read('pokemon-species/25');
      expect(entry!.data['name'], 'pikachu');

      await second.clear();
      expect(await JsonCache(directory: dir).read('pokemon-species/25'), isNull);
    });

    test('un archivo dañado se ignora', () async {
      final cache = JsonCache(directory: dir);
      await File('${dir.path}/${JsonCache.fileNameFor('pokemon/1')}').writeAsString('{no es json');
      expect(await cache.read('pokemon/1'), isNull);
    });

    test('nombres de archivo seguros', () {
      expect(JsonCache.fileNameFor('pokemon/25'), 'pokemon_25.json');
      expect(JsonCache.fileNameFor('pokemon-species?limit=1'), 'pokemon-species_limit_1.json');
    });
  });
}
