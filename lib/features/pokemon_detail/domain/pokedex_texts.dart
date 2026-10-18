import '../../../shared/models/localized_resource.dart';
import '../../../shared/models/pokemon_species.dart';

/// Una descripción de la Pokédex lista para mostrar.
class PokedexDescription {
  const PokedexDescription({required this.text, required this.language, this.versionSlug, this.versionUrl});

  final String text;

  /// Idioma real del texto (`es` o `en`).
  final String language;
  final String? versionSlug;
  final String? versionUrl;

  bool get isSpanish => language == 'es';
}

/// Descripciones de la Pokédex, de la versión más reciente a la más antigua.
///
/// * Usa las entradas en español si existen.
/// * Si PokéAPI no tiene ninguna en español (ocurre con 127 especies, de la
///   #899 en adelante), devuelve las inglesas para que la interfaz lo indique.
/// * Elimina textos repetidos entre versiones (conserva el más reciente).
List<PokedexDescription> pokedexDescriptions(List<FlavorTextEntry> entries) {
  var source = entries.where((e) => e.language == 'es').toList();
  if (source.isEmpty) {
    source = entries.where((e) => e.language == 'en').toList();
  }
  source.sort((a, b) => b.versionOrder.compareTo(a.versionOrder));

  final seen = <String>{};
  final result = <PokedexDescription>[];
  for (final entry in source) {
    final text = cleanGameText(entry.text);
    if (text.isEmpty || !seen.add(text.toLowerCase())) continue;
    result.add(PokedexDescription(
      text: text,
      language: entry.language,
      versionSlug: entry.versionSlug,
      versionUrl: entry.versionUrl,
    ));
  }
  return result;
}

/// Categoría ("Pokémon Ratón") en español o, si no existe, en inglés.
LocalizedText? speciesGenus(PokemonSpecies species) {
  final es = species.genera['es'];
  if (es != null) return LocalizedText(text: es, language: 'es');
  final en = species.genera['en'];
  if (en != null) return LocalizedText(text: en, language: 'en');
  return null;
}
