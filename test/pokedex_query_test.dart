import 'package:flutter_test/flutter_test.dart';
import 'package:pokestudio/core/utils/text_normalizer.dart';
import 'package:pokestudio/features/pokedex/domain/pokedex_filter.dart';
import 'package:pokestudio/features/pokedex/domain/pokedex_query.dart';
import 'package:pokestudio/shared/models/pokedex_entry.dart';
import 'package:pokestudio/shared/models/pokemon_type.dart';

import 'helpers/test_data.dart';

void main() {
  late PokedexIndex index;
  late List<PokedexEntry> all;

  setUpAll(() {
    index = loadRealIndex();
    all = index.entries;
  });

  List<String> names(List<PokedexEntry> entries) => <String>[for (final e in entries) e.nameEs];

  group('Índice empaquetado', () {
    test('contiene las 1025 especies ordenadas y sin huecos', () {
      expect(index.count, 1025);
      for (var i = 0; i < all.length; i++) {
        expect(all[i].id, i + 1);
      }
      expect(index.generations, <int>[1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(index.countForGeneration(1), 151);
    });

    test('incluye nombres en español distintos del inglés', () {
      final typeNull = index.byId(772)!;
      expect(typeNull.nameEs, 'Código Cero');
      expect(typeNull.nameEn, 'Type: Null');
      expect(index.byId(984)!.nameEs, 'Colmilargo');
    });

    test('las URLs de imagen vienen de los datos y apuntan al repositorio de sprites', () {
      final pikachu = index.byId(25)!;
      expect(pikachu.spriteUrl, 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png');
      expect(pikachu.artworkUrl, endsWith('/other/official-artwork/25.png'));
      expect(pikachu.types, <PokemonType>[PokemonType.electric]);
    });
  });

  group('Normalización', () {
    test('quita acentos, signos y espacios', () {
      expect(TextNormalizer.compact('Código Cero'), 'codigocero');
      expect(TextNormalizer.compact('Mr. Mime'), 'mrmime');
      expect(TextNormalizer.compact('Nidoran♀'), 'nidoran');
      expect(TextNormalizer.fold('ELÉCTRICO'), 'electrico');
    });
  });

  group('Búsqueda', () {
    test('por nombre en español, sin acentos ni mayúsculas', () {
      expect(names(PokedexQuery.search(all, 'codigo cero')).first, 'Código Cero');
    });

    test('por nombre en inglés', () {
      expect(names(PokedexQuery.search(all, 'type: null')).first, 'Código Cero');
      expect(names(PokedexQuery.search(all, 'great tusk')).first, 'Colmilargo');
    });

    test('coincidencias parciales, primero las que empiezan igual', () {
      final results = PokedexQuery.search(all, 'mr mi');
      expect(names(results), contains('Mr. Mime'));
      final pika = names(PokedexQuery.search(all, 'pika'));
      expect(pika.first, 'Pikachu');
    });

    test('por número, con o sin # y ceros', () {
      for (final query in <String>['25', '#025', '025', ' #25 ']) {
        final results = PokedexQuery.search(all, query);
        expect(results.first.id, 25, reason: query);
      }
      // Después del exacto, los números que empiezan igual.
      expect(<int>[for (final e in PokedexQuery.search(all, '25')) e.id],
          <int>[25, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259]);
    });

    test('por forma alternativa ("alola")', () {
      final results = PokedexQuery.search(all, 'alola');
      expect(results.length, 19);
      expect(names(results), containsAll(<String>['Rattata', 'Vulpix', 'Raichu']));
    });

    test('sin coincidencias devuelve vacío', () {
      expect(PokedexQuery.search(all, 'zzzzzz'), isEmpty);
      expect(PokedexQuery.search(all, '♀♂'), isEmpty);
    });

    test('detecta sugerencias de tipo y de generación', () {
      expect(PokedexQuery.detectSuggestion('Fuego'), isA<TypeSuggestion>());
      expect((PokedexQuery.detectSuggestion('electrico') as TypeSuggestion).type, PokemonType.electric);
      expect((PokedexQuery.detectSuggestion('kanto') as GenerationSuggestion).generation, 1);
      expect((PokedexQuery.detectSuggestion('gen 4') as GenerationSuggestion).generation, 4);
      expect((PokedexQuery.detectSuggestion('Generación IV') as GenerationSuggestion).generation, 4);
      expect(PokedexQuery.detectSuggestion('pikachu'), isNull);
    });
  });

  group('Filtros', () {
    int count(PokedexFilter filter) => PokedexQuery.count(all, filter: filter);

    test('tipo en cualquier posición vs. posición exacta', () {
      expect(count(const PokedexFilter(firstType: PokemonType.fire)), 81);
      expect(
        count(const PokedexFilter(firstType: PokemonType.fire, typeMatchMode: TypeMatchMode.exactPosition)),
        66,
      );
    });

    test('combinación de dos tipos', () {
      const filter = PokedexFilter(
        firstType: PokemonType.fire,
        secondType: PokemonType.flying,
        typeMatchMode: TypeMatchMode.exactPosition,
      );
      final results = PokedexQuery.run(all, filter: filter).items;
      expect(names(results), <String>['Charizard', 'Moltres', 'Ho-Oh', 'Fletchinder', 'Talonflame', 'Oricorio']);
      // En orden invertido (Volador/Fuego) no hay ninguno.
      expect(
        count(const PokedexFilter(
          firstType: PokemonType.flying,
          secondType: PokemonType.fire,
          typeMatchMode: TypeMatchMode.exactPosition,
        )),
        0,
      );
    });

    test('generación y monotipo', () {
      expect(count(const PokedexFilter(generations: <int>{1})), 151);
      expect(count(const PokedexFilter(generations: <int>{1}, monotypeOnly: true)), 84);
    });

    test('estadísticas mínimas', () {
      final fast = PokedexQuery.run(all, filter: const PokedexFilter(minSpeed: 150, sort: PokedexSort.speedDesc)).items;
      expect(names(fast), <String>['Regieleki', 'Ninjask', 'Pheromosa', 'Electrode', 'Deoxys']);
      expect(count(const PokedexFilter(minTotal: 700)), 1); // Arceus (720)
    });

    test('formas alternativas', () {
      final withForms = PokedexQuery.run(all, filter: const PokedexFilter(onlyWithForms: true)).items;
      expect(withForms.every((e) => e.forms.isNotEmpty), isTrue);
      expect(withForms.length, 224);
    });

    test('filtros + búsqueda', () {
      final results = PokedexQuery.run(
        all,
        filter: const PokedexFilter(generations: <int>{1}),
        query: 'alola',
      );
      expect(results.items.every((e) => e.generation == 1), isTrue);
      // Las 19 especies con forma de Alola son de la Gen. I.
      expect(results.items.length, 19);
    });

    test('activeCount y cleared conservan el orden', () {
      const filter = PokedexFilter(
        firstType: PokemonType.water,
        generations: <int>{3},
        minAttack: 50,
        sort: PokedexSort.nameAsc,
      );
      expect(filter.activeCount, 3);
      expect(filter.cleared().hasActiveFilters, isFalse);
      expect(filter.cleared().sort, PokedexSort.nameAsc);
      expect(filter.copyWith(firstType: null).firstType, isNull);
      expect(filter.copyWith(minDefense: 10).firstType, PokemonType.water);
    });
  });

  group('Orden', () {
    test('por número descendente', () {
      final sorted = PokedexQuery.sort(all, PokedexSort.numberDesc);
      expect(sorted.first.id, 1025);
    });

    test('por total de estadísticas', () {
      final sorted = PokedexQuery.sort(all, PokedexSort.totalDesc);
      expect(sorted.first.nameEs, 'Arceus');
    });

    test('alfabético ignora acentos', () {
      final sorted = PokedexQuery.sort(all, PokedexSort.nameAsc);
      final folded = <String>[for (final e in sorted) TextNormalizer.fold(e.nameEs)];
      final copy = List<String>.of(folded)..sort();
      expect(folded, copy);
    });
  });
}
