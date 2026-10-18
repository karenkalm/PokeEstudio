import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/application/pokedex_index_controller.dart';
import '../../../../shared/models/pokedex_entry.dart';
import '../../../../shared/models/pokemon_type.dart';
import '../../../../shared/widgets/pokemon_type_badge.dart';
import '../../application/pokedex_providers.dart';
import '../../domain/pokedex_filter.dart';
import '../../domain/pokedex_query.dart';

/// Hoja de filtros avanzados. Trabaja sobre un borrador y devuelve el filtro
/// al pulsar "Ver N resultados" (vista previa en vivo del recuento).
class PokemonFilterSheet extends ConsumerStatefulWidget {
  const PokemonFilterSheet({super.key, required this.initial});

  final PokedexFilter initial;

  @override
  ConsumerState<PokemonFilterSheet> createState() => _PokemonFilterSheetState();
}

class _PokemonFilterSheetState extends ConsumerState<PokemonFilterSheet> {
  late PokedexFilter _draft = widget.initial;

  void _update(PokedexFilter next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(pokedexIndexProvider).value;
    final query = ref.watch(pokedexQueryProvider);
    final entries = index?.entries ?? const <PokedexEntry>[];
    final count = PokedexQuery.count(entries, filter: _draft, query: query);
    final generations = index?.generations ?? const <int>[];
    // El filtro de variocolor solo se muestra si hay especies sin sprite shiny;
    // con los datos actuales de PokéAPI todas lo tienen y no filtraría nada.
    final shinyFilterUseful = entries.any((e) => !e.hasShinySprite) || _draft.onlyWithShiny;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
                children: <Widget>[
                  Semantics(header: true, child: Text('Filtros', style: textTheme.headlineSmall)),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Tipos ────────────────────────────────────────────────
                  _SectionTitle('Tipos'),
                  SegmentedButton<TypeMatchMode>(
                    segments: <ButtonSegment<TypeMatchMode>>[
                      for (final mode in TypeMatchMode.values)
                        ButtonSegment<TypeMatchMode>(value: mode, label: Text(mode.label)),
                    ],
                    selected: <TypeMatchMode>{_draft.typeMatchMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) => _update(_draft.copyWith(typeMatchMode: selection.first)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _draft.typeMatchMode == TypeMatchMode.exactPosition ? 'Tipo principal' : 'Tipo 1',
                    style: textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TypeSelectorRow(
                    selected: _draft.firstType,
                    onSelected: (type) => _update(_draft.copyWith(firstType: type)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _draft.typeMatchMode == TypeMatchMode.exactPosition ? 'Tipo secundario' : 'Tipo 2',
                    style: textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TypeSelectorRow(
                    selected: _draft.secondType,
                    monotypeSelected: _draft.monotypeOnly,
                    onMonotype: () => _update(_draft.copyWith(secondType: null, monotypeOnly: true)),
                    onSelected: (type) => _update(_draft.copyWith(secondType: type, monotypeOnly: false)),
                  ),

                  // ── Generaciones ─────────────────────────────────────────
                  const SizedBox(height: AppSpacing.xl),
                  _SectionTitle('Generación'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final generation in generations)
                        FilterChip(
                          label: Text('${Formatters.roman(generation)} · ${Generations.regionNames[generation] ?? ''}'),
                          selected: _draft.generations.contains(generation),
                          onSelected: (selected) {
                            final next = Set<int>.of(_draft.generations);
                            if (selected) {
                              next.add(generation);
                            } else {
                              next.remove(generation);
                            }
                            _update(_draft.copyWith(generations: next));
                          },
                        ),
                    ],
                  ),

                  // ── Estadísticas ─────────────────────────────────────────
                  const SizedBox(height: AppSpacing.xl),
                  _SectionTitle('Estadísticas base mínimas'),
                  _StatSlider(
                    label: 'Ataque',
                    value: _draft.minAttack,
                    max: 200,
                    onChanged: (v) => _update(_draft.copyWith(minAttack: v)),
                  ),
                  _StatSlider(
                    label: 'Defensa',
                    value: _draft.minDefense,
                    max: 200,
                    onChanged: (v) => _update(_draft.copyWith(minDefense: v)),
                  ),
                  _StatSlider(
                    label: 'Velocidad',
                    value: _draft.minSpeed,
                    max: 200,
                    onChanged: (v) => _update(_draft.copyWith(minSpeed: v)),
                  ),
                  _StatSlider(
                    label: 'Total',
                    value: _draft.minTotal,
                    max: 720,
                    step: 20,
                    onChanged: (v) => _update(_draft.copyWith(minTotal: v)),
                  ),

                  // ── Otros ────────────────────────────────────────────────
                  const SizedBox(height: AppSpacing.lg),
                  _SectionTitle('Otros'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Con formas alternativas'),
                    subtitle: const Text('Regionales, megaevoluciones, Gigamax…'),
                    value: _draft.onlyWithForms,
                    onChanged: (v) => _update(_draft.copyWith(onlyWithForms: v)),
                  ),
                  if (shinyFilterUseful)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Con sprite variocolor disponible'),
                      value: _draft.onlyWithShiny,
                      onChanged: (v) => _update(_draft.copyWith(onlyWithShiny: v)),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Favoritos y capturados se podrán filtrar cuando llegue "Mi colección" (Fase 3).',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _SheetFooter(
              count: count,
              canClear: _draft.hasActiveFilters,
              onClear: () => _update(_draft.cleared()),
              onApply: () => Navigator.of(context).pop(_draft),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
    );
  }
}

/// Fila deslizable con "Cualquiera", (opcional) "Ninguno" y los 18 tipos.
class _TypeSelectorRow extends StatelessWidget {
  const _TypeSelectorRow({
    required this.selected,
    required this.onSelected,
    this.onMonotype,
    this.monotypeSelected = false,
  });

  final PokemonType? selected;
  final ValueChanged<PokemonType?> onSelected;
  final VoidCallback? onMonotype;
  final bool monotypeSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          ChoiceChip(
            label: const Text('Cualquiera'),
            selected: selected == null && !monotypeSelected,
            onSelected: (_) => onSelected(null),
          ),
          if (onMonotype != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: const Text('Ninguno (un solo tipo)'),
              selected: monotypeSelected,
              onSelected: (_) => onMonotype!(),
            ),
          ],
          for (final type in PokemonType.values) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Center(
              child: PokemonTypeBadge(
                type: type,
                selected: selected == type,
                onTap: () => onSelected(selected == type ? null : type),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatSlider extends StatelessWidget {
  const _StatSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.step = 5,
  });

  final String label;
  final int value;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: textTheme.labelLarge)),
            Text(
              value == 0 ? 'Sin mínimo' : '≥ $value',
              style: textTheme.labelMedium?.copyWith(color: value == 0 ? AppColors.inkMuted : AppColors.pokeRedDeep),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          max: max.toDouble(),
          divisions: max ~/ step,
          label: value == 0 ? 'Sin mínimo' : '≥ $value',
          semanticFormatterCallback: (v) => v == 0 ? 'Sin mínimo' : 'Mínimo ${v.round()}',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter({required this.count, required this.canClear, required this.onClear, required this.onApply});

  final int count;
  final bool canClear;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.warmCream,
        border: Border(top: BorderSide(color: AppColors.retroBrown, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.md),
          child: Row(
            children: <Widget>[
              TextButton(onPressed: canClear ? onClear : null, child: const Text('Limpiar')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: onApply,
                  child: Text(
                    count == 1 ? 'Ver 1 resultado' : 'Ver $count resultados',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
