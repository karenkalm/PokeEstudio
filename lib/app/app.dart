import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_controller.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Permite arrastrar listas y carruseles también con el mouse y el touchpad
/// (por defecto Flutter solo lo permite con el dedo), y muestra barras de
/// desplazamiento en computadora.
class _PokeStudioScrollBehavior extends MaterialScrollBehavior {
  const _PokeStudioScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}

/// Raíz de la interfaz.
class PokeStudioApp extends ConsumerWidget {
  const PokeStudioApp({super.key});

  static final ThemeData _theme = AppTheme.light();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final reduceMotion = ref.watch(settingsProvider.select((s) => s.reduceMotion));

    return MaterialApp.router(
      title: 'PokéStudio',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      routerConfig: router,
      scrollBehavior: const _PokeStudioScrollBehavior(),
      locale: const Locale('es'),
      supportedLocales: const <Locale>[Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!reduceMotion) return content;
        // "Reducir movimiento" propio: se suma a la preferencia del sistema y
        // todos los widgets lo leen con MediaQuery.disableAnimationsOf.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: content,
        );
      },
    );
  }
}
