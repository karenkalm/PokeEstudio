import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/pokedex_providers.dart';
import '../../domain/pokedex_filter.dart';

/// Chips con los filtros activos; cada uno se quita con un toque.
class ActiveFiltersBar extends ConsumerWidget {
  const ActiveFiltersBar({super.key, required this.filter});

  final PokedexFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(pokedexFilterProvider.notifier);
    final exact = filter.typeMatchMode == TypeMatchMode.exactPosition;
    final chips = <_ChipData>[
      if (filter.firstType != null)
        _ChipData(
          '${exact ? 'Principal' : 'Tipo'}: ${filter.firstType!.spanishName}',
          controller.removeFirstType,
        ),
      if (filter.secondType != null)
        _ChipData(
          '${exact ? 'Secundario' : 'Tipo'}: ${filter.secondType!.spanishName}',
          controller.removeSecondType,
        ),
      if (filter.monotypeOnly) _ChipData('Un solo tipo', controller.removeSecondType),
      if (filter.generations.isNotEmpty)
        _ChipData(
          'Gen. ${(filter.generations.toList()..sort()).map(Formatters.roman).join(', ')}',
          controller.removeGenerations,
        ),
      if (filter.minAttack > 0) _ChipData('Ataque ≥ ${filter.minAttack}', controller.removeMinAttack),
      if (filter.minDefense > 0) _ChipData('Defensa ≥ ${filter.minDefense}', controller.removeMinDefense),
      if (filter.minSpeed > 0) _ChipData('Velocidad ≥ ${filter.minSpeed}', controller.removeMinSpeed),
      if (filter.minTotal > 0) _ChipData('Total ≥ ${filter.minTotal}', controller.removeMinTotal),
      if (filter.onlyWithShiny) _ChipData('Con variocolor', controller.removeOnlyWithShiny),
      if (filter.onlyWithForms) _ChipData('Con formas alternativas', controller.removeOnlyWithForms),
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        children: <Widget>[
          for (final chip in chips)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: InputChip(
                label: Text(chip.label),
                onDeleted: chip.onRemove,
                deleteButtonTooltipMessage: 'Quitar filtro',
                backgroundColor: AppColors.creamYellow,
              ),
            ),
          TextButton(onPressed: controller.clear, child: const Text('Quitar todos')),
        ],
      ),
    );
  }
}

class _ChipData {
  const _ChipData(this.label, this.onRemove);

  final String label;
  final VoidCallback onRemove;
}
