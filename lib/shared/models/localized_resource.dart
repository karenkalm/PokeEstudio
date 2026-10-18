import '../../core/utils/formatters.dart';
import 'pokemon_species.dart';

/// Un texto con el idioma en que realmente está escrito.
class LocalizedText {
  const LocalizedText({required this.text, required this.language});

  final String text;
  final String language;

  bool get isSpanish => language == 'es';
}

/// Recurso con nombres traducidos: habilidad (`/ability`), versión
/// (`/version`), movimiento (`/move`)… Se usa para mostrar nombres en
/// español sin inventar traducciones: si PokéAPI no la tiene, se dice.
class LocalizedResource {
  const LocalizedResource({
    required this.id,
    required this.slug,
    required this.names,
    required this.flavorTexts,
    required this.shortEffects,
  });

  factory LocalizedResource.fromApi(Map<String, dynamic> json) {
    final names = <String, String>{};
    for (final raw in (json['names'] as List<dynamic>?) ?? const <dynamic>[]) {
      final item = raw as Map<String, dynamic>;
      names[(item['language'] as Map<String, dynamic>)['name'] as String] = item['name'] as String;
    }
    final shortEffects = <String, String>{};
    for (final raw in (json['effect_entries'] as List<dynamic>?) ?? const <dynamic>[]) {
      final item = raw as Map<String, dynamic>;
      final text = item['short_effect'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        shortEffects[(item['language'] as Map<String, dynamic>)['name'] as String] = text;
      }
    }
    return LocalizedResource(
      id: json['id'] as int,
      slug: json['name'] as String,
      names: Map<String, String>.unmodifiable(names),
      flavorTexts: List<FlavorTextEntry>.unmodifiable(<FlavorTextEntry>[
        for (final raw in (json['flavor_text_entries'] as List<dynamic>?) ?? const <dynamic>[])
          FlavorTextEntry.fromApi(raw as Map<String, dynamic>),
      ]),
      shortEffects: Map<String, String>.unmodifiable(shortEffects),
    );
  }

  /// Conserva solo lo necesario (nombres, textos y efectos en es/en).
  static Map<String, dynamic> reduceForCache(Map<String, dynamic> json) {
    List<dynamic> onlyEsEn(Object? list) {
      if (list is! List<dynamic>) return const <dynamic>[];
      return list.where((item) {
        if (item is! Map<String, dynamic>) return false;
        final language = (item['language'] as Map<String, dynamic>?)?['name'];
        return language == 'es' || language == 'en';
      }).toList();
    }

    return <String, dynamic>{
      'id': json['id'],
      'name': json['name'],
      'names': onlyEsEn(json['names']),
      'flavor_text_entries': onlyEsEn(json['flavor_text_entries']),
      'effect_entries': onlyEsEn(json['effect_entries']),
    };
  }

  final int id;
  final String slug;
  final Map<String, String> names;
  final List<FlavorTextEntry> flavorTexts;
  final Map<String, String> shortEffects;

  /// Nombre en español; si PokéAPI no lo tiene, el inglés; si tampoco, el
  /// identificador legible.
  LocalizedText get displayName {
    final es = names['es'];
    if (es != null) return LocalizedText(text: es, language: 'es');
    final en = names['en'];
    if (en != null) return LocalizedText(text: en, language: 'en');
    return LocalizedText(text: Formatters.slugToTitle(slug), language: 'slug');
  }

  /// Descripción breve: el texto de juego más reciente en español; si no hay,
  /// el efecto resumido en inglés.
  LocalizedText? get description {
    final spanish = flavorTexts.where((entry) => entry.language == 'es').toList()
      ..sort((a, b) => b.versionOrder.compareTo(a.versionOrder));
    if (spanish.isNotEmpty) {
      return LocalizedText(text: cleanGameText(spanish.first.text), language: 'es');
    }
    final shortEs = shortEffects['es'];
    if (shortEs != null) return LocalizedText(text: cleanGameText(shortEs), language: 'es');
    final shortEn = shortEffects['en'];
    if (shortEn != null) return LocalizedText(text: cleanGameText(shortEn), language: 'en');
    final english = flavorTexts.where((entry) => entry.language == 'en').toList()
      ..sort((a, b) => b.versionOrder.compareTo(a.versionOrder));
    if (english.isNotEmpty) {
      return LocalizedText(text: cleanGameText(english.first.text), language: 'en');
    }
    return null;
  }
}

/// Limpia los textos de los juegos: saltos de línea fijos, saltos de página
/// (`\f`), guiones suaves y la antigua grafía "POKéMON".
String cleanGameText(String raw) {
  return raw
      .replaceAll('­\n', '')
      .replaceAll('­', '')
      .replaceAll(RegExp(r'[\n\f\r]+'), ' ')
      .replaceAll('POKéMON', 'Pokémon')
      .replaceAll(RegExp(r' {2,}'), ' ')
      .trim();
}
