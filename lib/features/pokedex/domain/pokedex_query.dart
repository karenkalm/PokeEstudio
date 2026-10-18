import '../../../core/utils/formatters.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../../shared/models/pokedex_entry.dart';
import '../../../shared/models/pokemon_type.dart';
import 'pokedex_filter.dart';

/// Sugerencia de filtro detectada en el texto de búsqueda ("fuego", "kanto"…).
sealed class SearchSuggestion {
  const SearchSuggestion();
}

final class TypeSuggestion extends SearchSuggestion {
  const TypeSuggestion(this.type);
  final PokemonType type;
}

final class GenerationSuggestion extends SearchSuggestion {
  const GenerationSuggestion(this.generation);
  final int generation;
}

/// Resultado de aplicar búsqueda + filtros + orden.
class PokedexResults {
  const PokedexResults({required this.items, required this.totalInIndex, this.suggestion});

  final List<PokedexEntry> items;
  final int totalInIndex;
  final SearchSuggestion? suggestion;
}

/// Motor de búsqueda y filtrado. Funciones puras, sin red ni estado: se
/// prueban en `test/pokedex_query_test.dart`.
abstract final class PokedexQuery {
  static final RegExp _numberPattern = RegExp(r'^#?\s*0*(\d{1,4})$');
  static final RegExp _generationPattern = RegExp(r'^(?:gen|generacion|g)\s*\.?\s*(\d{1,2}|[ivx]{1,4})$');

  static PokedexResults run(List<PokedexEntry> entries, {required PokedexFilter filter, String query = ''}) {
    final filtered = entries.where((entry) => matchesFilter(entry, filter)).toList();
    final searched = search(filtered, query);
    final hasQuery = query.trim().isNotEmpty;
    // Con texto de búsqueda se respeta la relevancia; sin texto, el orden elegido.
    final items = hasQuery ? searched : sort(searched, filter.sort);
    return PokedexResults(items: items, totalInIndex: entries.length, suggestion: detectSuggestion(query));
  }

  /// Cuántos resultados daría [filter] (vista previa en la hoja de filtros).
  static int count(List<PokedexEntry> entries, {required PokedexFilter filter, String query = ''}) {
    final filtered = entries.where((entry) => matchesFilter(entry, filter)).toList();
    return search(filtered, query).length;
  }

  static bool matchesFilter(PokedexEntry entry, PokedexFilter filter) {
    if (!_matchesTypes(entry, filter)) return false;
    if (filter.generations.isNotEmpty && !filter.generations.contains(entry.generation)) return false;
    if (entry.stats.attack < filter.minAttack) return false;
    if (entry.stats.defense < filter.minDefense) return false;
    if (entry.stats.speed < filter.minSpeed) return false;
    if (entry.stats.total < filter.minTotal) return false;
    if (filter.onlyWithShiny && !entry.hasShinySprite) return false;
    if (filter.onlyWithForms && !entry.hasForms) return false;
    return true;
  }

  static bool _matchesTypes(PokedexEntry entry, PokedexFilter filter) {
    final types = entry.types;
    if (filter.monotypeOnly && types.length != 1) return false;
    switch (filter.typeMatchMode) {
      case TypeMatchMode.anyPosition:
        if (filter.firstType != null && !types.contains(filter.firstType)) return false;
        if (filter.secondType != null && !types.contains(filter.secondType)) return false;
        return true;
      case TypeMatchMode.exactPosition:
        if (filter.firstType != null && types.first != filter.firstType) return false;
        if (filter.secondType != null && (types.length < 2 || types[1] != filter.secondType)) return false;
        return true;
    }
  }

  /// Búsqueda tolerante a acentos, mayúsculas y signos, por nombre en
  /// español o inglés, número y formas alternativas. Ordena por relevancia.
  static List<PokedexEntry> search(List<PokedexEntry> entries, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return entries;

    final numberMatch = _numberPattern.firstMatch(trimmed);
    if (numberMatch != null) {
      final digits = numberMatch.group(1)!;
      final exact = int.parse(digits);
      final ranked = <(int, PokedexEntry)>[];
      for (final entry in entries) {
        if (entry.id == exact) {
          ranked.add((0, entry));
        } else if (entry.id.toString().startsWith(digits)) {
          ranked.add((1, entry));
        }
      }
      return _byRank(ranked);
    }

    final needle = TextNormalizer.compact(trimmed);
    if (needle.isEmpty) return const <PokedexEntry>[];
    final ranked = <(int, PokedexEntry)>[];
    for (final entry in entries) {
      final rank = _nameRank(entry, needle);
      if (rank != null) ranked.add((rank, entry));
    }
    return _byRank(ranked);
  }

  static int? _nameRank(PokedexEntry entry, String needle) {
    final names = <String>[entry.searchNameEs, entry.searchNameEn, entry.searchSlug];
    if (names.any((name) => name == needle)) return 0;
    if (names.any((name) => name.startsWith(needle))) return 1;
    if (names.any((name) => name.contains(needle))) return 2;
    if (entry.searchForms.any((form) => form.contains(needle))) return 3;
    return null;
  }

  static List<PokedexEntry> _byRank(List<(int, PokedexEntry)> ranked) {
    ranked.sort((a, b) {
      final byRank = a.$1.compareTo(b.$1);
      return byRank != 0 ? byRank : a.$2.id.compareTo(b.$2.id);
    });
    return <PokedexEntry>[for (final item in ranked) item.$2];
  }

  static List<PokedexEntry> sort(List<PokedexEntry> entries, PokedexSort sort) {
    final sorted = List<PokedexEntry>.of(entries);
    int byId(PokedexEntry a, PokedexEntry b) => a.id.compareTo(b.id);
    int desc(int a, int b, PokedexEntry x, PokedexEntry y) {
      final value = b.compareTo(a);
      return value != 0 ? value : byId(x, y);
    }

    switch (sort) {
      case PokedexSort.numberAsc:
        sorted.sort(byId);
      case PokedexSort.numberDesc:
        sorted.sort((a, b) => b.id.compareTo(a.id));
      case PokedexSort.nameAsc:
        sorted.sort((a, b) => TextNormalizer.fold(a.nameEs).compareTo(TextNormalizer.fold(b.nameEs)));
      case PokedexSort.nameDesc:
        sorted.sort((a, b) => TextNormalizer.fold(b.nameEs).compareTo(TextNormalizer.fold(a.nameEs)));
      case PokedexSort.totalDesc:
        sorted.sort((a, b) => desc(a.stats.total, b.stats.total, a, b));
      case PokedexSort.attackDesc:
        sorted.sort((a, b) => desc(a.stats.attack, b.stats.attack, a, b));
      case PokedexSort.defenseDesc:
        sorted.sort((a, b) => desc(a.stats.defense, b.stats.defense, a, b));
      case PokedexSort.speedDesc:
        sorted.sort((a, b) => desc(a.stats.speed, b.stats.speed, a, b));
    }
    return sorted;
  }

  /// Detecta si el texto es un tipo ("fuego", "fire"), una región ("kanto")
  /// o una generación ("gen 3", "generación iv").
  static SearchSuggestion? detectSuggestion(String query) {
    final folded = TextNormalizer.fold(query.trim());
    if (folded.isEmpty) return null;
    final compact = TextNormalizer.compact(folded);
    for (final type in PokemonType.values) {
      if (compact == TextNormalizer.compact(type.spanishName) || compact == type.slug) {
        return TypeSuggestion(type);
      }
    }
    for (final entry in Generations.regionNames.entries) {
      if (compact == TextNormalizer.compact(entry.value)) return GenerationSuggestion(entry.key);
    }
    final match = _generationPattern.firstMatch(folded);
    if (match != null) {
      final raw = match.group(1)!;
      final generation = int.tryParse(raw) ?? _romanToInt(raw);
      if (generation != null && Generations.regionNames.containsKey(generation)) {
        return GenerationSuggestion(generation);
      }
    }
    return null;
  }

  static int? _romanToInt(String roman) {
    for (var i = 1; i <= 10; i++) {
      if (Formatters.roman(i).toLowerCase() == roman) return i;
    }
    return null;
  }
}
