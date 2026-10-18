import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/layout/responsive.dart';
import '../../../../app/theme/type_palette.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/pokedex_entry.dart';
import '../../../../shared/widgets/feedback_views.dart';
import '../../../../shared/widgets/pokemon_sprite.dart';
import '../../../../shared/widgets/pokemon_type_badge.dart';
import '../../../../shared/widgets/retro_widgets.dart';
import '../../application/home_providers.dart';

/// Carrusel de destacados del día con flechas retro y puntos de página.
class FeaturedCarousel extends ConsumerStatefulWidget {
  const FeaturedCarousel({super.key});

  @override
  ConsumerState<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends ConsumerState<FeaturedCarousel> {
  PageController? _controller;
  double _fraction = 0;
  int _page = 0;

  /// Celular: una tarjeta grande con las vecinas asomándose. Tablet y
  /// computadora: tarjetas de ~420 px para que no se vean gigantes.
  static double _fractionFor(double width) {
    if (width < Breakpoints.medium) return 0.86;
    return (430 / width).clamp(0.34, 0.62);
  }

  /// Crea (o recrea al cambiar el tamaño de la ventana) el controlador,
  /// conservando la página actual.
  PageController _controllerFor(double width, int itemCount) {
    final fraction = _fractionFor(width);
    final current = _controller;
    if (current != null && (fraction - _fraction).abs() < 0.01) return current;
    // En pantallas anchas se empieza en el segundo destacado para que no
    // quede un hueco a la izquierda.
    if (current == null && fraction < 0.7 && itemCount > 2) _page = 1;
    _fraction = fraction;
    final next = PageController(viewportFraction: fraction, initialPage: _page);
    _controller = next;
    if (current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => current.dispose());
    }
    return next;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    final duration = AppMotion.of(context, AppMotion.medium);
    if (duration == Duration.zero) {
      _controller?.jumpToPage(page);
    } else {
      _controller?.animateToPage(page, duration: duration, curve: AppMotion.emphasized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final picks = ref.watch(dailyPicksProvider);
    final scale = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 1.5);
    final height = 236 + 40 * (scale - 1) * 2;

    return picks.when(
      loading: () => SizedBox(height: height),
      error: (error, _) => ErrorRetryView(error: error, compact: true),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) => _buildCarousel(context, entries, height, constraints.maxWidth),
        );
      },
    );
  }

  Widget _buildCarousel(BuildContext context, List<PokedexEntry> entries, double height, double width) {
    final controller = _controllerFor(width, entries.length);
    if (_page >= entries.length) _page = entries.length - 1;
    return Column(
      children: <Widget>[
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: controller,
            itemCount: entries.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _FeaturedCard(entry: entries[index]),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RetroArrowButton(
              pointsLeft: true,
              tooltip: 'Destacado anterior',
              onPressed: _page > 0 ? () => _goTo(_page - 1) : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Semantics(
              label: 'Destacado ${_page + 1} de ${entries.length}',
              excludeSemantics: true,
              child: Row(
                children: <Widget>[
                  for (var i = 0; i < entries.length; i++)
                    AnimatedContainer(
                      duration: AppMotion.of(context, AppMotion.fast),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.pokeRedDeep : AppColors.sand,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            RetroArrowButton(
              pointsLeft: false,
              tooltip: 'Destacado siguiente',
              onPressed: _page < entries.length - 1 ? () => _goTo(_page + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.entry});

  final PokedexEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = TypePalette.of(entry.primaryType);
    final textTheme = Theme.of(context).textTheme;
    final tag = entry.isMythical
        ? 'Singular'
        : entry.isLegendary
            ? 'Legendario'
            : entry.isBaby
                ? 'Bebé'
                : null;
    void open() {
      playSound(context, SoundEffect.open);
      context.push(AppRoutes.pokemon(entry.id));
    }

    return Semantics(
      button: true,
      label: 'Destacado: ${entry.nameEs}, número ${entry.id}',
      hint: 'Abrir ficha',
      excludeSemantics: true,
      onTap: open,
      child: PressableScale(
        scale: 0.98,
        child: Material(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.xlAll,
            side: const BorderSide(color: AppColors.retroBrown, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[palette.soft, AppColors.warmCream],
              ),
            ),
            child: InkWell(
              onTap: open,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    right: -30,
                    bottom: -30,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(color: palette.base.withValues(alpha: 0.2), shape: BoxShape.circle),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  DexNumberTag(id: entry.id),
                                  if (tag != null) ...<Widget>[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.pikachuYellow,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(tag, style: textTheme.labelSmall, overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const Spacer(),
                              Text(
                                entry.nameEs,
                                style: textTheme.headlineSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(Generations.label(entry.generation), style: textTheme.bodySmall),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: <Widget>[
                                  for (final type in entry.types) PokemonTypeBadge(type: type, size: BadgeSize.small),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                'Ver ficha ›',
                                style: textTheme.labelLarge?.copyWith(color: AppColors.pokeBlueDeep),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: LayoutBuilder(
                            builder: (context, constraints) => PokemonSprite(
                              url: entry.artworkUrl ?? entry.spriteUrl,
                              style: entry.artworkUrl != null ? SpriteStyle.artwork : SpriteStyle.pixel,
                              size: constraints.biggest.shortestSide,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
