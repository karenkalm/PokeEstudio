import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../models/base_stats.dart';

/// Barra de estadística base con valor real y escala fija 0–255.
///
/// El color indica el rango, pero el número siempre está visible: la
/// información nunca depende solo del color.
class PokemonStatBar extends StatelessWidget {
  const PokemonStatBar({super.key, required this.kind, required this.value, this.delay = Duration.zero});

  final StatKind kind;
  final int value;

  /// Retraso para animar las barras en cascada.
  final Duration delay;

  static Color colorFor(int value) {
    if (value < 60) return AppColors.statLow;
    if (value < 90) return AppColors.statMid;
    if (value < 120) return AppColors.statGood;
    return AppColors.statHigh;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fraction = (value / BaseStats.maxValue).clamp(0.0, 1.0);
    final reduced = AppMotion.reduced(context);
    final color = colorFor(value);

    return Semantics(
      label: '${kind.spanishName}: $value de ${BaseStats.maxValue}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 86,
              child: Text(
                kind.shortName,
                style: textTheme.labelMedium?.copyWith(color: AppColors.inkMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.right,
                style: textTheme.labelLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TweenAnimationBuilder<double>(
                key: ValueKey<int>(value),
                tween: Tween<double>(begin: reduced ? fraction : 0.0, end: fraction),
                duration: reduced ? Duration.zero : AppMotion.slow + delay,
                curve: Interval(
                  reduced ? 0.0 : delay.inMilliseconds / (AppMotion.slow + delay).inMilliseconds,
                  1,
                  curve: AppMotion.emphasized,
                ),
                builder: (context, animated, _) => _StatTrack(fraction: animated, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTrack extends StatelessWidget {
  const _StatTrack({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: AppColors.creamDeep,
        borderRadius: AppRadii.smAll,
        border: Border.all(color: AppColors.retroBrown.withValues(alpha: 0.55), width: 1.5),
      ),
      padding: const EdgeInsets.all(2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
