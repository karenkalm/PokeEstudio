import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokedex_entry.dart';
import '../repositories/pokedex_index_repository.dart';

/// Estado global del índice de la Pokédex.
///
/// Carga el índice local al instante y, unos segundos después, comprueba en
/// segundo plano si PokéAPI publicó especies nuevas. Si falla la comprobación
/// (por ejemplo, sin conexión), la app sigue funcionando con el índice local.
class PokedexIndexController extends AsyncNotifier<PokedexIndex> {
  static const Duration updateCheckDelay = Duration(seconds: 4);

  @override
  Future<PokedexIndex> build() async {
    final repository = ref.watch(pokedexIndexRepositoryProvider);
    final index = await repository.load();
    unawaited(_checkForUpdates(repository, index));
    return index;
  }

  Future<void> _checkForUpdates(PokedexIndexRepository repository, PokedexIndex index) async {
    await Future<void>.delayed(updateCheckDelay);
    if (!ref.mounted) return;
    try {
      final updated = await repository.fetchNewSpecies(index);
      if (updated != null && ref.mounted) {
        state = AsyncData<PokedexIndex>(updated);
      }
    } on Object catch (error) {
      debugPrint('PokéStudio: no se pudo comprobar si hay especies nuevas ($error).');
    }
  }
}

final pokedexIndexProvider = AsyncNotifierProvider<PokedexIndexController, PokedexIndex>(
  PokedexIndexController.new,
  name: 'pokedexIndexProvider',
);
