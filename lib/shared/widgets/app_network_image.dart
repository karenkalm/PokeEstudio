import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';

/// Permite desactivar la carga de imágenes de red (pruebas de widgets, o un
/// futuro "modo ahorro de datos").
final networkImagesEnabledProvider = Provider<bool>((ref) => true, name: 'networkImagesEnabledProvider');

/// Imagen remota con caché y alternativas para carga y error.
///
/// * **Android / iOS**: `CachedNetworkImage`, que guarda las imágenes en disco
///   para verlas sin conexión.
/// * **Web**: `Image.network` de Flutter. El navegador ya guarda las imágenes en
///   su caché HTTP, y la implementación web de `CachedNetworkImage` creaba
///   texturas que se perdían al cambiar de pestaña (cuadros negros y el aviso
///   `WebGL: texImage2D: no image` en la consola).
class AppNetworkImage extends ConsumerWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    required this.placeholder,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.width,
    this.height,
    this.semanticLabel,
  });

  final String? url;

  /// Se muestra mientras la imagen carga.
  final Widget placeholder;

  /// Se muestra si no hay URL o la descarga falla.
  final Widget fallback;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final double? width;
  final double? height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(networkImagesEnabledProvider);
    final imageUrl = url;
    final Widget image;
    if (imageUrl == null || imageUrl.isEmpty) {
      image = fallback;
    } else if (!enabled) {
      image = placeholder;
    } else if (kIsWeb) {
      final fade = AppMotion.of(context, const Duration(milliseconds: 180));
      image = Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        filterQuality: filterQuality,
        // Mantiene la imagen anterior mientras llega la nueva (sin parpadeos).
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedSwitcher(
            duration: fade,
            child: frame == null ? KeyedSubtree(key: const ValueKey<String>('cargando'), child: placeholder) : child,
          );
        },
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } else {
      final fade = AppMotion.of(context, const Duration(milliseconds: 220));
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        filterQuality: filterQuality,
        fadeInDuration: fade,
        fadeOutDuration: fade,
        placeholderFadeInDuration: Duration.zero,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => fallback,
      );
    }
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: image);
    return Semantics(image: true, label: label, child: ExcludeSemantics(child: image));
  }
}
