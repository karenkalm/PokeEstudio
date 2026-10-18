import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/json_cache.dart';
import '../../core/network/poke_api_client.dart';
import '../../core/providers.dart';
import '../models/base_stats.dart';
import '../models/pokedex_entry.dart';
import '../models/pokemon_detail.dart';
import '../models/pokemon_species.dart';
import 'pokemon_repository.dart';

PokedexIndex _parseIndex(String raw) => PokedexIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>);

/// Carga el índice local de la Pokédex y lo mantiene al día.
///
/// 1. Lee `assets/data/pokedex_index.json` (instantánea de PokéAPI).
/// 2. Suma las especies nuevas que se hayan descargado antes (caché).
/// 3. [fetchNewSpecies] pregunta a PokéAPI cuántas especies existen y, si hay
///    más que en el índice, descarga solo las que faltan.
class PokedexIndexRepository {
  PokedexIndexRepository({
    required AssetBundle bundle,
    required PokeApiClient api,
    required PokemonRepository pokemon,
    required JsonCache cache,
  })  : _bundle = bundle,
        _api = api,
        _pokemon = pokemon,
        _cache = cache;

  static const String assetPath = 'assets/data/pokedex_index.json';
  static const String _extensionKey = 'local/pokedex_index_extension';

  final AssetBundle _bundle;
  final PokeApiClient _api;
  final PokemonRepository _pokemon;
  final JsonCache _cache;

  Future<PokedexIndex> load() async {
    final raw = await _bundle.loadString(assetPath);
    var index = await compute(_parseIndex, raw);
    final extension = await _readExtension();
    if (extension.isNotEmpty) {
      index = index.withEntries(extension);
    }
    return index;
  }

  /// Devuelve un índice ampliado si PokéAPI tiene especies nuevas, o `null`
  /// si el índice ya está completo.
  Future<PokedexIndex?> fetchNewSpecies(PokedexIndex current) async {
    final listing = await _api.getJson('pokemon-species?limit=1', maxAge: const Duration(days: 1));
    final count = listing['count'];
    if (count is! int || count <= current.maxId) return null;

    final added = <PokedexEntry>[];
    for (var id = current.maxId + 1; id <= count; id++) {
      added.add(await _buildEntry(id));
    }
    final stored = <PokedexEntry>[...await _readExtension(), ...added];
    await _cache.write(_extensionKey, <String, dynamic>{
      'entries': <Map<String, dynamic>>[for (final entry in stored) entry.toIndexJson()],
    });
    return current.withEntries(added);
  }

  Future<PokedexEntry> _buildEntry(int speciesId) async {
    final PokemonSpecies species = await _pokemon.getSpecies(speciesId);
    final defaultVariety = species.varieties.where((v) => v.isDefault).firstOrNull;
    final pokemonId = defaultVariety?.pokemonId ?? speciesId;
    final PokemonDetail detail = await _pokemon.getPokemon(pokemonId);
    return PokedexEntry(
      id: species.id,
      pokemonId: pokemonId,
      slug: species.slug,
      nameEs: species.names['es'] ?? species.names['en'] ?? species.slug,
      nameEn: species.names['en'] ?? species.slug,
      generation: species.generation,
      types: detail.types,
      stats: BaseStats.fromList(detail.stats.toList()),
      spriteUrl: detail.sprites.frontDefault,
      shinySpriteUrl: detail.sprites.frontShiny,
      artworkUrl: detail.sprites.artwork,
      forms: <String>[for (final variety in species.alternateVarieties) variety.slug],
      isLegendary: species.isLegendary,
      isMythical: species.isMythical,
      isBaby: species.isBaby,
    );
  }

  Future<List<PokedexEntry>> _readExtension() async {
    final cached = await _cache.read(_extensionKey);
    final rawEntries = cached?.data['entries'];
    if (rawEntries is! List<dynamic>) return const <PokedexEntry>[];
    final entries = <PokedexEntry>[];
    for (final raw in rawEntries) {
      try {
        entries.add(PokedexEntry.fromIndexJson(raw as Map<String, dynamic>, spriteBase: ''));
      } on Object {
        // Una entrada dañada se descarta; se volverá a descargar.
      }
    }
    return entries;
  }
}

final pokedexIndexRepositoryProvider = Provider<PokedexIndexRepository>((ref) {
  return PokedexIndexRepository(
    bundle: rootBundle,
    api: ref.watch(pokeApiClientProvider),
    pokemon: ref.watch(pokemonRepositoryProvider),
    cache: ref.watch(jsonCacheProvider),
  );
}, name: 'pokedexIndexRepositoryProvider');
