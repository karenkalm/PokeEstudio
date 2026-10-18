import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/network/poke_api_client.dart';
import '../../core/providers.dart';
import '../models/localized_resource.dart';
import '../models/pokemon_detail.dart';
import '../models/pokemon_species.dart';

/// Acceso a los recursos de PokéAPI que usa la ficha de un Pokémon.
///
/// Convierte JSON en modelos y cualquier sorpresa de formato en un
/// [ParseFailure]: nunca rellena huecos con datos inventados.
class PokemonRepository {
  PokemonRepository(this._api);

  final PokeApiClient _api;

  Future<PokemonDetail> getPokemon(int pokemonId) async {
    final json = await _api.getJson('pokemon/$pokemonId', reduce: PokemonDetail.reduceForCache);
    return _parse('pokemon/$pokemonId', () => PokemonDetail.fromApi(json));
  }

  Future<PokemonSpecies> getSpecies(int speciesId) async {
    final json = await _api.getJson('pokemon-species/$speciesId', reduce: PokemonSpecies.reduceForCache);
    return _parse('pokemon-species/$speciesId', () => PokemonSpecies.fromApi(json));
  }

  /// Habilidades, versiones, movimientos… cualquier recurso con `names`.
  Future<LocalizedResource> getLocalizedResource(String pathOrUrl) async {
    final json = await _api.getJson(pathOrUrl, reduce: LocalizedResource.reduceForCache);
    return _parse(pathOrUrl, () => LocalizedResource.fromApi(json));
  }

  T _parse<T>(String resource, T Function() parse) {
    try {
      return parse();
    } on FormatException catch (error) {
      throw ParseFailure('$resource: $error');
      // ignore: avoid_catching_errors
    } on TypeError catch (error) {
      // Un campo con un tipo distinto al documentado.
      throw ParseFailure('$resource: $error');
    }
  }
}

final pokemonRepositoryProvider = Provider<PokemonRepository>(
  (ref) => PokemonRepository(ref.watch(pokeApiClientProvider)),
  name: 'pokemonRepositoryProvider',
);
