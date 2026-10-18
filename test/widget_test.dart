import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pokestudio/app/app.dart';
import 'package:pokestudio/app/router.dart';
import 'package:pokestudio/core/audio/sound_service.dart';
import 'package:pokestudio/core/providers.dart';
import 'package:pokestudio/features/home/application/home_providers.dart';
import 'package:pokestudio/features/home/presentation/home_screen.dart';
import 'package:pokestudio/features/pokedex/presentation/pokedex_screen.dart';
import 'package:pokestudio/features/pokemon_detail/presentation/pokemon_detail_screen.dart';
import 'package:pokestudio/shared/application/pokedex_index_controller.dart';
import 'package:pokestudio/shared/models/pokedex_entry.dart';
import 'package:pokestudio/shared/widgets/app_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_data.dart';

void main() {
  late PokedexIndex index;

  setUpAll(() => index = loadRealIndex());

  /// Por defecto, un celular de 392 × 851 dp. [physicalSize] y
  /// [pixelRatio] permiten simular tablets y computadoras.
  Future<void> pumpApp(
    WidgetTester tester, {
    Size physicalSize = const Size(1080, 2340),
    double pixelRatio = 2.75,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          networkImagesEnabledProvider.overrideWithValue(false),
          httpClientProvider.overrideWithValue(fixtureHttpClient()),
          pokedexIndexProvider.overrideWith(() => FakeIndexController(index)),
          todayProvider.overrideWithValue(DateTime(2026, 10, 17)),
          soundServiceProvider.overrideWithValue(const SilentSoundService()),
        ],
        child: const PokeStudioApp(),
      ),
    );
    await settle(tester);
  }

  testWidgets('el inicio muestra saludo, destacados y exploración', (tester) async {
    await pumpApp(tester);
    expect(find.text('¡Hola, entrenador!'), findsOneWidget);
    expect(find.text('Destacados de hoy'), findsOneWidget);

    // "Vistos recientemente" queda debajo del carrusel: se desplaza hasta él.
    final homeScroll = find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Aún no has abierto ninguna ficha'), 200, scrollable: homeScroll);
    expect(find.text('Aún no has abierto ninguna ficha'), findsOneWidget);
  });

  testWidgets('la barra inferior navega entre las cinco secciones', (tester) async {
    await pumpApp(tester);
    Finder navItem(String label) =>
        find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

    await tester.tap(navItem('Pokédex'));
    await settle(tester);
    expect(find.byType(PokedexScreen), findsOneWidget);
    expect(find.text('Bulbasaur'), findsWidgets);

    await tester.tap(navItem('Mi equipo'));
    await settle(tester);
    expect(find.text('EN CONSTRUCCIÓN · FASE 4'), findsOneWidget);

    await tester.tap(navItem('Minijuegos'));
    await settle(tester);
    expect(find.text('EN CONSTRUCCIÓN · FASE 6'), findsOneWidget);

    await tester.tap(navItem('Colección'));
    await settle(tester);
    expect(find.text('EN CONSTRUCCIÓN · FASE 3'), findsOneWidget);

    await tester.tap(navItem('Inicio'));
    await settle(tester);
    expect(find.text('Destacados de hoy'), findsOneWidget);
  });

  testWidgets('en computadora usa un riel lateral y centra el contenido', (tester) async {
    await pumpApp(tester, physicalSize: const Size(1440, 900), pixelRatio: 1);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Destacados de hoy'), findsOneWidget);

    // El contenido no se estira: el encabezado queda dentro de 1200 dp.
    final header = tester.getRect(find.text('Destacados de hoy'));
    expect(header.left, greaterThan(96));
    expect(header.right, lessThan(1440));

    Finder railItem(String label) =>
        find.descendant(of: find.byType(NavigationRail), matching: find.text(label));
    await tester.tap(railItem('Pokédex'));
    await settle(tester);
    expect(find.byType(PokedexScreen), findsOneWidget);
    expect(find.text('Bulbasaur'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en tablet vertical conserva la barra inferior sin desbordes', (tester) async {
    await pumpApp(tester, physicalSize: const Size(768, 1024), pixelRatio: 1);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Destacados de hoy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la búsqueda de la Pokédex filtra por nombre en español', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Pokédex')));
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, 'codigo cero');
    await settle(tester);
    expect(find.text('Código Cero'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('la ficha carga datos reales y se registra en "vistos"', (tester) async {
    await pumpApp(tester);
    tester.container().read(routerProvider).push(AppRoutes.pokemon(25));
    await settle(tester);

    expect(find.byType(PokemonDetailScreen), findsOneWidget);
    expect(find.text('Pikachu'), findsWidgets);
    expect(find.text('Pokémon Ratón'), findsOneWidget);
    final detailScroll =
        find.descendant(of: find.byType(PokemonDetailScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Electricidad Estática'), 200, scrollable: detailScroll);
    expect(find.text('Electricidad Estática'), findsOneWidget);
    expect(tester.container().read(recentlyViewedProvider), <int>[25]);

    await tester.ensureVisible(find.text('Estadísticas'));
    await tester.tap(find.text('Estadísticas'));
    await settle(tester);
    expect(find.text('320'), findsOneWidget); // total real de Pikachu

    await tester.ensureVisible(find.text('Debilidades'));
    await tester.tap(find.text('Debilidades'));
    await settle(tester);
    expect(find.text('Tierra'), findsOneWidget); // única debilidad (×2)
  });
}

/// Avanza el reloj de la prueba sin depender de pumpAndSettle (hay
/// indicadores de progreso indeterminados que nunca "se asientan").
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
