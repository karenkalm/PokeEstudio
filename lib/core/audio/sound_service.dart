import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/settings_controller.dart';

/// Efectos de sonido retro de la interfaz (archivos en `assets/sounds/`,
/// sintetizados con `tool/generate_sounds.py`; son originales).
enum SoundEffect {
  /// Toque ligero en botones.
  tap('tap'),

  /// Cambio de pestaña o sección.
  select('select'),

  /// Abrir una ficha o entrar a una sección.
  open('open'),

  /// Volver o cerrar.
  back('back'),

  /// Flechas ◀ ▶.
  arrow('arrow'),

  /// Activar o desactivar una opción.
  toggle('toggle'),

  /// Acción completada (aplicar filtros, guardar).
  success('success'),

  /// Algo salió mal.
  error('error');

  const SoundEffect(this.fileName);
  final String fileName;

  /// Ruta relativa a `assets/`, como la espera `AssetSource`.
  String get assetPath => 'sounds/$fileName.wav';
}

/// Reproduce efectos de interfaz. Nunca es el único medio de comunicar algo:
/// siempre acompaña a un cambio visual.
abstract class SoundService {
  void play(SoundEffect effect);
  Future<void> dispose();
}

/// Implementación sin sonido (pruebas o cuando el sistema no tiene audio).
class SilentSoundService implements SoundService {
  const SilentSoundService();

  @override
  void play(SoundEffect effect) {}

  @override
  Future<void> dispose() async {}
}

/// Implementación con `audioplayers`. Usa dos reproductores por efecto en
/// modo de baja latencia para que toques rápidos no se corten entre sí.
class AudioplayersSoundService implements SoundService {
  AudioplayersSoundService({required this.isEnabled, required this.volume});

  final bool Function() isEnabled;
  final double Function() volume;

  static const int _playersPerEffect = 2;
  static const Duration _minGap = Duration(milliseconds: 45);

  final Map<SoundEffect, List<AudioPlayer>> _players = <SoundEffect, List<AudioPlayer>>{};
  final Map<SoundEffect, int> _next = <SoundEffect, int>{};
  final Map<SoundEffect, DateTime> _lastPlayed = <SoundEffect, DateTime>{};
  bool _disposed = false;

  @override
  void play(SoundEffect effect) {
    if (_disposed || !isEnabled()) return;
    final now = DateTime.now();
    final last = _lastPlayed[effect];
    if (last != null && now.difference(last) < _minGap) return; // evita ráfagas
    _lastPlayed[effect] = now;
    unawaited(_play(effect));
  }

  Future<void> _play(SoundEffect effect) async {
    try {
      final pool = _players.putIfAbsent(
        effect,
        () => List<AudioPlayer>.generate(_playersPerEffect, (_) => AudioPlayer()),
      );
      final index = (_next[effect] ?? 0) % pool.length;
      _next[effect] = index + 1;
      final player = pool[index];
      await player.stop();
      await player.play(
        AssetSource(effect.assetPath),
        volume: volume().clamp(0.0, 1.0),
        mode: PlayerMode.lowLatency,
      );
    } on Object catch (error) {
      // El sonido es un adorno: si el dispositivo no puede reproducirlo, la
      // app sigue igual.
      debugPrint('PokéStudio: no se pudo reproducir ${effect.fileName} ($error)');
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final pool in _players.values) {
      for (final player in pool) {
        await player.dispose();
      }
    }
    _players.clear();
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = AudioplayersSoundService(
    isEnabled: () => ref.read(settingsProvider).soundEnabled,
    volume: () => ref.read(settingsProvider).soundVolume,
  );
  ref.onDispose(service.dispose);
  return service;
}, name: 'soundServiceProvider');

/// Atajo para reproducir un efecto desde cualquier widget.
void playSound(BuildContext context, SoundEffect effect) {
  ProviderScope.containerOf(context, listen: false).read(soundServiceProvider).play(effect);
}
