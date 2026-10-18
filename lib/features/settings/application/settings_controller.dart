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
    this.soundEnabled = true,
    this.soundVolume = 0.6,
  });

  /// Nombre para el saludo; vacío = "entrenador".
  final String trainerName;

  /// Además de la preferencia del sistema, el usuario puede pedir menos movimiento.
  final bool reduceMotion;
  final CardArtStyle cardArtStyle;

  /// Efectos de sonido de la interfaz.
  final bool soundEnabled;

  /// Volumen de los efectos, de 0 a 1.
  final double soundVolume;

  String get greetingName => trainerName.trim().isEmpty ? 'entrenador' : trainerName.trim();

  AppSettings copyWith({
    String? trainerName,
    bool? reduceMotion,
    CardArtStyle? cardArtStyle,
    bool? soundEnabled,
    double? soundVolume,
  }) {
    return AppSettings(
      trainerName: trainerName ?? this.trainerName,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      cardArtStyle: cardArtStyle ?? this.cardArtStyle,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
    );
  }
}

class SettingsController extends Notifier<AppSettings> {
  static const String _nameKey = 'settings.trainerName';
  static const String _reduceMotionKey = 'settings.reduceMotion';
  static const String _cardStyleKey = 'settings.cardArtStyle';
  static const String _soundEnabledKey = 'settings.soundEnabled';
  static const String _soundVolumeKey = 'settings.soundVolume';

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
      soundEnabled: prefs.getBool(_soundEnabledKey) ?? true,
      soundVolume: (prefs.getDouble(_soundVolumeKey) ?? 0.6).clamp(0.0, 1.0),
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

  Future<void> setSoundEnabled(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await _prefs.setBool(_soundEnabledKey, value);
  }

  Future<void> setSoundVolume(double value) async {
    final clean = value.clamp(0.0, 1.0);
    state = state.copyWith(soundVolume: clean);
    await _prefs.setDouble(_soundVolumeKey, clean);
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
