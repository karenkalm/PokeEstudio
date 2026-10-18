import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/domain/type_chart.dart';
import '../../../../shared/models/base_stats.dart';
import '../../../../shared/models/localized_resource.dart';
import '../../../../shared/models/pokemon_detail.dart';
import '../../../../shared/models/pokemon_type.dart';
import '../../../../shared/widgets/feedback_views.dart';
import '../../../../shared/widgets/pokemon_stat_bar.dart';
import '../../../../shared/widgets/pokemon_type_badge.dart';
import '../../../../shared/widgets/retro_widgets.dart';
import '../../application/pokemon_detail_providers.dart';
import '../../domain/pokedex_texts.dart';

/// Pestañas de la ficha.
enum DetailTab {
  info('Información'),
  stats('Estadísticas'),
  matchups('Debilidades');

  const DetailTab(this.label);
  final String label;
}

/// Selector de pestañas con estilo retro.
class DetailTabSelector extends StatelessWidget {
  const DetailTabSelector({super.key, required this.selected, required this.onChanged});

  final DetailTab selected;
  final ValueChanged<DetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.creamDeep,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.retroBrown, width: 2),
      ),
      child: Row(
        children: <Widget>[
          for (final tab in DetailTab.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: tab == selected,
                label: 'Pestaña ${tab.label}',
                excludeSemantics: true,
                onTap: () => onChanged(tab),
                child: Material(
                  color: tab == selected ? AppColors.pikachuYellow : Colors.transparent,
                  borderRadius: AppRadii.mdAll,
                  child: InkWell(
                    borderRadius: AppRadii.mdAll,
                    onTap: () => onChanged(tab),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Text(
                            tab.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              color: tab == selected ? AppColors.retroBrownDark : AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Información
// ─────────────────────────────────────────────────────────────────────────────

class InfoTab extends ConsumerWidget {
  const InfoTab({super.key, required this.speciesId, required this.detail});

  final int speciesId;
  final AsyncValue<PokemonDetail> detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final species = ref.watch(pokemonSpeciesProvider(speciesId));
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Descripción', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        species.when(
          loading: () => const _TextSkeleton(lines: 3),
          error: (error, _) => ErrorRetryView(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(pokemonSpeciesProvider(speciesId)),
          ),
          data: (data) => _DescriptionPanel(descriptions: pokedexDescriptions(data.flavorTexts)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Habilidades', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        detail.when(
          loading: () => const _TextSkeleton(lines: 1),
          error: (error, _) => const SizedBox.shrink(),
          data: (data) => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[for (final ability in data.abilities) _AbilityChip(ability: ability)],
          ),
        ),
        if (species.value case final data? when data.alternateVarieties.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          Text('Formas alternativas (${data.alternateVarieties.length})', style: textTheme.titleMedium),
          const SizedBox(height: 2),
          Text('Nombres tal como los registra PokéAPI.', style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final variety in data.alternateVarieties)
                Chip(
                  label: Text(Formatters.slugToTitle(variety.slug)),
                  backgroundColor: AppColors.white,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DescriptionPanel extends ConsumerStatefulWidget {
  const _DescriptionPanel({required this.descriptions});

  final List<PokedexDescription> descriptions;

  @override
  ConsumerState<_DescriptionPanel> createState() => _DescriptionPanelState();
}

class _DescriptionPanelState extends ConsumerState<_DescriptionPanel> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _DescriptionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.descriptions.length) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (widget.descriptions.isEmpty) {
      return RetroPanel(
        child: Text('PokéAPI no tiene una descripción registrada para esta especie.', style: textTheme.bodyMedium),
      );
    }
    final current = widget.descriptions[_index];
    final versionUrl = current.versionUrl;
    final versionName = versionUrl == null
        ? null
        : ref.watch(localizedResourceFor(versionUrl)).value?.displayName.text;
    final versionLabel = versionName ?? (current.versionSlug == null ? null : Formatters.slugToTitle(current.versionSlug!));

    return RetroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!current.isSpanish)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(color: AppColors.skyBlue, borderRadius: AppRadii.smAll),
              child: Text('PokéAPI solo tiene este texto en inglés', style: textTheme.labelSmall),
            ),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.medium),
            child: Text(
              current.text,
              key: ValueKey<int>(_index),
              style: textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  versionLabel == null ? 'Pokédex' : 'Pokédex de Pokémon $versionLabel',
                  style: textTheme.bodySmall,
                ),
              ),
              if (widget.descriptions.length > 1) ...<Widget>[
                IconButton(
                  tooltip: 'Descripción más reciente',
                  onPressed: _index > 0 ? () => setState(() => _index--) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('${_index + 1}/${widget.descriptions.length}', style: textTheme.labelMedium),
                IconButton(
                  tooltip: 'Descripción anterior',
                  onPressed: _index < widget.descriptions.length - 1 ? () => setState(() => _index++) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AbilityChip extends ConsumerWidget {
  const _AbilityChip({required this.ability});

  final PokemonAbilitySlot ability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resource = ref.watch(localizedResourceFor(ability.url));
    final name = resource.value?.displayName.text ?? Formatters.slugToTitle(ability.slug);
    return ActionChip(
      avatar: Icon(
        ability.isHidden ? Icons.visibility_off_rounded : Icons.auto_fix_high_rounded,
        size: 18,
        color: AppColors.retroBrown,
      ),
      label: Text(ability.isHidden ? '$name · oculta' : name),
      tooltip: 'Ver qué hace $name',
      backgroundColor: AppColors.white,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        builder: (context) => _AbilitySheet(ability: ability),
      ),
    );
  }
}

class _AbilitySheet extends ConsumerWidget {
  const _AbilitySheet({required this.ability});

  final PokemonAbilitySlot ability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resource = ref.watch(localizedResourceFor(ability.url));
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.xl),
        child: resource.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => ErrorRetryView(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(localizedResourceFor(ability.url)),
          ),
          data: (data) {
            final LocalizedText? description = data.description;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(data.displayName.text, style: textTheme.headlineSmall),
                if (ability.isHidden) ...<Widget>[
                  const SizedBox(height: 4),
                  Text('Habilidad oculta', style: textTheme.labelMedium?.copyWith(color: AppColors.pokeRedDeep)),
                ],
                const SizedBox(height: AppSpacing.md),
                if (description == null)
                  Text('PokéAPI no tiene descripción para esta habilidad.', style: textTheme.bodyMedium)
                else ...<Widget>[
                  Text(description.text, style: textTheme.bodyLarge),
                  if (!description.isSpanish) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Text('Descripción disponible solo en inglés.', style: textTheme.bodySmall),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TextSkeleton extends StatelessWidget {
  const _TextSkeleton({required this.lines});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < lines; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 14,
              width: i == lines - 1 ? 180 : double.infinity,
              decoration: const BoxDecoration(color: AppColors.sand, borderRadius: AppRadii.smAll),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estadísticas
// ─────────────────────────────────────────────────────────────────────────────

class StatsTab extends StatelessWidget {
  const StatsTab({super.key, required this.stats});

  final BaseStats stats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return RetroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final (index, kind) in StatKind.values.indexed)
            PokemonStatBar(kind: kind, value: stats[kind], delay: Duration(milliseconds: 60 * index)),
          const Divider(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              Expanded(child: Text('Total', style: textTheme.titleMedium)),
              Text('${stats.total}', style: textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Barras sobre una escala de 0 a ${BaseStats.maxValue}, el valor base más alto posible.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Debilidades
// ─────────────────────────────────────────────────────────────────────────────

class MatchupsTab extends StatelessWidget {
  const MatchupsTab({super.key, required this.types});

  final List<PokemonType> types;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final matchups = TypeChart.matchups(types);
    final groups = <(String, String, List<PokemonType>)>[
      ('Muy débil', '×4', matchups.quadrupleWeak),
      ('Débil', '×2', matchups.doubleWeak),
      ('Resiste', '×½', matchups.halfResist),
      ('Resiste mucho', '×¼', matchups.quarterResist),
      ('Inmune', '×0', matchups.immune),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (title, multiplier, list) in groups)
          if (list.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: RetroPanel(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: Text(title, style: textTheme.titleMedium)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: const BoxDecoration(color: AppColors.retroBrownDark, borderRadius: AppRadii.smAll),
                          child: Text(
                            multiplier,
                            style: textTheme.labelLarge?.copyWith(color: AppColors.pikachuYellow),
                            semanticsLabel: 'multiplicador $multiplier',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[for (final type in list) PokemonTypeBadge(type: type)],
                    ),
                  ],
                ),
              ),
            ),
        Text(
          'Cálculo con la tabla de tipos actual (Gen. VI en adelante). No considera habilidades como Levitación ni objetos.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Datos rápidos
// ─────────────────────────────────────────────────────────────────────────────

class QuickFacts extends StatelessWidget {
  const QuickFacts({super.key, required this.detail, required this.generation});

  final PokemonDetail? detail;
  final int? generation;

  @override
  Widget build(BuildContext context) {
    final data = detail;
    return Row(
      children: <Widget>[
        Expanded(
          child: _FactTile(
            icon: Icons.height_rounded,
            label: 'Altura',
            value: data == null ? '…' : Formatters.heightMeters(data.heightDecimeters),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _FactTile(
            icon: Icons.monitor_weight_rounded,
            label: 'Peso',
            value: data == null ? '…' : Formatters.weightKg(data.weightHectograms),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _FactTile(
            icon: Icons.public_rounded,
            label: 'Generación',
            value: generation == null
                ? '…'
                : '${Formatters.roman(generation!)} · ${Generations.regionNames[generation] ?? ''}',
          ),
        ),
      ],
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadii.mdAll,
          border: Border.all(color: AppColors.retroBrown.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 16, color: AppColors.inkMuted),
                const SizedBox(width: 4),
                Flexible(child: Text(label, style: textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: textTheme.titleSmall, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
