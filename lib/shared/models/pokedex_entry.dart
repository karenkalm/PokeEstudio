import '../../core/utils/text_normalizer.dart';
import 'base_stats.dart';
import 'pokemon_type.dart';

/// Una especie dentro del índice local de la Pokédex.
///
/// Se construye a partir de `assets/data/pokedex_index.json` (generado con
/// datos reales de PokéAPI) y permite buscar y filtrar sin red.
class PokedexEntry {
  PokedexEntry({
    required this.id,
    required this.pokemonId,
    required this.slug,
    required this.nameEs,
    required this.nameEn,
    required this.generation,
    required this.types,
    required this.stats,
    required this.spriteUrl,
    required this.shinySpriteUrl,
    required this.artworkUrl,
    required this.forms,
    this.isLegendary = false,
    this.isMythical = false,
    this.isBaby = false,
  })  : searchNameEs = TextNormalizer.compact(nameEs),
        searchNameEn = TextNormalizer.compact(nameEn),
        searchSlug = TextNormalizer.compact(slug),
        searchForms = <String>[for (final form in forms) TextNormalizer.compact(form)];

  factory PokedexEntry.fromIndexJson(Map<String, dynamic> json, {required String spriteBase}) {
    String? resolve(Object? path) {
      if (path is! String || path.isEmpty) return null;
      return path.startsWith('http') ? path : '$spriteBase$path';
    }

    final types = <PokemonType>[];
    for (final slug in (json['types'] as List<dynamic>).cast<String>()) {
      final type = PokemonType.fromSlug(slug);
      if (type != null) types.add(type);
    }
    if (types.isEmpty) {
      throw FormatException('La especie ${json['id']} no tiene tipos válidos.');
    }

    return PokedexEntry(
      id: json['id'] as int,
      pokemonId: (json['pokemonId'] as int?) ?? json['id'] as int,
      slug: json['slug'] as String,
      nameEs: json['es'] as String,
      nameEn: json['en'] as String,
      generation: json['gen'] as int,
      types: List<PokemonType>.unmodifiable(types),
      stats: BaseStats.fromList((json['stats'] as List<dynamic>).cast<int>()),
      spriteUrl: resolve(json['sprite']),
      shinySpriteUrl: resolve(json['shiny']),
      artworkUrl: resolve(json['artwork']),
      forms: List<String>.unmodifiable(((json['forms'] as List<dynamic>?) ?? const <dynamic>[]).cast<String>()),
      isLegendary: json['legendary'] == true,
      isMythical: json['mythical'] == true,
      isBaby: json['baby'] == true,
    );
  }

  Map<String, dynamic> toIndexJson() => <String, dynamic>{
        'id': id,
        'pokemonId': pokemonId,
        'slug': slug,
        'es': nameEs,
        'en': nameEn,
        'gen': generation,
        'types': <String>[for (final type in types) type.slug],
        'stats': stats.toList(),
        'sprite': spriteUrl,
        'shiny': shinySpriteUrl,
        'artwork': artworkUrl,
        'forms': forms,
        if (isLegendary) 'legendary': true,
        if (isMythical) 'mythical': true,
        if (isBaby) 'baby': true,
      };

  /// Número de la Pokédex Nacional (id de la especie).
  final int id;

  /// Id de la variedad por defecto en `/pokemon/{id}`.
  final int pokemonId;
  final String slug;
  final String nameEs;
  final String nameEn;
  final int generation;
  final List<PokemonType> types;
  final BaseStats stats;
  final String? spriteUrl;
  final String? shinySpriteUrl;
  final String? artworkUrl;

  /// Identificadores de las variedades no predeterminadas (formas regionales,
  /// megaevoluciones, Gigamax…).
  final List<String> forms;
  final bool isLegendary;
  final bool isMythical;
  final bool isBaby;

  // Claves precalculadas para la búsqueda.
  final String searchNameEs;
  final String searchNameEn;
  final String searchSlug;
  final List<String> searchForms;

  PokemonType get primaryType => types.first;
  PokemonType? get secondaryType => types.length > 1 ? types[1] : null;
  bool get hasForms => forms.isNotEmpty;
  bool get hasShinySprite => shinySpriteUrl != null;

  @override
  bool operator ==(Object other) => other is PokedexEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// El índice completo cargado en memoria.
class PokedexIndex {
  factory PokedexIndex({
    required List<PokedexEntry> entries,
    required String source,
    required String generatedAt,
  }) {
    final sorted = <PokedexEntry>[...entries]..sort((a, b) => a.id.compareTo(b.id));
    return PokedexIndex._(List<PokedexEntry>.unmodifiable(sorted), source, generatedAt);
  }

  PokedexIndex._(this.entries, this.source, this.generatedAt)
      : _byId = <int, PokedexEntry>{for (final entry in entries) entry.id: entry};

  factory PokedexIndex.fromJson(Map<String, dynamic> json) {
    final spriteBase = json['spriteBase'] as String;
    final entries = <PokedexEntry>[
      for (final raw in json['entries'] as List<dynamic>)
        PokedexEntry.fromIndexJson(raw as Map<String, dynamic>, spriteBase: spriteBase),
    ];
    return PokedexIndex(
      entries: entries,
      source: (json['source'] as String?) ?? 'PokéAPI',
      generatedAt: (json['generatedAt'] as String?) ?? '',
    );
  }

  final List<PokedexEntry> entries;
  final String source;
  final String generatedAt;
  final Map<int, PokedexEntry> _byId;

  int get count => entries.length;
  int get maxId => entries.isEmpty ? 0 : entries.last.id;

  PokedexEntry? byId(int id) => _byId[id];

  /// Generaciones presentes, ordenadas.
  List<int> get generations {
    final set = <int>{for (final entry in entries) entry.generation};
    return set.toList()..sort();
  }

  int countForGeneration(int generation) => entries.where((e) => e.generation == generation).length;

  /// Devuelve un índice nuevo con [extra] añadido (sin duplicar ids).
  PokedexIndex withEntries(List<PokedexEntry> extra) {
    final merged = <int, PokedexEntry>{for (final entry in entries) entry.id: entry};
    for (final entry in extra) {
      merged[entry.id] = entry;
    }
    return PokedexIndex(entries: merged.values.toList(), source: source, generatedAt: generatedAt);
  }
}
