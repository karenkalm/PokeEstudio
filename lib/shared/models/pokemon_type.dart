/// Los 18 tipos jugables, en el orden en que los muestran los juegos actuales.
///
/// Los nombres en español coinciden con `/type/{id}` → `names` (idioma `es`)
/// de PokéAPI. Los tipos especiales `stellar`, `unknown` y `shadow` no se
/// incluyen porque no tienen relaciones de daño ni especies asociadas.
enum PokemonType {
  normal('normal', 'Normal', 'Normal'),
  fire('fire', 'Fuego', 'Fire'),
  water('water', 'Agua', 'Water'),
  grass('grass', 'Planta', 'Grass'),
  electric('electric', 'Eléctrico', 'Electric'),
  ice('ice', 'Hielo', 'Ice'),
  fighting('fighting', 'Lucha', 'Fighting'),
  poison('poison', 'Veneno', 'Poison'),
  ground('ground', 'Tierra', 'Ground'),
  flying('flying', 'Volador', 'Flying'),
  psychic('psychic', 'Psíquico', 'Psychic'),
  bug('bug', 'Bicho', 'Bug'),
  rock('rock', 'Roca', 'Rock'),
  ghost('ghost', 'Fantasma', 'Ghost'),
  dragon('dragon', 'Dragón', 'Dragon'),
  dark('dark', 'Siniestro', 'Dark'),
  steel('steel', 'Acero', 'Steel'),
  fairy('fairy', 'Hada', 'Fairy');

  const PokemonType(this.slug, this.spanishName, this.englishName);

  /// Identificador de PokéAPI (`fire`).
  final String slug;
  final String spanishName;
  final String englishName;

  static final Map<String, PokemonType> _bySlug = <String, PokemonType>{
    for (final type in PokemonType.values) type.slug: type,
  };

  /// Devuelve `null` para tipos desconocidos en lugar de inventar uno.
  static PokemonType? fromSlug(String slug) => _bySlug[slug];
}
