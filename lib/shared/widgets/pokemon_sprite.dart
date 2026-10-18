import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import 'app_network_image.dart';

/// Cómo se dibuja la imagen.
enum SpriteStyle {
  /// Sprite pixel art de 96×96: se escala sin suavizado para conservar los píxeles.
  pixel,

  /// Ilustración oficial en alta resolución.
  artwork,
}

/// Sprite o ilustración de un Pokémon con marcador bonito si falta.
class PokemonSprite extends StatelessWidget {
  const PokemonSprite({
    super.key,
    required this.url,
    required this.style,
    this.size = 96,
    this.semanticLabel,
  });

  final String? url;
  final SpriteStyle style;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: AppNetworkImage(
        url: url,
        width: size,
        height: size,
        // Sin suavizado para pixel art: nítido en cualquier tamaño.
        filterQuality: style == SpriteStyle.pixel ? FilterQuality.none : FilterQuality.medium,
        semanticLabel: semanticLabel,
        placeholder: _SpritePlaceholder(size: size),
        fallback: MissingSprite(size: size),
      ),
    );
  }
}

/// Silueta suave mientras la imagen llega.
class _SpritePlaceholder extends StatelessWidget {
  const _SpritePlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size * 0.46,
        height: size * 0.46,
        decoration: BoxDecoration(
          color: AppColors.retroBrown.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Marcador para cuando PokéAPI no tiene imagen o la descarga falla.
/// Nunca se sustituye por una imagen inventada.
class MissingSprite extends StatelessWidget {
  const MissingSprite({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.56;
    return Center(
      child: Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(
          color: AppColors.creamYellow,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.retroBrown.withValues(alpha: 0.5), width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          '?',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
            fontSize: inner * 0.5,
            color: AppColors.retroBrown.withValues(alpha: 0.7),
            height: 1,
          ),
        ),
      ),
    );
  }
}
