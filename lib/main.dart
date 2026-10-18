import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/cache/json_cache.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();

  final preferences = await SharedPreferences.getInstance();
  final supportDir = await getApplicationSupportDirectory();
  final cache = JsonCache(directory: Directory('${supportDir.path}${Platform.pathSeparator}pokeapi_cache'));

  runApp(
    ProviderScope(
      // Los reintentos viven en la capa HTTP (PokeApiClient), con criterio:
      // no se reintenta un 404 ni un JSON mal formado. Se desactiva el
      // reintento automático de Riverpod para no multiplicar peticiones.
      retry: (retryCount, error) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        jsonCacheProvider.overrideWithValue(cache),
      ],
      child: const PokeStudioApp(),
    ),
  );
}

/// Las fuentes OFL empaquetadas aparecen en Ajustes → Licencias.
void _registerFontLicenses() {
  const fonts = <String, String>{
    'Fredoka': 'assets/fonts/fredoka/OFL.txt',
    'Nunito': 'assets/fonts/nunito/OFL.txt',
    'Press Start 2P': 'assets/fonts/press_start_2p/OFL.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final font in fonts.entries) {
      final text = await rootBundle.loadString(font.value);
      yield LicenseEntryWithLineBreaks(<String>[font.key], text);
    }
  });
}
