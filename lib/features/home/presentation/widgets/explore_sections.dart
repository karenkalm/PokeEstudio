import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/pokedex_entry.dart';
import '../../../../shared/models/pokemon_type.dart';
import '../../../../shared/widgets/pokemon_type_badge.dart';

/// Insignias de los 18 tipos; cada una abre la Pokédex filtrada.
class ExploreByType extends StatelessWidget {
  const ExploreByType({super.key, required this.onSelected});

  final ValueChanged<PokemonType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          for (final type in PokemonType.values)
            PokemonTypeBadge(type: type, size: BadgeSize.large, onTap: () => onSelected(type)),
        ],
      ),
    );
  }
}

/// Tarjetas de generación con su región y número de especies.
class ExploreByGeneration extends StatelessWidget {
  const ExploreByGeneration({super.key, required this.index, required this.onSelected});

  final PokedexIndex index;
  final ValueChanged<int> onSelected;

  static const List<Color> _tints = <Color>[
    AppColors.pastelPink,
    AppColors.skyBlue,
    AppColors.mint,
    AppColors.creamYellow,
    AppColors.lavender,
  ];

  @override
  Widget build(BuildContext context) {
    final generations = index.generations;
    final textTheme = Theme.of(context).textTheme;
    final scale = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 1.6);
    return SizedBox(
      height: 112 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        itemCount: generations.length,
        separatorBuilder: (context, i) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final generation = generations[i];
          final region = Generations.regionNames[generation] ?? '';
          final count = index.countForGeneration(generation);
          return Semantics(
            button: true,
            label: 'Generación $generation, $region, $count especies',
            excludeSemantics: true,
            onTap: () => onSelected(generation),
            child: Material(
              color: _tints[i % _tints.length],
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.lgAll,
                side: const BorderSide(color: AppColors.retroBrown, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelected(generation),
                child: SizedBox(
                  width: 128,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'GEN ${Formatters.roman(generation)}',
                          style: AppTypography.pixelStyle(fontSize: 9, color: AppColors.retroBrownDark),
                        ),
                        const Spacer(),
                        Text(region, style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('$count especies', style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
