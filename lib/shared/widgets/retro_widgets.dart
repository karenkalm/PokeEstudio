import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/audio/sound_service.dart';
import '../../core/utils/formatters.dart';

/// Etiqueta pixel con el número de Pokédex: `#025`.
class DexNumberTag extends StatelessWidget {
  const DexNumberTag({super.key, required this.id, this.large = false});

  final int id;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: large ? 10 : 6, vertical: large ? 7 : 5),
        decoration: BoxDecoration(
          color: AppColors.retroBrownDark,
          borderRadius: BorderRadius.circular(large ? 10 : 7),
        ),
        child: Text(
          Formatters.dexNumber(id),
          style: AppTypography.pixelStyle(fontSize: large ? 11 : 8, color: AppColors.warmCream),
        ),
      ),
    );
  }
}

/// Panel con el marco retro de PokéStudio: borde marrón y filo interior claro.
class RetroPanel extends StatelessWidget {
  const RetroPanel({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.lg,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.retroBrown, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(color: AppColors.shadow, offset: const Offset(0, 3), blurRadius: 0),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - 3),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.7), width: 1.5),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Encabezado de sección con acción opcional a la derecha.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xl, AppSpacing.md, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(header: true, child: Text(title, style: textTheme.titleLarge)),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Botón de flecha retro (◀ ▶), como en las Pokédex clásicas.
class RetroArrowButton extends StatelessWidget {
  const RetroArrowButton({super.key, required this.pointsLeft, required this.tooltip, this.onPressed});

  final bool pointsLeft;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        excludeSemantics: true,
        onTap: onPressed,
        child: Material(
          color: enabled ? AppColors.retroBrownDark : AppColors.retroBrown.withValues(alpha: 0.25),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    playSound(context, SoundEffect.arrow);
                    onPressed!();
                  },
            child: SizedBox.square(
              dimension: AppSpacing.minTouchTarget,
              child: CustomPaint(
                painter: _ArrowPainter(
                  pointsLeft: pointsLeft,
                  color: enabled ? AppColors.pikachuYellow : AppColors.warmCream,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.pointsLeft, required this.color});

  final bool pointsLeft;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Triángulo "pixelado": esquinas rectas, como en las consolas portátiles.
    final w = size.width * 0.28;
    final h = size.height * 0.34;
    final cx = size.width / 2 + (pointsLeft ? -1 : 1);
    final cy = size.height / 2;
    final path = Path();
    if (pointsLeft) {
      path
        ..moveTo(cx - w / 2, cy)
        ..lineTo(cx + w / 2, cy - h / 2)
        ..lineTo(cx + w / 2, cy + h / 2);
    } else {
      path
        ..moveTo(cx + w / 2, cy)
        ..lineTo(cx - w / 2, cy - h / 2)
        ..lineTo(cx - w / 2, cy + h / 2);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      oldDelegate.pointsLeft != pointsLeft || oldDelegate.color != color;
}

/// Envuelve un hijo táctil: lo encoge un poco al presionarlo y, con mouse,
/// lo levanta ligeramente al pasar el puntero (y muestra la mano).
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.scale = 0.96, this.hoverScale = 1.02});

  final Widget child;
  final double scale;
  final double hoverScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;
  bool _hovered = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _hover(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final target = _pressed
        ? widget.scale
        : _hovered
            ? widget.hoverScale
            : 1.0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _hover(true),
      onExit: (_) => _hover(false),
      child: Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: target,
          duration: AppMotion.of(context, AppMotion.fast),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
