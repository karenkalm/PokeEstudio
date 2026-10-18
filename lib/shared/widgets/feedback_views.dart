import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/errors/app_failure.dart';

/// Desenvuelve los `ProviderException` de Riverpod y devuelve el fallo
/// original convertido en [AppFailure].
AppFailure failureFromError(Object error) {
  var current = error;
  while (current is ProviderException) {
    current = current.exception;
  }
  return toAppFailure(current);
}

/// Error comprensible con botón de reintento.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({super.key, required this.error, this.onRetry, this.compact = false});

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final failure = failureFromError(error);
    final textTheme = Theme.of(context).textTheme;
    final icon = switch (failure) {
      NetworkFailure() => Icons.wifi_off_rounded,
      TimeoutFailure() => Icons.hourglass_bottom_rounded,
      NotFoundFailure() => Icons.search_off_rounded,
      _ => Icons.error_outline_rounded,
    };
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: compact ? 48 : 72,
              height: compact ? 48 : 72,
              decoration: BoxDecoration(
                color: AppColors.pastelPink,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.retroBrown, width: 2),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: compact ? 24 : 34, color: AppColors.retroBrownDark),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(failure.title, style: compact ? textTheme.titleMedium : textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(failure.message, style: textTheme.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null && failure.isRetryable) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado vacío amable, con acción opcional.
class CuteEmptyState extends StatelessWidget {
  const CuteEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bubble = compact ? 56.0 : 88.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: compact ? AppSpacing.md : AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: bubble + 16,
            height: bubble + 8,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: bubble,
                  height: bubble,
                  decoration: BoxDecoration(
                    color: AppColors.creamYellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.retroBrown, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: bubble * 0.46, color: AppColors.retroBrown),
                ),
                // Destellos decorativos.
                const Positioned(top: 0, right: 2, child: _Sparkle(size: 14, color: AppColors.pokeRed)),
                const Positioned(bottom: 4, left: 0, child: _Sparkle(size: 10, color: AppColors.pokeBlue)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: compact ? textTheme.titleMedium : textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted), textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(child: Icon(Icons.auto_awesome_rounded, size: size, color: color));
  }
}

/// Diálogo de confirmación para acciones destructivas.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmLabel)),
      ],
    ),
  );
  return result ?? false;
}

/// Mensaje breve de confirmación visual.
void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
