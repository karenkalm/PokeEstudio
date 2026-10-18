import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/models/pokedex_entry.dart';
import '../../../../shared/widgets/feedback_views.dart';
import '../../../../shared/widgets/pokemon_card.dart';

/// Fila horizontal con los últimos Pokémon consultados.
class RecentStrip extends StatelessWidget {
  const RecentStrip({super.key, required this.index, required this.recentIds});

  final PokedexIndex index;
  final List<int> recentIds;

  @override
  Widget build(BuildContext context) {
    final entries = <PokedexEntry>[
      for (final id in recentIds)
        if (index.byId(id) case final entry?) entry,
    ];
    if (entries.isEmpty) {
      return CuteEmptyState(
        compact: true,
        icon: Icons.history_rounded,
        title: 'Aún no has abierto ninguna ficha',
        message: 'Los Pokémon que consultes aparecerán aquí para volver a ellos rápido.',
        actionLabel: 'Abrir la Pokédex',
        onAction: () => context.go(AppRoutes.pokedex),
      );
    }
    final cardHeight = PokemonCard.heightFor(context);
    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        itemCount: entries.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) => SizedBox(width: 150, child: PokemonCard(entry: entries[i])),
      ),
    );
  }
}
