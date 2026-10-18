/// Formatos de presentación compartidos.
abstract final class Formatters {
  /// `25` → `#025`; a partir de 1000 no se rellena: `#1025`.
  static String dexNumber(int id) => '#${id.toString().padLeft(3, '0')}';

  /// PokéAPI expresa la altura en decímetros. `4` → `0.4 m`.
  static String heightMeters(int decimeters) => '${(decimeters / 10).toStringAsFixed(1)} m';

  /// PokéAPI expresa el peso en hectogramos. `60` → `6.0 kg`.
  static String weightKg(int hectograms) => '${(hectograms / 10).toStringAsFixed(1)} kg';

  static const List<String> _roman = <String>['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];

  static String roman(int value) =>
      value >= 1 && value <= _roman.length ? _roman[value - 1] : value.toString();

  /// Convierte un identificador de PokéAPI en un texto legible. Solo se usa
  /// cuando PokéAPI no ofrece un nombre traducido.
  /// `pikachu-rock-star` → `Pikachu Rock Star`.
  static String slugToTitle(String slug) {
    return slug
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  /// `1234567` → `1.2 MB`.
  static String bytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Regiones principales de cada generación (nombres oficiales en español).
abstract final class Generations {
  static const Map<int, String> regionNames = <int, String>{
    1: 'Kanto',
    2: 'Johto',
    3: 'Hoenn',
    4: 'Sinnoh',
    5: 'Teselia',
    6: 'Kalos',
    7: 'Alola',
    8: 'Galar',
    9: 'Paldea',
  };

  static String label(int generation) {
    final region = regionNames[generation];
    final roman = Formatters.roman(generation);
    return region == null ? 'Gen. $roman' : 'Gen. $roman · $region';
  }
}
