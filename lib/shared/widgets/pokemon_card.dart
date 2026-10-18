import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/type_palette.dart';
import '../../core/audio/sound_service.dart';
import '../../features/settings/application/settings_controller.dart';
import '../models/pokedex_entry.dart';
import 'pokemon_sprite.dart';
import 'pokemon_type_badge.dart';
import 'retro_widgets.dart';

/// Tarjeta de especie para cuadrículas y carruseles.
///
/// Es un componente interno de la app (no un widget del sistema operativo).
class PokemonCard extends ConsumerWidget {
  const PokemonCard({super.key, required this.entry, this.onTap});

  final PokedexEntry entry;

  /// Por defecto abre la ficha.
  final VoidCallback? onTap;

  /// Alto recomendado según la escala de texto (las tarjetas no deben
  /// desbordarse cuando el usuario agranda la letra).
  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return 132 + 58 * scale.clamp(1.0, 1.6);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TypePalette.of(entry.primaryType);
    final artStyle = ref.watch(settingsProvider.select((s) => s.cardArtStyle));
    final usePixel = artStyle == CardArtStyle.pixel && entry.spriteUrl != null;
    final imageUrl = usePixel ? entry.spriteUrl : (entry.artworkUrl ?? entry.spriteUrl);
    final textTheme = Theme.of(context).textTheme;
    final typeNames = entry.types.map((t) => t.spanishName).join(' y ');
    void open() {
      playSound(context, SoundEffect.open);
      final callback = onTap;
      if (callback != null) {
        callback();
      } else {
        context.push(AppRoutes.pokemon(entry.id));
      }
    }

    return Semantics(
      button: true,
      label: '${entry.nameEs}, número ${entry.id}, tipo $typeNames',
      hint: 'Abrir ficha',
      excludeSemantics: true,
      onTap: open,
      child: PressableScale(
        child: Material(
          color: palette.soft,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.lgAll,
            side: BorderSide(color: AppColors.retroBrown.withValues(alpha: 0.9), width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: open,
            splashColor: palette.base.withValues(alpha: 0.18),
            child: Stack(
              children: <Widget>[
                // "Lente" decorativa en la esquina, teñida con el tipo.
                Positioned(
                  right: -22,
                  top: -22,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(color: palette.base.withValues(alpha: 0.18), shape: BoxShape.circle),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DexNumberTag(id: entry.id),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = constraints.biggest.shortestSide.clamp(48.0, 120.0);
                            return Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                // Plataforma ovalada bajo el sprite (como en los combates).
                                Positioned(
                                  bottom: constraints.maxHeight * 0.08,
                                  child: Container(
                                    width: size * 0.78,
                                    height: size * 0.16,
                                    decoration: ShapeDecoration(
                                      color: palette.base.withValues(alpha: 0.28),
                                      shape: const OvalBorder(),
                                    ),
                                  ),
                                ),
                                PokemonSprite(
                                  url: imageUrl,
                                  style: usePixel ? SpriteStyle.pixel : SpriteStyle.artwork,
                                  size: usePixel ? size : size * 0.86,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Text(
                        entry.nameEs,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: <Widget>[
                          for (final type in entry.types) PokemonTypeBadge(type: type, size: BadgeSize.small),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Esqueleto con pulso suave mientras cargan los datos.
class LoadingPokemonCard extends StatefulWidget {
  const LoadingPokemonCard({super.key});

  @override
  State<LoadingPokemonCard> createState() => _LoadingPokemonCardState();
}

class _LoadingPokemonCardState extends State<LoadingPokemonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No se anima si el usuario pidió reducir el movimiento.
    if (AppMotion.reduced(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.creamDeep,
            borderRadius: AppRadii.lgAll,
            border: Border.all(color: AppColors.retroBrown.withValues(alpha: 0.35), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _bone(width: 40, height: 16),
                const Spacer(),
                Center(child: _bone(width: 64, height: 64, circle: true)),
                const Spacer(),
                _bone(width: 96, height: 16),
                const SizedBox(height: 8),
                _bone(width: 56, height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bone({required double width, required double height, bool circle = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.sand,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : AppRadii.smAll,
      ),
    );
  }
}
