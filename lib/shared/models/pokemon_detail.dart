import 'base_stats.dart';
import 'pokemon_type.dart';

/// Recursos visuales de `/pokemon/{id}` → `sprites`. Cualquier campo puede
/// ser `null`: PokéAPI no tiene todos los recursos para todas las formas.
class PokemonSprites {
  const PokemonSprites({
    this.frontDefault,
    this.frontShiny,
    this.artwork,
    this.artworkShiny,
    this.animated,
    this.animatedShiny,
  });

  factory PokemonSprites.fromApi(Map<String, dynamic> json) {
    final other = json['other'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final artwork = other['official-artwork'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final showdown = other['showdown'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return PokemonSprites(
      frontDefault: _url(json['front_default']),
      frontShiny: _url(json['front_shiny']),
      artwork: _url(artwork['front_default']),
      artworkShiny: _url(artwork['front_shiny']),
      animated: _url(showdown['front_default']),
      animatedShiny: _url(showdown['front_shiny']),
    );
  }

  /// `sprites.front_default` (pixel art).
  final String? frontDefault;

  /// `sprites.front_shiny`.
  final String? frontShiny;

  /// `sprites.other.official-artwork.front_default`.
  final String? artwork;
  final String? artworkShiny;

  /// `sprites.other.showdown.front_default` (GIF animado).
  final String? animated;
  final String? animatedShiny;

  static String? _url(Object? value) => value is String && value.startsWith('http') ? value : null;
}

/// Una habilidad de un Pokémon (`abilities[]`).
class PokemonAbilitySlot {
  const PokemonAbilitySlot({required this.slug, required this.url, required this.isHidden, required this.slot});

  factory PokemonAbilitySlot.fromApi(Map<String, dynamic> json) {
    final ability = json['ability'] as Map<String, dynamic>;
    return PokemonAbilitySlot(
      slug: ability['name'] as String,
      url: ability['url'] as String,
      isHidden: json['is_hidden'] as bool? ?? false,
      slot: json['slot'] as int? ?? 0,
    );
  }

  final String slug;
  final String url;
  final bool isHidden;
  final int slot;
}

/// Datos de `/pokemon/{id}` que usa la ficha.
class PokemonDetail {
  const PokemonDetail({
    required this.id,
    required this.slug,
    required this.speciesSlug,
    required this.speciesUrl,
    required this.heightDecimeters,
    required this.weightHectograms,
    required this.types,
    required this.stats,
    required this.abilities,
    required this.sprites,
    required this.isDefault,
    this.baseExperience,
    this.cryLatest,
    this.cryLegacy,
  });

  factory PokemonDetail.fromApi(Map<String, dynamic> json) {
    final typeSlots = (json['types'] as List<dynamic>).cast<Map<String, dynamic>>().toList()
      ..sort((a, b) => (a['slot'] as int).compareTo(b['slot'] as int));
    final types = <PokemonType>[];
    for (final slot in typeSlots) {
      final type = PokemonType.fromSlug((slot['type'] as Map<String, dynamic>)['name'] as String);
      if (type != null) types.add(type);
    }
    if (types.isEmpty) {
      throw FormatException('El Pokémon ${json['id']} no tiene tipos válidos.');
    }

    final abilities = <PokemonAbilitySlot>[
      for (final raw in json['abilities'] as List<dynamic>) PokemonAbilitySlot.fromApi(raw as Map<String, dynamic>),
    ]..sort((a, b) => a.slot.compareTo(b.slot));

    final species = json['species'] as Map<String, dynamic>;
    final cries = json['cries'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    return PokemonDetail(
      id: json['id'] as int,
      slug: json['name'] as String,
      speciesSlug: species['name'] as String,
      speciesUrl: species['url'] as String,
      heightDecimeters: json['height'] as int,
      weightHectograms: json['weight'] as int,
      types: List<PokemonType>.unmodifiable(types),
      stats: BaseStats.fromApi(json['stats'] as List<dynamic>),
      abilities: List<PokemonAbilitySlot>.unmodifiable(abilities),
      sprites: PokemonSprites.fromApi(json['sprites'] as Map<String, dynamic>),
      isDefault: json['is_default'] as bool? ?? true,
      baseExperience: json['base_experience'] as int?,
      cryLatest: cries['latest'] as String?,
      cryLegacy: cries['legacy'] as String?,
    );
  }

  /// Quita del JSON lo que la app no usa antes de guardarlo en caché
  /// (`moves` y `sprites.versions` pueden ocupar cientos de KB).
  static Map<String, dynamic> reduceForCache(Map<String, dynamic> json) {
    final reduced = Map<String, dynamic>.of(json)
      ..remove('moves')
      ..remove('game_indices')
      ..remove('held_items');
    final sprites = reduced['sprites'];
    if (sprites is Map<String, dynamic>) {
      reduced['sprites'] = Map<String, dynamic>.of(sprites)..remove('versions');
    }
    return reduced;
  }

  final int id;
  final String slug;
  final String speciesSlug;
  final String speciesUrl;
  final int heightDecimeters;
  final int weightHectograms;
  final List<PokemonType> types;
  final BaseStats stats;
  final List<PokemonAbilitySlot> abilities;
  final PokemonSprites sprites;
  final bool isDefault;
  final int? baseExperience;

  /// URLs de los gritos (`cries`). Se usarán en la Fase 5.
  final String? cryLatest;
  final String? cryLegacy;
}
