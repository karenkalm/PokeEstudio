import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema global. Toda la app toma colores, tipografía y formas de aquí.
abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.pokeRed,
      primary: AppColors.pokeRedDeep,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.pastelPink,
      onPrimaryContainer: AppColors.retroBrownDark,
      secondary: AppColors.pokeBlueDeep,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.skyBlue,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.retroBrown,
      onTertiary: AppColors.warmCream,
      tertiaryContainer: AppColors.creamYellow,
      onTertiaryContainer: AppColors.retroBrownDark,
      error: AppColors.pokeRedDeep,
      onError: AppColors.white,
      surface: AppColors.warmCream,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: const Color(0xFFFFFBF3),
      surfaceContainer: const Color(0xFFFBF0DD),
      surfaceContainerHigh: AppColors.creamDeep,
      surfaceContainerHighest: AppColors.sand,
      outline: AppColors.retroBrown,
      outlineVariant: const Color(0xFFD9C4A6),
      shadow: AppColors.retroBrownDark,
    );

    final textTheme = AppTypography.textTheme();
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadii.mdAll);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.warmCream,
      fontFamily: AppTypography.body,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.warmCream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.lgAll,
          side: BorderSide(color: AppColors.retroBrown.withValues(alpha: 0.85), width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.pikachuYellow,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(size: 24, color: selected ? AppColors.retroBrownDark : AppColors.inkMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: AppTypography.body,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            color: selected ? AppColors.retroBrownDark : AppColors.inkMuted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.pokeRedDeep,
          foregroundColor: AppColors.white,
          textStyle: textTheme.labelLarge,
          padding: buttonPadding,
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.retroBrownDark,
          backgroundColor: AppColors.white,
          textStyle: textTheme.labelLarge,
          padding: buttonPadding,
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          side: const BorderSide(color: AppColors.retroBrown, width: 2),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.pokeBlueDeep,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(48, AppSpacing.minTouchTarget),
          shape: buttonShape,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.lgAll,
          borderSide: BorderSide(color: AppColors.retroBrown, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.lgAll,
          borderSide: BorderSide(color: AppColors.retroBrown, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.lgAll,
          borderSide: BorderSide(color: AppColors.pokeBlueDeep, width: 2.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.creamYellow,
        side: const BorderSide(color: AppColors.retroBrown, width: 1.5),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        checkmarkColor: AppColors.retroBrownDark,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.warmCream,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.retroBrown,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.warmCream,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.xlAll,
          side: BorderSide(color: AppColors.retroBrown, width: 2),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.retroBrownDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.warmCream, fontWeight: FontWeight.w700),
        actionTextColor: AppColors.pikachuYellow,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: AppColors.pokeRedDeep,
        inactiveTrackColor: AppColors.sand,
        thumbColor: AppColors.pokeRedDeep,
        overlayColor: AppColors.pokeRed.withValues(alpha: 0.14),
        valueIndicatorColor: AppColors.retroBrownDark,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(color: AppColors.warmCream),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.white : AppColors.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.pokeRedDeep : AppColors.sand,
        ),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(AppColors.retroBrown),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(color: AppColors.retroBrownDark, borderRadius: AppRadii.smAll),
        textStyle: textTheme.labelMedium?.copyWith(color: AppColors.warmCream),
        waitDuration: const Duration(milliseconds: 400),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE5D3B8), thickness: 1.5, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.pokeRedDeep,
        linearTrackColor: AppColors.sand,
        circularTrackColor: AppColors.sand,
      ),
    );
  }
}
