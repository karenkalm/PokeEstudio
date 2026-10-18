import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../app/layout/responsive.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/audio/sound_service.dart';
import 'retro_widgets.dart';

/// Pantalla honesta para secciones que llegan en fases posteriores.
///
/// No simula la función: explica qué incluirá y ofrece una acción real.
class UpcomingFeatureView extends StatelessWidget {
  const UpcomingFeatureView({
    super.key,
    required this.title,
    required this.phase,
    required this.icon,
    required this.summary,
    required this.highlights,
  });

  final String title;
  final int phase;
  final IconData icon;
  final String summary;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final inset = centeredInset(constraints.maxWidth, maxWidth: Breakpoints.reading);
            return ListView(
              padding: EdgeInsets.fromLTRB(inset, AppSpacing.xl, inset, AppSpacing.xxl),
              children: <Widget>[
                Semantics(header: true, child: Text(title, style: textTheme.headlineMedium)),
                const SizedBox(height: AppSpacing.lg),
                RetroPanel(
                  color: AppColors.creamYellow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.retroBrown, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Icon(icon, color: AppColors.retroBrown, size: 28),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: const BoxDecoration(
                                    color: AppColors.retroBrownDark,
                                    borderRadius: AppRadii.smAll,
                                  ),
                                  child: Text(
                                    'EN CONSTRUCCIÓN · FASE $phase',
                                    style: AppTypography.pixelStyle(fontSize: 7, color: AppColors.pikachuYellow),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text('Todavía no está disponible', style: textTheme.titleMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(summary, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Lo que incluirá', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                for (final item in highlights)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.inkMuted),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(item, style: textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () {
                      playSound(context, SoundEffect.select);
                      context.go(AppRoutes.pokedex);
                    },
                    icon: const Icon(Icons.catching_pokemon),
                    label: const Text('Explorar la Pokédex'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
