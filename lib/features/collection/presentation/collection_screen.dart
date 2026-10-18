import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/upcoming_feature_view.dart';

/// Mi colección · se implementa en la Fase 3.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UpcomingFeatureView(
      title: 'Mi colección',
      phase: 3,
      icon: Icons.collections_bookmark_rounded,
      summary:
          'Tu registro personal, sin cuenta y guardado en tu dispositivo. Distinto de la Pokédex oficial: aquí anotas lo que tú tienes.',
      highlights: <String>[
        'Marcar Pokémon como capturados, favoritos, pendientes u objetivos.',
        'Registro de variocolor (shiny) conseguidos.',
        'Progreso total y por generación con porcentajes.',
        'Filtros y orden dentro de tu colección.',
      ],
    );
  }
}
