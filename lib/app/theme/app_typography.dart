import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Tipografía: Fredoka (títulos), Nunito (lectura) y Press Start 2P (detalles
/// retro breves como números de Pokédex). Todas OFL y empaquetadas.
abstract final class AppTypography {
  static const String display = 'Fredoka';
  static const String body = 'Nunito';
  static const String pixel = 'PressStart2P';

  static TextTheme textTheme() {
    const ink = AppColors.ink;
    return const TextTheme(
      displayLarge: TextStyle(fontFamily: display, fontWeight: FontWeight.w700, fontSize: 52, height: 1.05, color: ink),
      displayMedium: TextStyle(fontFamily: display, fontWeight: FontWeight.w700, fontSize: 42, height: 1.08, color: ink),
      displaySmall: TextStyle(fontFamily: display, fontWeight: FontWeight.w700, fontSize: 34, height: 1.1, color: ink),
      headlineLarge: TextStyle(fontFamily: display, fontWeight: FontWeight.w700, fontSize: 30, height: 1.15, color: ink),
      headlineMedium: TextStyle(fontFamily: display, fontWeight: FontWeight.w600, fontSize: 26, height: 1.2, color: ink),
      headlineSmall: TextStyle(fontFamily: display, fontWeight: FontWeight.w600, fontSize: 22, height: 1.2, color: ink),
      titleLarge: TextStyle(fontFamily: display, fontWeight: FontWeight.w600, fontSize: 20, height: 1.25, color: ink),
      titleMedium: TextStyle(fontFamily: display, fontWeight: FontWeight.w600, fontSize: 17, height: 1.25, color: ink),
      titleSmall: TextStyle(fontFamily: body, fontWeight: FontWeight.w800, fontSize: 14, height: 1.3, color: ink),
      bodyLarge: TextStyle(fontFamily: body, fontWeight: FontWeight.w400, fontSize: 16, height: 1.45, color: ink),
      bodyMedium: TextStyle(fontFamily: body, fontWeight: FontWeight.w400, fontSize: 14, height: 1.45, color: ink),
      bodySmall: TextStyle(fontFamily: body, fontWeight: FontWeight.w600, fontSize: 12, height: 1.4, color: AppColors.inkMuted),
      labelLarge: TextStyle(fontFamily: body, fontWeight: FontWeight.w800, fontSize: 15, height: 1.2, color: ink),
      labelMedium: TextStyle(fontFamily: body, fontWeight: FontWeight.w700, fontSize: 13, height: 1.2, color: ink),
      labelSmall: TextStyle(fontFamily: body, fontWeight: FontWeight.w700, fontSize: 11, height: 1.2, color: ink, letterSpacing: 0.2),
    );
  }

  /// Estilo pixel para números y etiquetas cortas. Nunca para párrafos.
  static TextStyle pixelStyle({double fontSize = 9, Color color = AppColors.ink}) {
    return TextStyle(fontFamily: pixel, fontSize: fontSize, height: 1.3, color: color, letterSpacing: 0.5);
  }
}
