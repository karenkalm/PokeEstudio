import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/upcoming_feature_view.dart';

/// Mi equipo · se implementa en la Fase 4.
class TeamBuilderScreen extends StatelessWidget {
  const TeamBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UpcomingFeatureView(
      title: 'Mi equipo',
      phase: 4,
      icon: Icons.groups_rounded,
      summary:
          'El Team Builder te permitirá armar equipos de hasta seis Pokémon y entender sus fortalezas y debilidades con cálculos reales de tipos.',
      highlights: <String>[
        'Crear, nombrar, duplicar y reordenar equipos guardados en tu dispositivo.',
        'Matriz de cobertura: debilidades, resistencias e inmunidades combinadas.',
        'Recomendaciones basadas en los cálculos, sin prometer victorias.',
        'Árbol evolutivo con ramas y localizaciones disponibles en PokéAPI.',
      ],
    );
  }
}
