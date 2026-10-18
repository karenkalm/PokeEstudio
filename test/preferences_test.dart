import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokestudio/core/providers.dart';
import 'package:pokestudio/features/home/application/home_providers.dart';
import 'package:pokestudio/features/settings/application/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_data.dart';

Future<ProviderContainer> makeContainer() async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('Vistos recientemente', () {
    test('el más reciente va primero, sin duplicados y con límite', () async {
      final container = await makeContainer();
      final notifier = container.read(recentlyViewedProvider.notifier);
      await notifier.record(1);
      await notifier.record(4);
      await notifier.record(1);
      expect(container.read(recentlyViewedProvider), <int>[1, 4]);

      for (var id = 10; id < 30; id++) {
        await notifier.record(id);
      }
      final list = container.read(recentlyViewedProvider);
      expect(list.length, RecentlyViewedController.maxItems);
      expect(list.first, 29);
    });

    test('persiste entre sesiones', () async {
      final first = await makeContainer();
      await first.read(recentlyViewedProvider.notifier).record(25);
      await first.read(recentlyViewedProvider.notifier).record(133);

      final second = await makeContainer();
      expect(second.read(recentlyViewedProvider), <int>[133, 25]);

      await second.read(recentlyViewedProvider.notifier).clear();
      final third = await makeContainer();
      expect(third.read(recentlyViewedProvider), isEmpty);
    });
  });

  group('Ajustes', () {
    test('valores por defecto', () async {
      final container = await makeContainer();
      final settings = container.read(settingsProvider);
      expect(settings.greetingName, 'entrenador');
      expect(settings.reduceMotion, isFalse);
      expect(settings.cardArtStyle, CardArtStyle.pixel);
    });

    test('guarda nombre (recortado), movimiento y estilo de tarjeta', () async {
      final container = await makeContainer();
      final notifier = container.read(settingsProvider.notifier);
      await notifier.setTrainerName('   Jorge Luis Pizano Saucedo y más   ');
      await notifier.setReduceMotion(true);
      await notifier.setCardArtStyle(CardArtStyle.artwork);

      final reopened = await makeContainer();
      final settings = reopened.read(settingsProvider);
      expect(settings.trainerName.length, SettingsController.maxNameLength);
      expect(settings.trainerName.startsWith('Jorge'), isTrue);
      expect(settings.reduceMotion, isTrue);
      expect(settings.cardArtStyle, CardArtStyle.artwork);
    });
  });

  group('Destacados del día', () {
    test('son deterministas por fecha y no se repiten', () {
      final entries = loadRealIndex().entries;
      final day = DateTime(2026, 10, 17);
      final a = dailyPicks(entries, day);
      final b = dailyPicks(entries, day);
      final other = dailyPicks(entries, DateTime(2026, 10, 18));
      expect(a.map((e) => e.id), b.map((e) => e.id));
      expect(a.map((e) => e.id).toSet().length, a.length);
      expect(a.length, 6);
      expect(a.map((e) => e.id).toList(), isNot(other.map((e) => e.id).toList()));
    });
  });
}
