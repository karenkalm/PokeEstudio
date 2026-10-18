import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/application/pokedex_index_controller.dart';
import '../../../shared/models/pokedex_entry.dart';

/// Especies abiertas recientemente (solo consultadas: no significa capturadas).
class RecentlyViewedController extends Notifier<List<int>> {
  static const String _key = 'home.recentlyViewed';
  static const int maxItems = 12;

  @override
  List<int> build() {
    final stored = ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const <String>[];
    return List<int>.unmodifiable(stored.map(int.tryParse).whereType<int>());
  }

  Future<void> record(int speciesId) async {
    if (state.isNotEmpty && state.first == speciesId) return;
    final updated = <int>[speciesId, ...state.where((id) => id != speciesId)].take(maxItems).toList();
    state = List<int>.unmodifiable(updated);
    await _persist();
  }

  Future<void> clear() async {
    state = const <int>[];
    await _persist();
  }

  Future<void> _persist() async {
    await ref.read(sharedPreferencesProvider).setStringList(_key, <String>[for (final id in state) '$id']);
  }
}

final recentlyViewedProvider = NotifierProvider<RecentlyViewedController, List<int>>(
  RecentlyViewedController.new,
  name: 'recentlyViewedProvider',
);

/// Fecha "de hoy" inyectable (las pruebas la fijan).
final todayProvider = Provider<DateTime>((ref) => DateTime.now(), name: 'todayProvider');

/// Selección diaria determinista: misma lista durante todo el día, distinta
/// cada día. Proviene del índice real; no hay datos de demostración.
List<PokedexEntry> dailyPicks(List<PokedexEntry> entries, DateTime date, {int count = 6}) {
  if (entries.isEmpty) return const <PokedexEntry>[];
  final seed = date.year * 10000 + date.month * 100 + date.day;
  final random = Random(seed);
  final picked = <PokedexEntry>[];
  final used = <int>{};
  final target = min(count, entries.length);
  while (picked.length < target) {
    final index = random.nextInt(entries.length);
    if (used.add(index)) picked.add(entries[index]);
  }
  return picked;
}

final dailyPicksProvider = Provider<AsyncValue<List<PokedexEntry>>>((ref) {
  final index = ref.watch(pokedexIndexProvider);
  final today = ref.watch(todayProvider);
  return index.whenData((data) => dailyPicks(data.entries, today));
}, name: 'dailyPicksProvider');
