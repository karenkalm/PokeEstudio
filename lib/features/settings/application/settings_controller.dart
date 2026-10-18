import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';

/// Qué imagen usan las tarjetas de la Pokédex.
enum CardArtStyle {
  pixel('Pixel art'),
  artwork('Ilustración');

  const CardArtStyle(this.label);
  final String label;
}

/// Preferencias sencillas del usuario (no requieren cuenta).
class AppSettings {
  const AppSettings({
    this.trainerName = '',
    this.reduceMotion = false,
    this.cardArtStyle = CardArtStyle.pixel,
  });

  /// Nombre para el saludo; vacío = "entrenador".
  final String trainerName;

  /// Además de la preferencia del sistema, el usuario puede pedir menos movimiento.
  final bool reduceMotion;
  final CardArtStyle cardArtStyle;

  String get greetingName => trainerName.trim().isEmpty ? 'entrenador' : trainerName.trim();

  AppSettings copyWith({String? trainerName, bool? reduceMotion, CardArtStyle? cardArtStyle}) {
    return AppSettings(
      trainerName: trainerName ?? this.trainerName,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      cardArtStyle: cardArtStyle ?? this.cardArtStyle,
    );
  }
}

class SettingsController extends Notifier<AppSettings> {
  static const String _nameKey = 'settings.trainerName';
  static const String _reduceMotionKey = 'settings.reduceMotion';
  static const String _cardStyleKey = 'settings.cardArtStyle';

  /// Longitud máxima del nombre de entrenador.
  static const int maxNameLength = 20;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final styleName = prefs.getString(_cardStyleKey);
    return AppSettings(
      trainerName: prefs.getString(_nameKey) ?? '',
      reduceMotion: prefs.getBool(_reduceMotionKey) ?? false,
      cardArtStyle: CardArtStyle.values.firstWhere(
        (style) => style.name == styleName,
        orElse: () => CardArtStyle.pixel,
      ),
    );
  }

  Future<void> setTrainerName(String name) async {
    var clean = name.trim();
    if (clean.length > maxNameLength) clean = clean.substring(0, maxNameLength);
    state = state.copyWith(trainerName: clean);
    await _prefs.setString(_nameKey, clean);
  }

  Future<void> setReduceMotion(bool value) async {
    state = state.copyWith(reduceMotion: value);
    await _prefs.setBool(_reduceMotionKey, value);
  }

  Future<void> setCardArtStyle(CardArtStyle style) async {
    state = state.copyWith(cardArtStyle: style);
    await _prefs.setString(_cardStyleKey, style.name);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
  name: 'settingsProvider',
);
