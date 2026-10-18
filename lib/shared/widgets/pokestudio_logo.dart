import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Logotipo original de PokéStudio: un pequeño dispositivo retro con lente
/// y luces, más el nombre en Fredoka.
class PokestudioLogo extends StatelessWidget {
  const PokestudioLogo({super.key, this.markSize = 38, this.showWordmark = true});

  final double markSize;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(dimension: markSize, child: const CustomPaint(painter: _LogoMarkPainter()));
    if (!showWordmark) return ExcludeSemantics(child: mark);
    return Semantics(
      label: 'PokéStudio',
      header: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          mark,
          const SizedBox(width: 10),
          Flexible(
            child: Text.rich(
              const TextSpan(
                children: <InlineSpan>[
                  TextSpan(text: 'Poké', style: TextStyle(color: AppColors.pokeRedDeep)),
                  TextSpan(text: 'Studio', style: TextStyle(color: AppColors.retroBrown)),
                ],
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.display,
                fontWeight: FontWeight.w700,
                fontSize: markSize * 0.68,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  const _LogoMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // Cuerpo del dispositivo.
    final body = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.26));
    canvas.drawRRect(body, Paint()..color = AppColors.retroBrown);
    canvas.drawRRect(
      body.deflate(s * 0.06),
      Paint()
        ..color = AppColors.warmCream.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035,
    );

    // Lente principal.
    final lensCenter = Offset(s * 0.38, s * 0.42);
    canvas.drawCircle(lensCenter, s * 0.25, Paint()..color = AppColors.warmCream);
    canvas.drawCircle(
      lensCenter,
      s * 0.185,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: <Color>[AppColors.skyBlue, AppColors.pokeBlue],
        ).createShader(Rect.fromCircle(center: lensCenter, radius: s * 0.185)),
    );
    canvas.drawCircle(lensCenter.translate(-s * 0.06, -s * 0.06), s * 0.05, Paint()..color = AppColors.white);

    // Luces de estado.
    final lights = <Color>[AppColors.pokeRed, AppColors.pikachuYellow, AppColors.grassGreen];
    for (var i = 0; i < lights.length; i++) {
      canvas.drawCircle(Offset(s * 0.78, s * (0.24 + i * 0.17)), s * 0.06, Paint()..color = lights[i]);
    }

    // Rejilla de altavoz pixel.
    final dot = Paint()..color = AppColors.warmCream.withValues(alpha: 0.55);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(s * (0.2 + i * 0.12), s * 0.8, s * 0.07, s * 0.07), dot);
    }
  }

  @override
  bool shouldRepaint(_LogoMarkPainter oldDelegate) => false;
}
