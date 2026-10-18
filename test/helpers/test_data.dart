import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokestudio/core/network/api_config.dart';
import 'package:pokestudio/shared/application/pokedex_index_controller.dart';
import 'package:pokestudio/shared/models/pokedex_entry.dart';

/// Índice real empaquetado con la app (assets/data/pokedex_index.json).
PokedexIndex loadRealIndex() {
  final raw = File('assets/data/pokedex_index.json').readAsStringSync();
  return PokedexIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// JSON real de PokéAPI recortado, guardado en test/fixtures.
Map<String, dynamic> fixture(String fileName) {
  return jsonDecode(File('test/fixtures/$fileName').readAsStringSync()) as Map<String, dynamic>;
}

/// Cliente HTTP falso que sirve los fixtures: `pokemon-species/25` →
/// `test/fixtures/pokemon_species_25.json`. Lo demás responde 404.
MockClient fixtureHttpClient({List<String>? requestLog}) {
  return MockClient((request) async {
    final path = ApiPath.normalize(request.url.toString());
    requestLog?.add(path);
    final file = File('test/fixtures/${path.replaceAll(RegExp(r'[-/]'), '_')}.json');
    if (!file.existsSync()) {
      return http.Response('Not Found', 404);
    }
    return http.Response.bytes(
      file.readAsBytesSync(),
      200,
      headers: const <String, String>{'content-type': 'application/json; charset=utf-8'},
    );
  });
}

/// Controlador del índice que devuelve datos fijos (sin comprobar
/// actualizaciones en red).
class FakeIndexController extends PokedexIndexController {
  FakeIndexController(this.index);

  final PokedexIndex index;

  @override
  Future<PokedexIndex> build() async => index;
}
