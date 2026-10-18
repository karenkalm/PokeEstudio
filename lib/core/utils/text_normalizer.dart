/// Normalización de texto para búsquedas tolerantes.
abstract final class TextNormalizer {
  static const Map<String, String> _accents = <String, String>{
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n', 'ç': 'c',
  };

  static final RegExp _nonAlphanumeric = RegExp(r'[^a-z0-9]+');

  /// Minúsculas y sin acentos. `Código Cero` → `codigo cero`.
  static String fold(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  /// Forma compacta para comparar: sin acentos, sin espacios ni signos.
  /// `Mr. Mime` → `mrmime`, `Type: Null` → `typenull`, `Nidoran♀` → `nidoran`.
  static String compact(String input) => fold(input).replaceAll(_nonAlphanumeric, '');
}
