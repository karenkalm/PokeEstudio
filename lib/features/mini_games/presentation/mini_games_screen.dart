import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/upcoming_feature_view.dart';

/// Minijuegos · se implementan en la Fase 6.
class MiniGamesScreen extends StatelessWidget {
  const MiniGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UpcomingFeatureView(
      title: 'Minijuegos',
      phase: 6,
      icon: Icons.sports_esports_rounded,
      summary: '¿Quién es ese Pokémon? en dos modos, con puntuaciones y récords guardados en tu dispositivo.',
      highlights: <String>[
        'Modo silueta: identifica al Pokémon entre cuatro opciones.',
        'Modo audio: reconócelo solo por su grito.',
        'Dificultad fácil, intermedia y difícil, con filtro por generación.',
        'Rachas, récord personal, desafío diario e historial de partidas.',
      ],
    );
  }
}
