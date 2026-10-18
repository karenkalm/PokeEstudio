import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/application/pokedex_index_controller.dart';
import '../../../shared/widgets/feedback_views.dart';
import '../../../shared/widgets/pokestudio_logo.dart';
import '../../../shared/widgets/retro_widgets.dart';
import '../../pokedex/application/pokedex_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../application/home_providers.dart';
import 'widgets/explore_sections.dart';
import 'widgets/featured_carousel.dart';
import 'widgets/home_search_field.dart';
import 'widgets/recent_strip.dart';

/// Inicio: el pequeño universo personal del entrenador.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final name = ref.watch(settingsProvider.select((s) => s.greetingName));
    final index = ref.watch(pokedexIndexProvider);
    final recents = ref.watch(recentlyViewedProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: index.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: ErrorRetryView(error: error, onRetry: () => ref.invalidate(pokedexIndexProvider)),
          ),
          data: (data) => CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.sm, 0),
                  child: Row(
                    children: <Widget>[
                      const Flexible(child: PokestudioLogo()),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Ajustes',
                        icon: const Icon(Icons.settings_rounded, color: AppColors.retroBrown),
                        onPressed: () => context.push(AppRoutes.settings),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xl, AppSpacing.screen, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Semantics(header: true, child: Text('¡Hola, $name!', style: textTheme.headlineMedium)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '¿Qué Pokémon exploramos hoy?',
                        style: textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      HomeSearchField(entries: data.entries),
                      const SizedBox(height: AppSpacing.md),
                      _DexCounter(count: data.count),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Destacados de hoy', subtitle: 'Una selección nueva cada día'),
              ),
              const SliverToBoxAdapter(child: FeaturedCarousel()),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Vistos recientemente',
                  action: recents.isEmpty
                      ? null
                      : TextButton(
                          onPressed: () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              title: '¿Borrar historial?',
                              message: 'Se quitará la lista de Pokémon consultados. Tu colección no se modifica.',
                              confirmLabel: 'Borrar',
                            );
                            if (confirmed) {
                              await ref.read(recentlyViewedProvider.notifier).clear();
                            }
                          },
                          child: const Text('Borrar'),
                        ),
                ),
              ),
              SliverToBoxAdapter(child: RecentStrip(index: data, recentIds: recents)),
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Explorar por tipo', subtitle: 'Abre la Pokédex filtrada'),
              ),
              SliverToBoxAdapter(
                child: ExploreByType(
                  onSelected: (type) {
                    ref.read(pokedexFilterProvider.notifier).showOnlyType(type);
                    ref.read(pokedexQueryProvider.notifier).setQuery('');
                    context.go(AppRoutes.pokedex);
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SectionHeader(title: 'Explorar por generación')),
              SliverToBoxAdapter(
                child: ExploreByGeneration(
                  index: data,
                  onSelected: (generation) {
                    ref.read(pokedexFilterProvider.notifier).showOnlyGeneration(generation);
                    ref.read(pokedexQueryProvider.notifier).setQuery('');
                    context.go(AppRoutes.pokedex);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xxl, AppSpacing.screen, AppSpacing.xxl),
                  child: Text(
                    'Proyecto de fans · Datos de PokéAPI\nNo afiliado a Nintendo, Game Freak ni The Pokémon Company.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DexCounter extends StatelessWidget {
  const _DexCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count especies en la Pokédex Nacional',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.creamYellow,
          borderRadius: AppRadii.mdAll,
          border: Border.all(color: AppColors.retroBrown.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.catching_pokemon, size: 18, color: AppColors.pokeRedDeep),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(color: AppColors.retroBrownDark, borderRadius: BorderRadius.circular(7)),
              child: Text('$count', style: AppTypography.pixelStyle(fontSize: 9, color: AppColors.warmCream)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'especies en la Pokédex Nacional',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
