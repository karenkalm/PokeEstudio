import '../models/pokemon_type.dart';
import 'type_chart_data.dart';

/// Cálculos de efectividad de tipos (tabla vigente, Gen. VI en adelante).
///
/// Solo considera tipos: no incluye habilidades (Levitación, Absorbe Agua…),
/// objetos ni climas. La interfaz lo indica para no prometer de más.
abstract final class TypeChart {
  /// Multiplicador de un tipo atacante contra un único tipo defensor.
  static double effectiveness(PokemonType attacking, PokemonType defending) {
    if (kNoEffectAgainst[attacking]!.contains(defending)) return 0;
    if (kSuperEffectiveAgainst[attacking]!.contains(defending)) return 2;
    if (kNotVeryEffectiveAgainst[attacking]!.contains(defending)) return 0.5;
    return 1;
  }

  /// Multiplicador contra un Pokémon de uno o dos tipos (se multiplican).
  static double effectivenessAgainst(PokemonType attacking, List<PokemonType> defendingTypes) {
    var multiplier = 1.0;
    for (final defending in defendingTypes) {
      multiplier *= effectiveness(attacking, defending);
    }
    return multiplier;
  }

  /// Multiplicador recibido de cada uno de los 18 tipos.
  static Map<PokemonType, double> defensiveProfile(List<PokemonType> defendingTypes) {
    return <PokemonType, double>{
      for (final attacking in PokemonType.values) attacking: effectivenessAgainst(attacking, defendingTypes),
    };
  }

  /// Agrupa el perfil defensivo por multiplicador (×4, ×2, ×½, ×¼, ×0).
  /// Los tipos neutros (×1) no se incluyen.
  static DefensiveMatchups matchups(List<PokemonType> defendingTypes) {
    final profile = defensiveProfile(defendingTypes);
    List<PokemonType> collect(bool Function(double value) test) => <PokemonType>[
          for (final entry in profile.entries)
            if (test(entry.value)) entry.key,
        ];
    return DefensiveMatchups(
      quadrupleWeak: collect((v) => v == 4),
      doubleWeak: collect((v) => v == 2),
      halfResist: collect((v) => v == 0.5),
      quarterResist: collect((v) => v == 0.25),
      immune: collect((v) => v == 0),
    );
  }
}

/// Resultado agrupado de [TypeChart.matchups].
class DefensiveMatchups {
  const DefensiveMatchups({
    required this.quadrupleWeak,
    required this.doubleWeak,
    required this.halfResist,
    required this.quarterResist,
    required this.immune,
  });

  final List<PokemonType> quadrupleWeak;
  final List<PokemonType> doubleWeak;
  final List<PokemonType> halfResist;
  final List<PokemonType> quarterResist;
  final List<PokemonType> immune;

  List<PokemonType> get weaknesses => <PokemonType>[...quadrupleWeak, ...doubleWeak];
  List<PokemonType> get resistances => <PokemonType>[...halfResist, ...quarterResist];
}
