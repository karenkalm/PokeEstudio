import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../features/collection/presentation/collection_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/mini_games/presentation/mini_games_screen.dart';
import '../features/pokedex/presentation/pokedex_screen.dart';
import '../features/pokemon_detail/presentation/pokemon_detail_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/team_builder/presentation/team_builder_screen.dart';
import '../shared/widgets/feedback_views.dart';
import 'app_shell.dart';

/// Rutas de la app (en español, como el resto de la interfaz).
abstract final class AppRoutes {
  static const String home = '/inicio';
  static const String pokedex = '/pokedex';
  static const String team = '/equipo';
  static const String miniGames = '/minijuegos';
  static const String collection = '/coleccion';
  static const String settings = '/ajustes';

  static String pokemon(int speciesId) => '/pokemon/$speciesId';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      // Las cinco secciones principales. indexedStack conserva el estado de
      // cada pestaña (scroll, búsqueda, filtros) al cambiar de sección.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(path: AppRoutes.pokedex, builder: (context, state) => const PokedexScreen()),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(path: AppRoutes.team, builder: (context, state) => const TeamBuilderScreen()),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(path: AppRoutes.miniGames, builder: (context, state) => const MiniGamesScreen()),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(path: AppRoutes.collection, builder: (context, state) => const CollectionScreen()),
          ]),
        ],
      ),
      // Pantallas completas por encima de la barra inferior.
      GoRoute(
        path: '/pokemon/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return _fadeSlidePage(
            state,
            id == null ? const _NotFoundScreen() : PokemonDetailScreen(speciesId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(state, const SettingsScreen()),
      ),
    ],
    errorBuilder: (context, state) => const _NotFoundScreen(),
  );
  ref.onDispose(router.dispose);
  return router;
}, name: 'routerProvider');

/// Transición suave (aparece y sube un poco). Sin animación si el usuario
/// pidió reducir el movimiento.
Page<void> _fadeSlidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: CuteEmptyState(
          icon: Icons.explore_off_rounded,
          title: 'Esta página no existe',
          message: 'Puede que el enlace esté incompleto.',
          actionLabel: 'Volver al inicio',
          onAction: () => context.go(AppRoutes.home),
        ),
      ),
    );
  }
}
