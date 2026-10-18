import 'package:flutter/material.dart';

import '../../shared/models/pokemon_type.dart';
import 'app_colors.dart';

/// Colores e icono de un tipo. Es una capa de personalización: tiñe tarjetas
/// e insignias, pero no reemplaza la identidad global de la app.
class TypePalette {
  const TypePalette({required this.base, required this.soft, required this.onBase, required this.icon});

  /// Color principal (insignias, acentos).
  final Color base;

  /// Fondo pastel (tarjetas, cabeceras).
  final Color soft;

  /// Color de texto sobre [base], elegido para superar 4.5:1.
  final Color onBase;

  /// Icono de apoyo: el tipo nunca se comunica solo con color.
  final IconData icon;

  static TypePalette of(PokemonType type) => _palettes[type]!;

  static const Map<PokemonType, TypePalette> _palettes = <PokemonType, TypePalette>{
    PokemonType.normal: TypePalette(base: Color(0xFFA8A77A), soft: Color(0xFFF1EFE2), onBase: AppColors.ink, icon: Icons.pets_rounded),
    PokemonType.fire: TypePalette(base: Color(0xFFF27D52), soft: Color(0xFFFFE3D6), onBase: AppColors.ink, icon: Icons.local_fire_department_rounded),
    PokemonType.water: TypePalette(base: Color(0xFF4B8FE8), soft: Color(0xFFDCEBFF), onBase: AppColors.ink, icon: Icons.water_drop_rounded),
    PokemonType.grass: TypePalette(base: Color(0xFF5DBB73), soft: Color(0xFFD5F1D7), onBase: AppColors.ink, icon: Icons.eco_rounded),
    PokemonType.electric: TypePalette(base: Color(0xFFF5C731), soft: Color(0xFFFFF0B3), onBase: AppColors.ink, icon: Icons.bolt_rounded),
    PokemonType.ice: TypePalette(base: Color(0xFF6CCFD9), soft: Color(0xFFDDF5F7), onBase: AppColors.ink, icon: Icons.ac_unit_rounded),
    PokemonType.fighting: TypePalette(base: Color(0xFFC4483E), soft: Color(0xFFF7DAD6), onBase: AppColors.white, icon: Icons.sports_mma_rounded),
    PokemonType.poison: TypePalette(base: Color(0xFF9550AA), soft: Color(0xFFEFDDF4), onBase: AppColors.white, icon: Icons.science_rounded),
    PokemonType.ground: TypePalette(base: Color(0xFFD2A45B), soft: Color(0xFFF4E6CC), onBase: AppColors.ink, icon: Icons.landscape_rounded),
    PokemonType.flying: TypePalette(base: Color(0xFF8FA6EE), soft: Color(0xFFE4E9FC), onBase: AppColors.ink, icon: Icons.air_rounded),
    PokemonType.psychic: TypePalette(base: Color(0xFFF2668B), soft: Color(0xFFFCDDE7), onBase: AppColors.ink, icon: Icons.psychology_rounded),
    PokemonType.bug: TypePalette(base: Color(0xFF9DB12E), soft: Color(0xFFEBF1CC), onBase: AppColors.ink, icon: Icons.bug_report_rounded),
    PokemonType.rock: TypePalette(base: Color(0xFFB69F45), soft: Color(0xFFF0E8CB), onBase: AppColors.ink, icon: Icons.terrain_rounded),
    PokemonType.ghost: TypePalette(base: Color(0xFF745C9E), soft: Color(0xFFE6DFF2), onBase: AppColors.white, icon: Icons.nights_stay_rounded),
    PokemonType.dragon: TypePalette(base: Color(0xFF6A50E6), soft: Color(0xFFE2DCFB), onBase: AppColors.white, icon: Icons.castle_rounded),
    PokemonType.dark: TypePalette(base: Color(0xFF5F4C43), soft: Color(0xFFE6DED8), onBase: AppColors.white, icon: Icons.dark_mode_rounded),
    PokemonType.steel: TypePalette(base: Color(0xFF93A3B5), soft: Color(0xFFE7ECF1), onBase: AppColors.ink, icon: Icons.hardware_rounded),
    PokemonType.fairy: TypePalette(base: Color(0xFFE58BC5), soft: Color(0xFFFBE3EF), onBase: AppColors.ink, icon: Icons.auto_awesome_rounded),
  };
}
