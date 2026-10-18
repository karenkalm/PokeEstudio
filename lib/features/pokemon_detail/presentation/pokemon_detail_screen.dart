import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/layout/responsive.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/type_palette.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/application/pokedex_index_controller.dart';
import '../../../shared/models/pokedex_entry.dart';
import '../../../shared/models/pokemon_detail.dart';
import '../../../shared/models/pokemon_type.dart';
import '../../../shared/widgets/feedback_views.dart';
import '../../../shared/widgets/pokemon_type_badge.dart';
import '../../../shared/widgets/retro_widgets.dart';
import '../../home/application/home_providers.dart';
import '../application/pokemon_detail_providers.dart';
import '../domain/pokedex_texts.dart';
import 'widgets/artwork_viewer.dart';
import 'widgets/detail_sections.dart';

/// Ficha completa de una especie.
///
/// Carga progresiva: el índice local pinta al instante nombre, número, tipos e
/// ilustración; después llegan de PokéAPI las estadísticas, habilidades,
/// medidas y descripciones.
class PokemonDetailScreen extends ConsumerStatefulWidget {
  const PokemonDetailScreen({super.key, required this.speciesId});

  final int speciesId;

  @override
  ConsumerState<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends ConsumerState<PokemonDetailScreen> {
  final ScrollController _scroll = ScrollController();
  DetailTab _tab = DetailTab.info;
  ArtworkMode _mode = ArtworkMode.artwork;

  @override
  void initState() {
    super.initState();
    _recordVisit();
  }

  @override
  void didUpdateWidget(covariant PokemonDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speciesId != widget.speciesId) {
      _recordVisit();
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _recordVisit() {
    final id = widget.speciesId;
    // Después del primer frame: no se modifica el estado durante la construcción.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recentlyViewedProvider.notifier).record(id);
    });
  }

  /// A partir de este ancho la ficha se muestra en dos columnas.
  static const double _twoColumnBreakpoint = 900;

  /// Las flechas retro ya suenan solas; el deslizamiento y el teclado piden
  /// el sonido aparte con [withSound].
  void _goToSpecies(int id, {bool withSound = false}) {
    if (withSound) playSound(context, SoundEffect.arrow);
    context.replace(AppRoutes.pokemon(id));
  }

  void _close() {
    playSound(context, SoundEffect.back);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.pokedex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final speciesId = widget.speciesId;
    final indexValue = ref.watch(pokedexIndexProvider).value;
    final PokedexEntry? entry = indexValue?.byId(speciesId);
    final pokemonId = entry?.pokemonId ?? speciesId;
    final detail = ref.watch(pokemonDetailProvider(pokemonId));
    final species = ref.watch(pokemonSpeciesProvider(speciesId));

    // Sin índice ni detalle no hay nada real que mostrar.
    if (entry == null && detail.hasError && !detail.hasValue) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: _close)),
        body: Center(
          child: ErrorRetryView(
            error: detail.error!,
            onRetry: () {
              ref.invalidate(pokemonDetailProvider(pokemonId));
              ref.invalidate(pokemonSpeciesProvider(speciesId));
            },
          ),
        ),
      );
    }

    final PokemonDetail? detailData = detail.value;
    // Si todavía no se conocen los tipos no se muestra ninguno (nada inventado);
    // Normal solo aporta un color neutro de fondo mientras carga.
    final List<PokemonType> types = entry?.types ?? detailData?.types ?? const <PokemonType>[];
    final primaryType = types.isEmpty ? PokemonType.normal : types.first;
    final palette = TypePalette.of(primaryType);
    final name = entry?.nameEs ?? species.value?.nameEs ?? Formatters.slugToTitle(detailData?.slug ?? '#$speciesId');
    final genus = species.value == null ? null : speciesGenus(species.value!);
    final previous = indexValue?.byId(speciesId - 1);
    final next = indexValue?.byId(speciesId + 1);
    final generation = entry?.generation ?? species.value?.generation;
    final textTheme = Theme.of(context).textTheme;

    // URLs reales por modo: primero las del detalle (vivas); mientras carga,
    // las del índice para que la ilustración aparezca al instante.
    final urls = <ArtworkMode, String>{
      if ((detailData?.sprites.artwork ?? entry?.artworkUrl) case final url?) ArtworkMode.artwork: url,
      if ((detailData?.sprites.frontDefault ?? entry?.spriteUrl) case final url?) ArtworkMode.pixel: url,
      if (detailData?.sprites.animated case final url?) ArtworkMode.animated: url,
    };

    final identity = <Widget>[
      ArtworkViewer(
        speciesId: speciesId,
        name: name,
        primaryType: primaryType,
        urls: urls,
        mode: _mode,
        onModeChanged: (mode) {
          playSound(context, SoundEffect.toggle);
          setState(() => _mode = mode);
        },
        onSwipePrevious: previous == null ? null : () => _goToSpecies(previous.id, withSound: true),
        onSwipeNext: next == null ? null : () => _goToSpecies(next.id, withSound: true),
      ),
      const SizedBox(height: AppSpacing.lg),
      Semantics(header: true, child: Text(name, style: textTheme.displaySmall)),
      if (genus != null)
        Text(
          genus.isSpanish ? genus.text : '${genus.text} (solo en inglés en PokéAPI)',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
        ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final type in types) PokemonTypeBadge(type: type, size: BadgeSize.large),
          if (entry?.isLegendary ?? false) const _StatusTag(label: 'Legendario'),
          if (entry?.isMythical ?? false) const _StatusTag(label: 'Singular'),
          if (entry?.isBaby ?? false) const _StatusTag(label: 'Bebé'),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      QuickFacts(detail: detailData, generation: generation),
    ];

    final tabs = <Widget>[
      DetailTabSelector(
        selected: _tab,
        onChanged: (tab) {
          if (tab != _tab) playSound(context, SoundEffect.select);
          setState(() => _tab = tab);
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.medium),
        switchInCurve: AppMotion.emphasized,
        layoutBuilder: (current, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previousChildren, if (current != null) current],
        ),
        child: KeyedSubtree(
          key: ValueKey<DetailTab>(_tab),
          child: switch (_tab) {
            DetailTab.info => InfoTab(speciesId: speciesId, detail: detail),
            DetailTab.stats => detail.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorRetryView(
                  error: error,
                  compact: true,
                  onRetry: () => ref.invalidate(pokemonDetailProvider(pokemonId)),
                ),
                data: (data) => StatsTab(stats: data.stats),
              ),
            DetailTab.matchups => types.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : MatchupsTab(types: types),
          },
        ),
      ),
      if (detail.hasError && !detail.hasValue && _tab == DetailTab.info) ...<Widget>[
        const SizedBox(height: AppSpacing.lg),
        ErrorRetryView(
          error: detail.error!,
          compact: true,
          onRetry: () => ref.invalidate(pokemonDetailProvider(pokemonId)),
        ),
      ],
    ];

    final footer = <Widget>[
      const SizedBox(height: AppSpacing.xxl),
      Text(
        'Datos e imágenes: PokéAPI · Proyecto de fans no oficial',
        textAlign: TextAlign.center,
        style: textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.xxl),
    ];

    final topBar = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[palette.soft, AppColors.warmCream],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: MaxWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0),
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: 'Volver',
                  onPressed: _close,
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.retroBrownDark),
                ),
                const Spacer(),
                RetroArrowButton(
                  pointsLeft: true,
                  tooltip: previous == null ? 'No hay especie anterior' : 'Anterior: ${previous.nameEs}',
                  onPressed: previous == null ? null : () => _goToSpecies(previous.id),
                ),
                const SizedBox(width: AppSpacing.sm),
                DexNumberTag(id: speciesId, large: true),
                const SizedBox(width: AppSpacing.sm),
                RetroArrowButton(
                  pointsLeft: false,
                  tooltip: next == null ? 'No hay especie siguiente' : 'Siguiente: ${next.nameEs}',
                  onPressed: next == null ? null : () => _goToSpecies(next.id),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );

    // Teclado (computadora): ← → cambian de especie y Esc cierra la ficha.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          if (previous != null) _goToSpecies(previous.id, withSound: true);
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          if (next != null) _goToSpecies(next.id, withSound: true);
        },
        const SingleActivator(LogicalKeyboardKey.escape): _close,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= _twoColumnBreakpoint;
              final Widget content;
              if (twoColumns) {
                // Computadora y tablet horizontal: identidad a la izquierda,
                // pestañas a la derecha, sin estirarse más de 1200 dp.
                content = SliverToBoxAdapter(
                  child: MaxWidth(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: identity,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xxl),
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: tabs,
                                ),
                              ),
                            ],
                          ),
                          ...footer,
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // Celular y tablet vertical: una columna (máximo 760 dp).
                content = SliverToBoxAdapter(
                  child: MaxWidth(
                    maxWidth: Breakpoints.reading,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ...identity,
                          const SizedBox(height: AppSpacing.xl),
                          ...tabs,
                          ...footer,
                        ],
                      ),
                    ),
                  ),
                );
              }
              return CustomScrollView(
                controller: _scroll,
                slivers: <Widget>[
                  SliverToBoxAdapter(child: topBar),
                  content,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.pikachuYellow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.retroBrown, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.star_rounded, size: 16, color: AppColors.retroBrownDark),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
