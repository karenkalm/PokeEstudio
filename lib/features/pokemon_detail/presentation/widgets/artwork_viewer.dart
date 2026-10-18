import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/type_palette.dart';
import '../../../../shared/models/pokemon_type.dart';
import '../../../../shared/widgets/pokemon_sprite.dart';

/// Modos de visualización de la imagen principal.
enum ArtworkMode {
  artwork('Ilustración', Icons.image_rounded),
  pixel('Pixel', Icons.grid_view_rounded),
  animated('Animado', Icons.gif_box_rounded);

  const ArtworkMode(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// "Pantalla" retro que muestra la ilustración, el sprite pixel o el GIF
/// animado. Solo ofrece los modos cuyos recursos existen en PokéAPI.
class ArtworkViewer extends StatelessWidget {
  const ArtworkViewer({
    super.key,
    required this.speciesId,
    required this.name,
    required this.primaryType,
    required this.urls,
    required this.mode,
    required this.onModeChanged,
    this.onSwipePrevious,
    this.onSwipeNext,
  });

  final int speciesId;
  final String name;
  final PokemonType primaryType;

  /// URL disponible para cada modo (solo los que existen).
  final Map<ArtworkMode, String> urls;
  final ArtworkMode mode;
  final ValueChanged<ArtworkMode> onModeChanged;
  final VoidCallback? onSwipePrevious;
  final VoidCallback? onSwipeNext;

  @override
  Widget build(BuildContext context) {
    final palette = TypePalette.of(primaryType);
    final effectiveMode = urls.containsKey(mode) ? mode : (urls.keys.isEmpty ? ArtworkMode.artwork : urls.keys.first);
    final url = urls[effectiveMode];
    final reduced = AppMotion.reduced(context);

    return Column(
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity > 300) onSwipePrevious?.call();
            if (velocity < -300) onSwipeNext?.call();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.retroBrown,
              borderRadius: AppRadii.xlAll,
              boxShadow: <BoxShadow>[
                BoxShadow(color: AppColors.shadow, offset: const Offset(0, 6), blurRadius: 0),
              ],
            ),
            child: Column(
              children: <Widget>[
                // Luces de la carcasa.
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                  child: Row(
                    children: <Widget>[
                      _Led(color: AppColors.pokeRed, size: 10),
                      const SizedBox(width: 6),
                      _Led(color: AppColors.pikachuYellow, size: 6),
                      const SizedBox(width: 4),
                      _Led(color: AppColors.grassGreen, size: 6),
                      const Spacer(),
                      for (var i = 0; i < 3; i++)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          width: 14,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.warmCream.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1.25,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: <Color>[AppColors.white, palette.soft],
                        radius: 0.9,
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: AppColors.retroBrownDark, width: 2),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest.shortestSide * 0.86;
                        final image = PokemonSprite(
                          key: ValueKey<String>('$speciesId-${effectiveMode.name}'),
                          url: url,
                          style: effectiveMode == ArtworkMode.artwork ? SpriteStyle.artwork : SpriteStyle.pixel,
                          size: size,
                          semanticLabel: '${effectiveMode.label} de $name',
                        );
                        return Center(
                          child: reduced
                              ? image
                              : TweenAnimationBuilder<double>(
                                  key: ValueKey<String>('enter-$speciesId-${effectiveMode.name}'),
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: AppMotion.slow,
                                  curve: AppMotion.playful,
                                  builder: (context, t, child) => Opacity(
                                    opacity: t.clamp(0.0, 1.0),
                                    child: Transform.scale(scale: 0.82 + 0.18 * t, child: child),
                                  ),
                                  child: image,
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (urls.length > 1) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final option in ArtworkMode.values)
                if (urls.containsKey(option))
                  ChoiceChip(
                    avatar: Icon(option.icon, size: 18),
                    label: Text(option.label),
                    selected: option == effectiveMode,
                    showCheckmark: false,
                    onSelected: (_) => onModeChanged(option),
                  ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Led extends StatelessWidget {
  const _Led({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.retroBrownDark, width: 1.5),
      ),
    );
  }
}
