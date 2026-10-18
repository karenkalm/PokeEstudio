import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/application/pokedex_index_controller.dart';
import '../../../shared/models/pokemon_type.dart';
import '../domain/pokedex_filter.dart';
import '../domain/pokedex_query.dart';

/// Filtros activos de la Pokédex. Se conservan al cambiar de pestaña.
class PokedexFilterController extends Notifier<PokedexFilter> {
  @override
  PokedexFilter build() => PokedexFilter.empty;

  void apply(PokedexFilter filter) => state = filter;

  void clear() => state = state.cleared();

  void setSort(PokedexSort sort) => state = state.copyWith(sort: sort);

  /// Atajo de "Explorar por tipo": muestra todos los Pokémon con ese tipo.
  void showOnlyType(PokemonType type) {
    state = state.cleared().copyWith(firstType: type, typeMatchMode: TypeMatchMode.anyPosition);
  }

  /// Atajo de "Explorar por generación".
  void showOnlyGeneration(int generation) {
    state = state.cleared().copyWith(generations: <int>{generation});
  }

  void removeFirstType() => state = state.copyWith(firstType: null);
  void removeSecondType() => state = state.copyWith(secondType: null, monotypeOnly: false);
  void removeGenerations() => state = state.copyWith(generations: const <int>{});
  void removeMinAttack() => state = state.copyWith(minAttack: 0);
  void removeMinDefense() => state = state.copyWith(minDefense: 0);
  void removeMinSpeed() => state = state.copyWith(minSpeed: 0);
  void removeMinTotal() => state = state.copyWith(minTotal: 0);
  void removeOnlyWithShiny() => state = state.copyWith(onlyWithShiny: false);
  void removeOnlyWithForms() => state = state.copyWith(onlyWithForms: false);
}

final pokedexFilterProvider = NotifierProvider<PokedexFilterController, PokedexFilter>(
  PokedexFilterController.new,
  name: 'pokedexFilterProvider',
);

/// Texto de búsqueda (ya con debounce desde la interfaz).
class PokedexQueryController extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final pokedexQueryProvider = NotifierProvider<PokedexQueryController, String>(
  PokedexQueryController.new,
  name: 'pokedexQueryProvider',
);

/// Resultados combinados. La búsqueda es local, así que no existen respuestas
/// "obsoletas" que lleguen tarde: el resultado siempre corresponde al texto actual.
final pokedexResultsProvider = Provider<AsyncValue<PokedexResults>>((ref) {
  final index = ref.watch(pokedexIndexProvider);
  final filter = ref.watch(pokedexFilterProvider);
  final query = ref.watch(pokedexQueryProvider);
  return index.whenData((data) => PokedexQuery.run(data.entries, filter: filter, query: query));
}, name: 'pokedexResultsProvider');
