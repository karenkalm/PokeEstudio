import '../../core/network/api_config.dart';

/// Una entrada de texto de la Pokédex (`flavor_text_entries[]`).
class FlavorTextEntry {
  const FlavorTextEntry({required this.text, required this.language, this.versionSlug, this.versionUrl});

  factory FlavorTextEntry.fromApi(Map<String, dynamic> json) {
    final version = (json['version'] ?? json['version_group']) as Map<String, dynamic>?;
    return FlavorTextEntry(
      text: json['flavor_text'] as String,
      language: (json['language'] as Map<String, dynamic>)['name'] as String,
      versionSlug: version?['name'] as String?,
      versionUrl: version?['url'] as String?,
    );
  }

  final String text;
  final String language;
  final String? versionSlug;
  final String? versionUrl;

  /// Id numérico de la versión; sirve para ordenar de más nueva a más antigua.
  int get versionOrder => versionUrl == null ? 0 : (ApiPath.idFromUrl(versionUrl!) ?? 0);
}

/// Una variedad de la especie (`varieties[]`).
class SpeciesVariety {
  const SpeciesVariety({required this.slug, required this.pokemonId, required this.isDefault});

  final String slug;
  final int? pokemonId;
  final bool isDefault;
}

/// Datos de `/pokemon-species/{id}` que usa la ficha.
class PokemonSpecies {
  const PokemonSpecies({
    required this.id,
    required this.slug,
    required this.names,
    required this.genera,
    required this.flavorTexts,
    required this.generation,
    required this.varieties,
    required this.isLegendary,
    required this.isMythical,
    required this.isBaby,
    this.evolutionChainUrl,
    this.habitatSlug,
    this.captureRate,
    this.genderRate,
  });

  factory PokemonSpecies.fromApi(Map<String, dynamic> json) {
    final names = <String, String>{};
    for (final raw in json['names'] as List<dynamic>) {
      final item = raw as Map<String, dynamic>;
      names[(item['language'] as Map<String, dynamic>)['name'] as String] = item['name'] as String;
    }
    final genera = <String, String>{};
    for (final raw in (json['genera'] as List<dynamic>?) ?? const <dynamic>[]) {
      final item = raw as Map<String, dynamic>;
      genera[(item['language'] as Map<String, dynamic>)['name'] as String] = item['genus'] as String;
    }
    final generationSlug = (json['generation'] as Map<String, dynamic>)['name'] as String;
    final varieties = <SpeciesVariety>[
      for (final raw in (json['varieties'] as List<dynamic>?) ?? const <dynamic>[])
        _variety(raw as Map<String, dynamic>),
    ];
    final chain = json['evolution_chain'] as Map<String, dynamic>?;
    final habitat = json['habitat'] as Map<String, dynamic>?;

    return PokemonSpecies(
      id: json['id'] as int,
      slug: json['name'] as String,
      names: Map<String, String>.unmodifiable(names),
      genera: Map<String, String>.unmodifiable(genera),
      flavorTexts: List<FlavorTextEntry>.unmodifiable(<FlavorTextEntry>[
        for (final raw in (json['flavor_text_entries'] as List<dynamic>?) ?? const <dynamic>[])
          FlavorTextEntry.fromApi(raw as Map<String, dynamic>),
      ]),
      generation: generationFromSlug(generationSlug),
      varieties: List<SpeciesVariety>.unmodifiable(varieties),
      isLegendary: json['is_legendary'] as bool? ?? false,
      isMythical: json['is_mythical'] as bool? ?? false,
      isBaby: json['is_baby'] as bool? ?? false,
      evolutionChainUrl: chain?['url'] as String?,
      habitatSlug: habitat?['name'] as String?,
      captureRate: json['capture_rate'] as int?,
      genderRate: json['gender_rate'] as int?,
    );
  }

  static SpeciesVariety _variety(Map<String, dynamic> json) {
    final pokemon = json['pokemon'] as Map<String, dynamic>;
    return SpeciesVariety(
      slug: pokemon['name'] as String,
      pokemonId: ApiPath.idFromUrl(pokemon['url'] as String),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  /// `generation-iv` → 4.
  static int generationFromSlug(String slug) {
    const roman = <String, int>{
      'i': 1, 'ii': 2, 'iii': 3, 'iv': 4, 'v': 5, 'vi': 6, 'vii': 7, 'viii': 8, 'ix': 9, 'x': 10,
    };
    final suffix = slug.split('-').last;
    final value = roman[suffix];
    if (value == null) throw FormatException('Generación desconocida: $slug');
    return value;
  }

  /// Conserva solo los textos en español e inglés antes de guardar en caché.
  static Map<String, dynamic> reduceForCache(Map<String, dynamic> json) {
    bool keep(Object? item) {
      if (item is! Map<String, dynamic>) return false;
      final language = (item['language'] as Map<String, dynamic>?)?['name'];
      return language == 'es' || language == 'en';
    }

    final reduced = Map<String, dynamic>.of(json)
      ..remove('pokedex_numbers')
      ..remove('pal_park_encounters');
    for (final key in const <String>['names', 'genera', 'flavor_text_entries', 'form_descriptions']) {
      final list = reduced[key];
      if (list is List<dynamic>) {
        reduced[key] = list.where(keep).toList();
      }
    }
    return reduced;
  }

  final int id;
  final String slug;

  /// Nombres por idioma (`es`, `en`).
  final Map<String, String> names;

  /// Categoría por idioma: `es` → `Pokémon Ratón`.
  final Map<String, String> genera;
  final List<FlavorTextEntry> flavorTexts;
  final int generation;
  final List<SpeciesVariety> varieties;
  final bool isLegendary;
  final bool isMythical;
  final bool isBaby;
  final String? evolutionChainUrl;
  final String? habitatSlug;
  final int? captureRate;

  /// -1 = sin género; 0..8 = octavos de probabilidad de ser hembra.
  final int? genderRate;

  String get nameEs => names['es'] ?? names['en'] ?? slug;

  List<SpeciesVariety> get alternateVarieties => varieties.where((v) => !v.isDefault).toList();
}
