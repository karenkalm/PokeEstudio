import 'package:material_ui/material_ui.dart';

/// Espaciado en múltiplos de 4 y radios del sistema visual.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margen lateral de las pantallas.
  static const double screen = 20;

  /// Ancho mínimo recomendado para áreas táctiles.
  static const double minTouchTarget = 48;
}

abstract final class AppRadii {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Duraciones de animación. Todas se anulan con "reducir movimiento".
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 450);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve playful = Curves.easeOutBack;

  /// `true` si el sistema o la app piden reducir el movimiento.
  static bool reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);

  static Duration of(BuildContext context, Duration duration) => reduced(context) ? Duration.zero : duration;
}
