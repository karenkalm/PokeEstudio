import 'package:flutter/material.dart';

/// Paleta de PokéStudio. Los colores clásicos son acentos sobre una base
/// crema; los pares de texto/fondo superan 4.5:1 (WCAG AA).
abstract final class AppColors {
  // Acentos clásicos
  static const Color pokeRed = Color(0xFFE94B4B);

  /// Rojo profundo para fondos de botón con texto blanco (5.1:1).
  static const Color pokeRedDeep = Color(0xFFC73A3A);
  static const Color coral = Color(0xFFFF7777);
  static const Color pikachuYellow = Color(0xFFFFD95A);
  static const Color creamYellow = Color(0xFFFFF0B3);
  static const Color pokeBlue = Color(0xFF4B8FE8);

  /// Azul para texto y enlaces sobre fondos claros (5.0:1).
  static const Color pokeBlueDeep = Color(0xFF2F6FC4);
  static const Color skyBlue = Color(0xFFBBDFFF);
  static const Color grassGreen = Color(0xFF8BCF9B);
  static const Color mint = Color(0xFFD5F1D7);
  static const Color lavender = Color(0xFFC9B8F2);
  static const Color pastelPink = Color(0xFFF7C7D9);

  // Base cálida
  static const Color warmCream = Color(0xFFFFF7E8);
  static const Color creamDeep = Color(0xFFF6E9D2);
  static const Color sand = Color(0xFFEAD9BC);
  static const Color retroBrown = Color(0xFF563B2B);
  static const Color retroBrownDark = Color(0xFF34251F);
  static const Color white = Color(0xFFFFFFFF);

  // Texto
  static const Color ink = Color(0xFF29252A);
  static const Color inkMuted = Color(0xFF6B5B50);

  /// Sombra cálida (marrón translúcido) para tarjetas y paneles.
  static Color get shadow => retroBrown.withValues(alpha: 0.16);

  // Barras de estadísticas por rango (siempre acompañadas del número).
  static const Color statLow = coral;
  static const Color statMid = pikachuYellow;
  static const Color statGood = grassGreen;
  static const Color statHigh = pokeBlue;
}
