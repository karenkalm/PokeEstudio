/// Las seis estadísticas base, con su identificador de PokéAPI y su nombre
/// oficial en español.
enum StatKind {
  hp('hp', 'PS', 'PS'),
  attack('attack', 'Ataque', 'Ataque'),
  defense('defense', 'Defensa', 'Defensa'),
  specialAttack('special-attack', 'Ataque Especial', 'At. Esp.'),
  specialDefense('special-defense', 'Defensa Especial', 'Def. Esp.'),
  speed('speed', 'Velocidad', 'Velocidad');

  const StatKind(this.slug, this.spanishName, this.shortName);

  final String slug;
  final String spanishName;
  final String shortName;

  static StatKind? fromSlug(String slug) {
    for (final kind in StatKind.values) {
      if (kind.slug == slug) return kind;
    }
    return null;
  }
}

/// Estadísticas base de un Pokémon.
class BaseStats {
  const BaseStats({
    required this.hp,
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
  });

  /// Construye desde una lista en el orden de [StatKind.values].
  factory BaseStats.fromList(List<int> values) {
    if (values.length != StatKind.values.length) {
      throw FormatException('Se esperaban 6 estadísticas y llegaron ${values.length}.');
    }
    return BaseStats(
      hp: values[0],
      attack: values[1],
      defense: values[2],
      specialAttack: values[3],
      specialDefense: values[4],
      speed: values[5],
    );
  }

  /// Construye desde `stats` de `/pokemon/{id}`.
  factory BaseStats.fromApi(List<dynamic> stats) {
    final byKind = <StatKind, int>{};
    for (final raw in stats) {
      final item = raw as Map<String, dynamic>;
      final statName = (item['stat'] as Map<String, dynamic>)['name'] as String;
      final kind = StatKind.fromSlug(statName);
      if (kind != null) byKind[kind] = item['base_stat'] as int;
    }
    if (byKind.length != StatKind.values.length) {
      throw const FormatException('Faltan estadísticas base en la respuesta.');
    }
    return BaseStats.fromList(<int>[for (final kind in StatKind.values) byKind[kind]!]);
  }

  /// La estadística base más alta posible en los juegos.
  static const int maxValue = 255;

  final int hp;
  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;

  int get total => hp + attack + defense + specialAttack + specialDefense + speed;

  int operator [](StatKind kind) => switch (kind) {
        StatKind.hp => hp,
        StatKind.attack => attack,
        StatKind.defense => defense,
        StatKind.specialAttack => specialAttack,
        StatKind.specialDefense => specialDefense,
        StatKind.speed => speed,
      };

  List<int> toList() => <int>[for (final kind in StatKind.values) this[kind]];
}
