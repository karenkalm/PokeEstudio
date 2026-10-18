import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'theme/app_colors.dart';

/// Estructura con la barra de navegación inferior de cinco secciones.
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

  void _onSelected(int index) {
    HapticFeedback.selectionClick();
    // Tocar la pestaña activa vuelve a su pantalla inicial.
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
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
            onDestinationSelected: _onSelected,
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

class _Destination {
  const _Destination(this.label, this.tooltip, this.icon, this.selectedIcon);

  final String label;
  final String tooltip;
  final IconData icon;
  final IconData selectedIcon;
}
