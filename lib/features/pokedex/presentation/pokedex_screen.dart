import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../app/layout/responsive.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/application/pokedex_index_controller.dart';
import '../../../shared/widgets/feedback_views.dart';
import '../../../shared/widgets/pokemon_card.dart';
import '../../../shared/widgets/pokemon_search_bar.dart';
import '../../../shared/widgets/pokemon_type_badge.dart';
import '../application/pokedex_providers.dart';
import '../domain/pokedex_filter.dart';
import '../domain/pokedex_query.dart';
import 'widgets/active_filters_bar.dart';
import 'widgets/pokemon_filter_sheet.dart';

/// Pokédex completa: búsqueda, filtros combinables, orden y cuadrícula.
class PokedexScreen extends ConsumerStatefulWidget {
  const PokedexScreen({super.key});

  @override
  ConsumerState<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends ConsumerState<PokedexScreen> {
  static const Duration _debounce = Duration(milliseconds: 220);

  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounceTimer;
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(pokedexQueryProvider);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scroll.offset > 900;
    if (show != _showScrollTop) setState(() => _showScrollTop = show);
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (mounted) ref.read(pokedexQueryProvider.notifier).setQuery(value);
    });
  }

  void _scrollToTop() {
    playSound(context, SoundEffect.arrow);
    final duration = AppMotion.of(context, AppMotion.slow);
    if (duration == Duration.zero) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(0, duration: duration, curve: AppMotion.emphasized);
    }
  }

  Future<void> _openFilters() async {
    playSound(context, SoundEffect.open);
    final current = ref.read(pokedexFilterProvider);
    final result = await showModalBottomSheet<PokedexFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PokemonFilterSheet(initial: current),
    );
    if (result != null && mounted) {
      HapticFeedback.lightImpact();
      playSound(context, SoundEffect.success);
      ref.read(pokedexFilterProvider.notifier).apply(result);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  void _applySuggestion(SearchSuggestion suggestion) {
    playSound(context, SoundEffect.open);
    final controller = ref.read(pokedexFilterProvider.notifier);
    switch (suggestion) {
      case TypeSuggestion(:final type):
        controller.showOnlyType(type);
      case GenerationSuggestion(:final generation):
        controller.showOnlyGeneration(generation);
    }
    _debounceTimer?.cancel();
    _search.clear();
    ref.read(pokedexQueryProvider.notifier).setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    // Si otra pantalla (p. ej. el buscador de Inicio) cambia la búsqueda,
    // el campo de texto se sincroniza.
    ref.listen<String>(pokedexQueryProvider, (previous, next) {
      if (_search.text != next) {
        _search.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
      }
    });

    final results = ref.watch(pokedexResultsProvider);
    final filter = ref.watch(pokedexFilterProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: _showScrollTop
          ? FloatingActionButton.small(
              tooltip: 'Volver arriba',
              backgroundColor: AppColors.retroBrownDark,
              foregroundColor: AppColors.pikachuYellow,
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward_rounded),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => _buildBody(context, constraints.maxWidth, results, filter, textTheme),
        ),
      ),
    );
  }

  /// Margen lateral: el normal en celular; en pantallas anchas, el que centra
  /// el contenido en [Breakpoints.content].
  static double _insetFor(double width) =>
      centeredInset(width, maxWidth: Breakpoints.content - 2 * AppSpacing.screen);

  Widget _buildBody(
    BuildContext context,
    double width,
    AsyncValue<PokedexResults> results,
    PokedexFilter filter,
    TextTheme textTheme,
  ) {
    final inset = _insetFor(width);
    return CustomScrollView(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(inset, AppSpacing.lg, inset, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Semantics(header: true, child: Text('Pokédex', style: textTheme.headlineMedium)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.retroBrownDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'NACIONAL',
                        style: AppTypography.pixelStyle(fontSize: 7, color: AppColors.pikachuYellow),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                PokemonSearchBar(
                  controller: _search,
                  focusNode: _searchFocus,
                  hintText: 'Nombre, número o forma (p. ej. "alola")',
                  onChanged: _onQueryChanged,
                  onSubmitted: (value) {
                    _debounceTimer?.cancel();
                    ref.read(pokedexQueryProvider.notifier).setQuery(value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    _FilterButton(activeCount: filter.activeCount, onPressed: _openFilters),
                    const SizedBox(width: AppSpacing.sm),
                    _SortButton(
                      value: filter.sort,
                      onSelected: (sort) {
                        playSound(context, SoundEffect.toggle);
                        ref.read(pokedexFilterProvider.notifier).setSort(sort);
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: results.maybeWhen(
                        data: (data) => Text(
                          data.items.length == data.totalInIndex
                              ? '${data.totalInIndex} Pokémon'
                              : '${data.items.length} de ${data.totalInIndex}',
                          textAlign: TextAlign.right,
                          style: textTheme.labelMedium?.copyWith(color: AppColors.inkMuted),
                          semanticsLabel: '${data.items.length} resultados',
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (results.value?.suggestion case final suggestion?)
          SliverToBoxAdapter(
            child: _SuggestionBanner(
              suggestion: suggestion,
              inset: inset,
              onApply: () => _applySuggestion(suggestion),
            ),
          ),
        if (filter.hasActiveFilters)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: MaxWidth(child: ActiveFiltersBar(filter: filter)),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ...results.when(
          loading: () => <Widget>[_loadingGrid(context, inset)],
          error: (error, _) => <Widget>[
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: ErrorRetryView(error: error, onRetry: () => ref.invalidate(pokedexIndexProvider)),
              ),
            ),
          ],
          data: (data) => data.items.isEmpty
              ? <Widget>[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CuteEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Sin coincidencias',
                        message: filter.hasActiveFilters
                            ? 'Ningún Pokémon cumple la búsqueda con los filtros activos.'
                            : 'Revisa el nombre o prueba con el número de la Pokédex.',
                        actionLabel: filter.hasActiveFilters ? 'Quitar filtros' : null,
                        onAction: filter.hasActiveFilters
                            ? () {
                                playSound(context, SoundEffect.back);
                                ref.read(pokedexFilterProvider.notifier).clear();
                              }
                            : null,
                      ),
                    ),
                  ),
                ]
              : <Widget>[_resultsGrid(context, data, inset)],
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  SliverGridDelegate _gridDelegate(BuildContext context) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 200,
      mainAxisExtent: PokemonCard.heightFor(context),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
    );
  }

  Widget _resultsGrid(BuildContext context, PokedexResults data, double inset) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      sliver: SliverGrid.builder(
        gridDelegate: _gridDelegate(context),
        itemCount: data.items.length,
        itemBuilder: (context, index) {
          final entry = data.items[index];
          return PokemonCard(key: ValueKey<int>(entry.id), entry: entry);
        },
      ),
    );
  }

  Widget _loadingGrid(BuildContext context, double inset) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      sliver: SliverGrid.builder(
        gridDelegate: _gridDelegate(context),
        itemCount: 8,
        itemBuilder: (context, index) => const LoadingPokemonCard(),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onPressed});

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: activeCount > 0,
        label: Text('$activeCount'),
        backgroundColor: AppColors.pokeRedDeep,
        child: const Icon(Icons.tune_rounded),
      ),
      label: Text(activeCount > 0 ? 'Filtros ($activeCount)' : 'Filtros'),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.value, required this.onSelected});

  final PokedexSort value;
  final ValueChanged<PokedexSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PokedexSort>(
      tooltip: 'Ordenar: ${value.label}',
      initialValue: value,
      onSelected: onSelected,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.mdAll,
        side: BorderSide(color: AppColors.retroBrown, width: 2),
      ),
      color: AppColors.warmCream,
      itemBuilder: (context) => <PopupMenuEntry<PokedexSort>>[
        for (final sort in PokedexSort.values)
          CheckedPopupMenuItem<PokedexSort>(value: sort, checked: sort == value, child: Text(sort.label)),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget, minWidth: AppSpacing.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadii.mdAll,
          border: Border.all(color: AppColors.retroBrown, width: 2),
        ),
        child: const Icon(Icons.sort_rounded, color: AppColors.retroBrownDark),
      ),
    );
  }
}

class _SuggestionBanner extends StatelessWidget {
  const _SuggestionBanner({required this.suggestion, required this.inset, required this.onApply});

  final SearchSuggestion suggestion;
  final double inset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Widget leading;
    final String label;
    switch (suggestion) {
      case TypeSuggestion(:final type):
        leading = PokemonTypeBadge(type: type, size: BadgeSize.small);
        label = 'Ver todos los Pokémon de tipo ${type.spanishName}';
      case GenerationSuggestion(:final generation):
        leading = const Icon(Icons.public_rounded, color: AppColors.retroBrown);
        label = 'Ver toda la ${Generations.label(generation)}';
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, AppSpacing.md, inset, 0),
      child: Material(
        color: AppColors.creamYellow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdAll,
          side: BorderSide(color: AppColors.retroBrown.withValues(alpha: 0.6), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onApply,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: <Widget>[
                leading,
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(label, style: textTheme.labelLarge)),
                const Icon(Icons.chevron_right_rounded, color: AppColors.retroBrown),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
