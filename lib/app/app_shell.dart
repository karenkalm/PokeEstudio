import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/sound_service.dart';
import '../shared/widgets/pokestudio_logo.dart';
import 'layout/responsive.dart';
import 'router.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

/// Estructura principal con las cinco secciones.
///
/// * Celular y ventanas angostas: barra de navegación inferior.
/// * Tablet en horizontal y computadora (≥ 840 dp): riel lateral, para no
///   estirar una barra de cinco botones a todo lo ancho del monitor.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<_Destination> _destinations = <_Destination>[
    _Destination('Inicio', 'Inicio', Icons.home_outlined, Icons.home_rounded),
    _Destination('Pokédex', 'Pokédex', Icons.catching_pokemon, Icons.catching_pokemon),
    _Destination('Mi equipo', 'Mi equipo', Icons.groups_outlined, Icons.groups_rounded),
    _Destination('Minijuegos', 'Minijuegos', Icons.sports_esports_outlined, Icons.sports_esports_rounded),
    _Destination('Colección', 'Mi colección', Icons.collections_bookmark_outlined, Icons.collections_bookmark_rounded),
  ];

  void _onSelected(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    playSound(context, SoundEffect.select);
    // Tocar la pestaña activa vuelve a su pantalla inicial.
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final useRail = MediaQuery.sizeOf(context).width >= Breakpoints.navigationRail;
    if (useRail) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            _SideRail(
              selectedIndex: navigationShell.currentIndex,
              destinations: _destinations,
              onSelected: (index) => _onSelected(context, index),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.warmCream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: const Border(top: BorderSide(color: AppColors.retroBrown, width: 2)),
          boxShadow: <BoxShadow>[
            BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => _onSelected(context, index),
            destinations: <Widget>[
              for (final destination in _destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                  tooltip: destination.tooltip,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Riel lateral para pantallas anchas, con el logotipo arriba y Ajustes abajo.
class _SideRail extends StatelessWidget {
  const _SideRail({required this.selectedIndex, required this.destinations, required this.onSelected});

  final int selectedIndex;
  final List<_Destination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppShellMetrics.railWidth,
      decoration: const BoxDecoration(
        color: AppColors.creamDeep,
        border: Border(right: BorderSide(color: AppColors.retroBrown, width: 2)),
      ),
      child: SafeArea(
        right: false,
        child: NavigationRail(
          backgroundColor: Colors.transparent,
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          labelType: NavigationRailLabelType.all,
          // En ventanas bajas (tablet horizontal) los destinos se desplazan
          // en lugar de desbordarse.
          scrollable: true,
          groupAlignment: -0.6,
          minWidth: AppShellMetrics.railWidth - 2,
          indicatorColor: AppColors.pikachuYellow,
          selectedIconTheme: const IconThemeData(color: AppColors.retroBrownDark, size: 26),
          unselectedIconTheme: const IconThemeData(color: AppColors.inkMuted, size: 24),
          selectedLabelTextStyle: const TextStyle(
            fontFamily: AppTypography.body,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: AppColors.retroBrownDark,
          ),
          unselectedLabelTextStyle: const TextStyle(
            fontFamily: AppTypography.body,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.inkMuted,
          ),
          leading: const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 20),
            child: PokestudioLogo(markSize: 44, showWordmark: false),
          ),
          trailingAtBottom: true,
          trailing: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              tooltip: 'Ajustes',
              icon: const Icon(Icons.settings_rounded, color: AppColors.retroBrown),
              onPressed: () {
                playSound(context, SoundEffect.open);
                context.push(AppRoutes.settings);
              },
            ),
          ),
          destinations: <NavigationRailDestination>[
            for (final destination in destinations)
              NavigationRailDestination(
                icon: Tooltip(message: destination.tooltip, child: Icon(destination.icon)),
                selectedIcon: Icon(destination.selectedIcon),
                label: Text(destination.label, textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.tooltip, this.icon, this.selectedIcon);

  final String label;
  final String tooltip;
  final IconData icon;
  final IconData selectedIcon;
}
