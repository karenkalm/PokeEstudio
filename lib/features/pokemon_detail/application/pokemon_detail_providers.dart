import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_config.dart';
import '../../../core/utils/provider_cache.dart';
import '../../../shared/models/localized_resource.dart';
import '../../../shared/models/pokemon_detail.dart';
import '../../../shared/models/pokemon_species.dart';
import '../../../shared/repositories/pokemon_repository.dart';

/// `/pokemon/{id}`: se libera unos minutos después de salir de la ficha.
final pokemonDetailProvider = FutureProvider.autoDispose.family<PokemonDetail, int>((ref, pokemonId) {
  ref.cacheFor(const Duration(minutes: 3));
  return ref.watch(pokemonRepositoryProvider).getPokemon(pokemonId);
}, name: 'pokemonDetailProvider');

/// `/pokemon-species/{id}`.
final pokemonSpeciesProvider = FutureProvider.autoDispose.family<PokemonSpecies, int>((ref, speciesId) {
  ref.cacheFor(const Duration(minutes: 3));
  return ref.watch(pokemonRepositoryProvider).getSpecies(speciesId);
}, name: 'pokemonSpeciesProvider');

/// Nombres traducidos de habilidades, versiones… La clave es la ruta
/// normalizada (`ability/9`), así la URL absoluta y la relativa comparten caché.
final localizedResourceProvider = FutureProvider.autoDispose.family<LocalizedResource, String>((ref, path) {
  ref.cacheFor(const Duration(minutes: 10));
  return ref.watch(pokemonRepositoryProvider).getLocalizedResource(path);
}, name: 'localizedResourceProvider');

/// Atajo: provider para cualquier URL de recurso de PokéAPI.
FutureProvider<LocalizedResource> localizedResourceFor(String url) =>
    localizedResourceProvider(ApiPath.normalize(url));
