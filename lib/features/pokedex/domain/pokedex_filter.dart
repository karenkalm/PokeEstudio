import '../../../shared/models/pokemon_type.dart';

/// Cómo se interpretan los tipos seleccionados.
enum TypeMatchMode {
  /// El Pokémon debe tener los tipos elegidos, en cualquier orden.
  anyPosition('Cualquier posición'),

  /// Tipo 1 = tipo principal y Tipo 2 = tipo secundario, exactamente.
  exactPosition('Posición exacta');

  const TypeMatchMode(this.label);
  final String label;
}

/// Orden de los resultados.
enum PokedexSort {
  numberAsc('Número (ascendente)'),
  numberDesc('Número (descendente)'),
  nameAsc('Nombre (A–Z)'),
  nameDesc('Nombre (Z–A)'),
  totalDesc('Estadísticas totales'),
  attackDesc('Ataque'),
  defenseDesc('Defensa'),
  speedDesc('Velocidad');

  const PokedexSort(this.label);
  final String label;
}

/// Filtros combinables de la Pokédex. Inmutable.
class PokedexFilter {
  const PokedexFilter({
    this.firstType,
    this.secondType,
    this.monotypeOnly = false,
    this.typeMatchMode = TypeMatchMode.anyPosition,
    this.generations = const <int>{},
    this.minAttack = 0,
    this.minDefense = 0,
    this.minSpeed = 0,
    this.minTotal = 0,
    this.onlyWithShiny = false,
    this.onlyWithForms = false,
    this.sort = PokedexSort.numberAsc,
  });

  static const PokedexFilter empty = PokedexFilter();

  /// Tipo 1 (en modo exacto: tipo principal).
  final PokemonType? firstType;

  /// Tipo 2 (en modo exacto: tipo secundario).
  final PokemonType? secondType;

  /// Solo Pokémon de un único tipo.
  final bool monotypeOnly;
  final TypeMatchMode typeMatchMode;
  final Set<int> generations;
  final int minAttack;
  final int minDefense;
  final int minSpeed;

  /// Suma mínima de estadísticas base.
  final int minTotal;
  final bool onlyWithShiny;
  final bool onlyWithForms;
  final PokedexSort sort;

  /// Número de filtros activos (el orden no cuenta como filtro).
  int get activeCount {
    var count = 0;
    if (firstType != null) count++;
    if (secondType != null) count++;
    if (monotypeOnly) count++;
    if (generations.isNotEmpty) count++;
    if (minAttack > 0) count++;
    if (minDefense > 0) count++;
    if (minSpeed > 0) count++;
    if (minTotal > 0) count++;
    if (onlyWithShiny) count++;
    if (onlyWithForms) count++;
    return count;
  }

  bool get hasActiveFilters => activeCount > 0;

  static const Object _unset = Object();

  PokedexFilter copyWith({
    Object? firstType = _unset,
    Object? secondType = _unset,
    bool? monotypeOnly,
    TypeMatchMode? typeMatchMode,
    Set<int>? generations,
    int? minAttack,
    int? minDefense,
    int? minSpeed,
    int? minTotal,
    bool? onlyWithShiny,
    bool? onlyWithForms,
    PokedexSort? sort,
  }) {
    return PokedexFilter(
      firstType: identical(firstType, _unset) ? this.firstType : firstType as PokemonType?,
      secondType: identical(secondType, _unset) ? this.secondType : secondType as PokemonType?,
      monotypeOnly: monotypeOnly ?? this.monotypeOnly,
      typeMatchMode: typeMatchMode ?? this.typeMatchMode,
      generations: generations ?? this.generations,
      minAttack: minAttack ?? this.minAttack,
      minDefense: minDefense ?? this.minDefense,
      minSpeed: minSpeed ?? this.minSpeed,
      minTotal: minTotal ?? this.minTotal,
      onlyWithShiny: onlyWithShiny ?? this.onlyWithShiny,
      onlyWithForms: onlyWithForms ?? this.onlyWithForms,
      sort: sort ?? this.sort,
    );
  }

  /// Quita los filtros pero conserva el orden elegido.
  PokedexFilter cleared() => PokedexFilter(sort: sort);

  @override
  bool operator ==(Object other) {
    return other is PokedexFilter &&
        other.firstType == firstType &&
        other.secondType == secondType &&
        other.monotypeOnly == monotypeOnly &&
        other.typeMatchMode == typeMatchMode &&
        other.generations.length == generations.length &&
        other.generations.containsAll(generations) &&
        other.minAttack == minAttack &&
        other.minDefense == minDefense &&
        other.minSpeed == minSpeed &&
        other.minTotal == minTotal &&
        other.onlyWithShiny == onlyWithShiny &&
        other.onlyWithForms == onlyWithForms &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(
        firstType,
        secondType,
        monotypeOnly,
        typeMatchMode,
        Object.hashAllUnordered(generations),
        minAttack,
        minDefense,
        minSpeed,
        minTotal,
        onlyWithShiny,
        onlyWithForms,
        sort,
      );
}
