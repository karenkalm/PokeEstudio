import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Tamaño de ventana según las guías de Material 3.
enum WindowSize {
  /// Celulares (< 600 dp).
  compact,

  /// Tablets y ventanas medianas (600–1023 dp).
  medium,

  /// Computadoras y tablets grandes en horizontal (≥ 1024 dp).
  expanded;

  static WindowSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Breakpoints.expanded) return WindowSize.expanded;
    if (width >= Breakpoints.medium) return WindowSize.medium;
    return WindowSize.compact;
  }

  bool get isCompact => this == WindowSize.compact;
  bool get isExpanded => this == WindowSize.expanded;
}

abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 1024;

  /// A partir de este ancho la barra inferior se convierte en un riel lateral.
  static const double navigationRail = 840;

  /// Ancho máximo del contenido para que nada se estire en monitores grandes.
  static const double content = 1200;

  /// Ancho máximo de pantallas de lectura o formularios (Ajustes, avisos).
  static const double reading = 760;
}

/// Margen horizontal que centra el contenido dentro de [maxWidth] y nunca es
/// menor que el margen normal de pantalla. [availableWidth] es el ancho real
/// del área (por ejemplo, `constraints.maxWidth` de un `LayoutBuilder`).
double centeredInset(double availableWidth, {double maxWidth = Breakpoints.content, double minInset = AppSpacing.screen}) {
  final inset = (availableWidth - maxWidth) / 2;
  return inset > minInset ? inset : minInset;
}

/// Centra a su hijo, limita su ancho y le da todo el ancho disponible hasta
/// ese límite (así el contenido alineado a la izquierda no se descuadra).
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.maxWidth = Breakpoints.content});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

/// Medidas compartidas de la estructura principal.
abstract final class AppShellMetrics {
  static const double railWidth = 96;
}
