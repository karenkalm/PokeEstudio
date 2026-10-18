import 'package:flutter_test/flutter_test.dart';
import 'package:pokestudio/shared/domain/type_chart.dart';
import 'package:pokestudio/shared/domain/type_chart_data.dart';
import 'package:pokestudio/shared/models/pokemon_type.dart';

void main() {
  group('Tabla de tipos', () {
    test('cubre los 18 tipos y no repite un tipo en dos categorías', () {
      for (final attacking in PokemonType.values) {
        final superEffective = kSuperEffectiveAgainst[attacking]!;
        final half = kNotVeryEffectiveAgainst[attacking]!;
        final none = kNoEffectAgainst[attacking]!;
        expect(superEffective.intersection(half), isEmpty, reason: '$attacking');
        expect(superEffective.intersection(none), isEmpty, reason: '$attacking');
        expect(half.intersection(none), isEmpty, reason: '$attacking');
      }
    });

    test('casos conocidos de un solo tipo', () {
      expect(TypeChart.effectiveness(PokemonType.water, PokemonType.fire), 2);
      expect(TypeChart.effectiveness(PokemonType.fire, PokemonType.water), 0.5);
      expect(TypeChart.effectiveness(PokemonType.normal, PokemonType.ghost), 0);
      expect(TypeChart.effectiveness(PokemonType.ghost, PokemonType.normal), 0);
      expect(TypeChart.effectiveness(PokemonType.electric, PokemonType.ground), 0);
      expect(TypeChart.effectiveness(PokemonType.ground, PokemonType.flying), 0);
      expect(TypeChart.effectiveness(PokemonType.dragon, PokemonType.fairy), 0);
      expect(TypeChart.effectiveness(PokemonType.poison, PokemonType.steel), 0);
      expect(TypeChart.effectiveness(PokemonType.psychic, PokemonType.dark), 0);
      expect(TypeChart.effectiveness(PokemonType.fairy, PokemonType.dragon), 2);
      expect(TypeChart.effectiveness(PokemonType.normal, PokemonType.normal), 1);
    });
  });

  group('Doble tipo', () {
    test('Charizard (Fuego/Volador): ×4 Roca, inmune a Tierra', () {
      final m = TypeChart.matchups(<PokemonType>[PokemonType.fire, PokemonType.flying]);
      expect(m.quadrupleWeak, <PokemonType>[PokemonType.rock]);
      expect(m.doubleWeak.toSet(), <PokemonType>{PokemonType.water, PokemonType.electric});
      expect(m.immune, <PokemonType>[PokemonType.ground]);
      expect(m.quarterResist.toSet(), <PokemonType>{PokemonType.grass, PokemonType.bug});
      expect(
        m.halfResist.toSet(),
        <PokemonType>{PokemonType.fire, PokemonType.fighting, PokemonType.steel, PokemonType.fairy},
      );
      // Hielo: ×2 contra Volador y ×½ contra Fuego → neutro.
      expect(TypeChart.effectivenessAgainst(PokemonType.ice, <PokemonType>[PokemonType.fire, PokemonType.flying]), 1);
    });

    test('Gyarados (Agua/Volador): ×4 Eléctrico', () {
      final m = TypeChart.matchups(<PokemonType>[PokemonType.water, PokemonType.flying]);
      expect(m.quadrupleWeak, <PokemonType>[PokemonType.electric]);
      expect(m.doubleWeak, <PokemonType>[PokemonType.rock]);
      expect(m.immune, <PokemonType>[PokemonType.ground]);
      expect(m.quarterResist, isEmpty);
      expect(
        m.halfResist.toSet(),
        <PokemonType>{PokemonType.fire, PokemonType.water, PokemonType.fighting, PokemonType.bug, PokemonType.steel},
      );
    });

    test('Pikachu (Eléctrico): solo débil a Tierra', () {
      final m = TypeChart.matchups(<PokemonType>[PokemonType.electric]);
      expect(m.weaknesses, <PokemonType>[PokemonType.ground]);
      expect(m.resistances.toSet(), <PokemonType>{PokemonType.electric, PokemonType.flying, PokemonType.steel});
      expect(m.immune, isEmpty);
    });

    test('el perfil defensivo siempre devuelve los 18 tipos', () {
      final profile = TypeChart.defensiveProfile(<PokemonType>[PokemonType.steel, PokemonType.fairy]);
      expect(profile.length, PokemonType.values.length);
      expect(profile[PokemonType.poison], 0);
      expect(profile[PokemonType.dragon], 0);
      expect(profile[PokemonType.ground], 2);
      expect(profile[PokemonType.fire], 2);
      expect(profile[PokemonType.bug], 0.25);
    });
  });
}
