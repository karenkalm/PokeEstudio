import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/pokedex_entry.dart';
import '../../../../shared/widgets/pokemon_search_bar.dart';
import '../../../../shared/widgets/pokemon_sprite.dart';
import '../../../pokedex/application/pokedex_providers.dart';
import '../../../pokedex/domain/pokedex_query.dart';

/// Buscador del inicio con sugerencias instantáneas (búsqueda local).
class HomeSearchField extends ConsumerStatefulWidget {
  const HomeSearchField({super.key, required this.entries});

  final List<PokedexEntry> entries;

  @override
  ConsumerState<HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends ConsumerState<HomeSearchField> {
  static const int _maxSuggestions = 5;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _openPokedexWithQuery() {
    playSound(context, SoundEffect.open);
    final text = _controller.text.trim();
    ref.read(pokedexQueryProvider.notifier).setQuery(text);
    _focusNode.unfocus();
    context.go(AppRoutes.pokedex);
  }

  void _openEntry(PokedexEntry entry) {
    playSound(context, SoundEffect.open);
    _focusNode.unfocus();
    context.push(AppRoutes.pokemon(entry.id));
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim();
    final results = text.isEmpty ? const <PokedexEntry>[] : PokedexQuery.search(widget.entries, text);
    final showSuggestions = _focusNode.hasFocus && text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokemonSearchBar(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _openPokedexWithQuery(),
        ),
        AnimatedSize(
          duration: AppMotion.of(context, AppMotion.medium),
          curve: AppMotion.emphasized,
          alignment: Alignment.topCenter,
          child: !showSuggestions
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadii.lgAll,
                    border: Border.all(color: AppColors.retroBrown, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (results.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'Ningún Pokémon coincide con "$text".',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                          ),
                        ),
                      for (final entry in results.take(_maxSuggestions))
                        _SuggestionTile(entry: entry, onTap: () => _openEntry(entry)),
                      if (results.isNotEmpty)
                        InkWell(
                          onTap: _openPokedexWithQuery,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    results.length == 1
                                        ? 'Ver en la Pokédex'
                                        : 'Ver los ${results.length} resultados en la Pokédex',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: AppColors.pokeBlueDeep),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.pokeBlueDeep),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.entry, required this.onTap});

  final PokedexEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${entry.nameEs}, número ${entry.id}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          child: Row(
            children: <Widget>[
              PokemonSprite(url: entry.spriteUrl, style: SpriteStyle.pixel, size: 52),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(entry.nameEs, style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '${Formatters.dexNumber(entry.id)} · ${entry.types.map((t) => t.spanishName).join(' / ')}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
