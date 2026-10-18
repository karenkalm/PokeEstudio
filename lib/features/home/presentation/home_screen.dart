import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../../app/layout/responsive.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/audio/sound_service.dart';
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
    // Con el riel lateral (pantallas anchas) Ajustes ya está a la vista.
    final showSettingsButton = MediaQuery.sizeOf(context).width < Breakpoints.navigationRail;

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
              _CenteredBox(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.sm, 0),
                  child: Row(
                    children: <Widget>[
                      // Expanded (y no Flexible + Spacer, que se repartían el
                      // espacio a la mitad y cortaban el nombre en celulares).
                      const Expanded(
                        child: Align(alignment: Alignment.centerLeft, child: PokestudioLogo()),
                      ),
                      if (showSettingsButton)
                        IconButton(
                          tooltip: 'Ajustes',
                          icon: const Icon(Icons.settings_rounded, color: AppColors.retroBrown),
                          onPressed: () {
                            playSound(context, SoundEffect.open);
                            context.push(AppRoutes.settings);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              _CenteredBox(
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
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: HomeSearchField(entries: data.entries),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DexCounter(count: data.count),
                    ],
                  ),
                ),
              ),
              const _CenteredBox(
                child: SectionHeader(title: 'Destacados de hoy', subtitle: 'Una selección nueva cada día'),
              ),
              const _CenteredBox(child: FeaturedCarousel()),
              _CenteredBox(
                child: SectionHeader(
                  title: 'Vistos recientemente',
                  action: recents.isEmpty
                      ? null
                      : TextButton(
                          onPressed: () async {
                            playSound(context, SoundEffect.tap);
                            final confirmed = await showConfirmDialog(
                              context,
                              title: '¿Borrar historial?',
                              message: 'Se quitará la lista de Pokémon consultados. Tu colección no se modifica.',
                              confirmLabel: 'Borrar',
                            );
                            if (confirmed) {
                              await ref.read(recentlyViewedProvider.notifier).clear();
                              if (context.mounted) playSound(context, SoundEffect.back);
                            }
                          },
                          child: const Text('Borrar'),
                        ),
                ),
              ),
              _CenteredBox(child: RecentStrip(index: data, recentIds: recents)),
              const _CenteredBox(
                child: SectionHeader(title: 'Explorar por tipo', subtitle: 'Abre la Pokédex filtrada'),
              ),
              _CenteredBox(
                child: ExploreByType(
                  onSelected: (type) {
                    playSound(context, SoundEffect.open);
                    ref.read(pokedexFilterProvider.notifier).showOnlyType(type);
                    ref.read(pokedexQueryProvider.notifier).setQuery('');
                    context.go(AppRoutes.pokedex);
                  },
                ),
              ),
              const _CenteredBox(child: SectionHeader(title: 'Explorar por generación')),
              _CenteredBox(
                child: ExploreByGeneration(
                  index: data,
                  onSelected: (generation) {
                    playSound(context, SoundEffect.open);
                    ref.read(pokedexFilterProvider.notifier).showOnlyGeneration(generation);
                    ref.read(pokedexQueryProvider.notifier).setQuery('');
                    context.go(AppRoutes.pokedex);
                  },
                ),
              ),
              _CenteredBox(
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

/// Fila de contenido centrada y con ancho máximo (no se estira en monitores).
class _CenteredBox extends StatelessWidget {
  const _CenteredBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(child: MaxWidth(child: child));
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
