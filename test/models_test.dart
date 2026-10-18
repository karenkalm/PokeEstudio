import 'package:flutter_test/flutter_test.dart';
import 'package:pokestudio/features/pokemon_detail/domain/pokedex_texts.dart';
import 'package:pokestudio/shared/models/base_stats.dart';
import 'package:pokestudio/shared/models/localized_resource.dart';
import 'package:pokestudio/shared/models/pokemon_detail.dart';
import 'package:pokestudio/shared/models/pokemon_species.dart';
import 'package:pokestudio/shared/models/pokemon_type.dart';

import 'helpers/test_data.dart';

void main() {
  group('PokemonDetail (/pokemon/25)', () {
    late PokemonDetail pikachu;

    setUpAll(() => pikachu = PokemonDetail.fromApi(fixture('pokemon_25.json')));

    test('datos básicos', () {
      expect(pikachu.id, 25);
      expect(pikachu.slug, 'pikachu');
      expect(pikachu.heightDecimeters, 4);
      expect(pikachu.weightHectograms, 60);
      expect(pikachu.types, <PokemonType>[PokemonType.electric]);
    });

    test('estadísticas en el orden oficial', () {
      expect(pikachu.stats.toList(), <int>[35, 55, 40, 50, 50, 90]);
      expect(pikachu.stats[StatKind.speed], 90);
      expect(pikachu.stats.total, 320);
    });

    test('habilidades con la oculta marcada', () {
      expect(pikachu.abilities.map((a) => a.slug), <String>['static', 'lightning-rod']);
      expect(pikachu.abilities.last.isHidden, isTrue);
    });

    test('sprites reales (sin URLs inventadas)', () {
      expect(pikachu.sprites.frontDefault, endsWith('/sprites/pokemon/25.png'));
      expect(pikachu.sprites.artwork, endsWith('/other/official-artwork/25.png'));
      expect(pikachu.sprites.animated, endsWith('/other/showdown/25.gif'));
      expect(pikachu.cryLatest, endsWith('/cries/pokemon/latest/25.ogg'));
    });

    test('Charizard tiene dos tipos en orden de slot', () {
      final charizard = PokemonDetail.fromApi(fixture('pokemon_6.json'));
      expect(charizard.types, <PokemonType>[PokemonType.fire, PokemonType.flying]);
    });

    test('reduceForCache elimina campos pesados', () {
      final json = <String, dynamic>{
        ...fixture('pokemon_25.json'),
        'moves': <dynamic>[1, 2, 3],
        'game_indices': <dynamic>[1],
      };
      (json['sprites'] as Map<String, dynamic>)['versions'] = <String, dynamic>{'x': 1};
      final reduced = PokemonDetail.reduceForCache(json);
      expect(reduced.containsKey('moves'), isFalse);
      expect(reduced.containsKey('game_indices'), isFalse);
      expect((reduced['sprites'] as Map<String, dynamic>).containsKey('versions'), isFalse);
      // Sigue siendo parseable.
      expect(PokemonDetail.fromApi(reduced).id, 25);
    });

    test('un JSON sin tipos válidos no se rellena con datos inventados', () {
      final json = <String, dynamic>{...fixture('pokemon_25.json'), 'types': <dynamic>[]};
      expect(() => PokemonDetail.fromApi(json), throwsFormatException);
    });
  });

  group('PokemonSpecies', () {
    test('Pikachu: nombres, categoría, generación y formas', () {
      final species = PokemonSpecies.fromApi(fixture('pokemon_species_25.json'));
      expect(species.nameEs, 'Pikachu');
      expect(species.genera['es'], 'Pokémon Ratón');
      expect(species.generation, 1);
      expect(species.alternateVarieties.length, 16);
      expect(species.evolutionChainUrl, contains('evolution-chain/10'));
      expect(speciesGenus(species)!.isSpanish, isTrue);
    });

    test('las descripciones en español van de la más nueva a la más antigua y sin duplicados', () {
      final species = PokemonSpecies.fromApi(fixture('pokemon_species_25.json'));
      final descriptions = pokedexDescriptions(species.flavorTexts);
      expect(descriptions, isNotEmpty);
      expect(descriptions.every((d) => d.isSpanish), isTrue);
      expect(descriptions.first.versionSlug, 'shield');
      final texts = descriptions.map((d) => d.text.toLowerCase()).toList();
      expect(texts.toSet().length, texts.length);
      expect(descriptions.first.text.contains('\n'), isFalse);
    });

    test('Sprigatito (#906) no tiene textos en español: se usa inglés y se indica', () {
      final species = PokemonSpecies.fromApi(fixture('pokemon_species_906.json'));
      final descriptions = pokedexDescriptions(species.flavorTexts);
      expect(descriptions, isNotEmpty);
      expect(descriptions.first.isSpanish, isFalse);
      expect(speciesGenus(species)!.isSpanish, isFalse);
      expect(species.generation, 9);
    });

    test('generationFromSlug', () {
      expect(PokemonSpecies.generationFromSlug('generation-iv'), 4);
      expect(PokemonSpecies.generationFromSlug('generation-ix'), 9);
      expect(() => PokemonSpecies.generationFromSlug('generation-zz'), throwsFormatException);
    });
  });

  group('LocalizedResource', () {
    test('habilidad con nombre y descripción en español', () {
      final ability = LocalizedResource.fromApi(fixture('ability_9.json'));
      expect(ability.displayName.text, 'Electricidad Estática');
      expect(ability.displayName.isSpanish, isTrue);
      final description = ability.description!;
      expect(description.isSpanish, isTrue);
      expect(description.text, isNot(contains('\n')));
    });

    test('versión', () {
      final version = LocalizedResource.fromApi(fixture('version_23.json'));
      expect(version.displayName.text, 'X');
    });

    test('sin traducción se usa el identificador legible, sin inventar', () {
      final resource = LocalizedResource.fromApi(<String, dynamic>{'id': 1, 'name': 'some-thing'});
      expect(resource.displayName.text, 'Some Thing');
      expect(resource.displayName.language, 'slug');
      expect(resource.description, isNull);
    });
  });

  test('cleanGameText limpia saltos y guiones suaves', () {
    expect(cleanGameText('Una\nlínea\fcon­\nsalto'), 'Una línea consalto');
    expect(cleanGameText('El POKéMON'), 'El Pokémon');
  });
}
