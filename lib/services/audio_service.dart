import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/sound_catalog.dart';
import '../models/app_settings.dart';

/// Canales de reproducción en bucle. Solo existe un reproductor por canal,
/// así nunca se acumulan reproducciones simultáneas descontroladas.
enum AudioChannel { music, ambient }

/// Abstracción del motor de audio, para poder probar sin plugins nativos.
abstract class AudioBackend {
  Future<void> playLoop(AudioChannel channel, String asset, double volume);

  Future<void> setVolume(AudioChannel channel, double volume);

  Future<void> pause(AudioChannel channel);

  Future<void> resume(AudioChannel channel);

  Future<void> stop(AudioChannel channel);

  Future<void> playEffect(String asset, double volume);

  Future<void> dispose();
}

/// Implementación real con audioplayers y assets locales (sin Internet).
class AudioplayersBackend implements AudioBackend {
  final Map<AudioChannel, AudioPlayer> _loops = <AudioChannel, AudioPlayer>{};
  final List<AudioPlayer> _effects = <AudioPlayer>[];
  int _nextEffect = 0;

  static const int _effectPoolSize = 2;

  /// Sin foco de audio exclusivo: música, ambiente y efectos pueden sonar
  /// juntos sin pausarse entre sí.
  AudioContext get _context => AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
        ),
      );

  Future<AudioPlayer> _loopPlayer(AudioChannel channel) async {
    final existing = _loops[channel];
    if (existing != null) {
      return existing;
    }
    final player = AudioPlayer(playerId: 'rye_${channel.name}');
    await player.setAudioContext(_context);
    await player.setReleaseMode(ReleaseMode.loop);
    _loops[channel] = player;
    return player;
  }

  Future<AudioPlayer> _effectPlayer() async {
    if (_effects.length < _effectPoolSize) {
      final player = AudioPlayer();
      await player.setAudioContext(_context);
      await player.setReleaseMode(ReleaseMode.stop);
      _effects.add(player);
      return player;
    }
    final player = _effects[_nextEffect % _effects.length];
    _nextEffect++;
    return player;
  }

  @override
  Future<void> playLoop(
      AudioChannel channel, String asset, double volume) async {
    final player = await _loopPlayer(channel);
    await player.stop();
    await player.play(AssetSource(asset), volume: volume);
  }

  @override
  Future<void> setVolume(AudioChannel channel, double volume) async {
    await _loops[channel]?.setVolume(volume);
  }

  @override
  Future<void> pause(AudioChannel channel) async {
    await _loops[channel]?.pause();
  }

  @override
  Future<void> resume(AudioChannel channel) async {
    await _loops[channel]?.resume();
  }

  @override
  Future<void> stop(AudioChannel channel) async {
    await _loops[channel]?.stop();
  }

  @override
  Future<void> playEffect(String asset, double volume) async {
    final player = await _effectPlayer();
    await player.stop();
    await player.play(AssetSource(asset), volume: volume);
  }

  @override
  Future<void> dispose() async {
    for (final p in _loops.values) {
      await p.dispose();
    }
    for (final p in _effects) {
      await p.dispose();
    }
    _loops.clear();
    _effects.clear();
  }
}

/// Motor silencioso: registra las llamadas. Se usa en pruebas.
class SilentAudioBackend implements AudioBackend {
  final List<String> calls = <String>[];

  @override
  Future<void> playLoop(
      AudioChannel channel, String asset, double volume) async {
    calls.add('loop:${channel.name}:$asset');
  }

  @override
  Future<void> setVolume(AudioChannel channel, double volume) async {
    calls.add('volume:${channel.name}:${volume.toStringAsFixed(2)}');
  }

  @override
  Future<void> pause(AudioChannel channel) async {
    calls.add('pause:${channel.name}');
  }

  @override
  Future<void> resume(AudioChannel channel) async {
    calls.add('resume:${channel.name}');
  }

  @override
  Future<void> stop(AudioChannel channel) async {
    calls.add('stop:${channel.name}');
  }

  @override
  Future<void> playEffect(String asset, double volume) async {
    calls.add('effect:$asset');
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
  }
}

/// Controla música, sonidos ambientales y efectos respetando los ajustes.
///
/// La voz guiada no se incluye en esta versión, por eso no existe un canal
/// ni un control para ella.
class AudioService extends ChangeNotifier {
  AudioService(this._backend, {AppSettings settings = const AppSettings()})
      : _settings = settings;

  final AudioBackend _backend;
  AppSettings _settings;

  bool _musicPlaying = false;
  bool _musicPaused = false;
  String? _musicId;

  bool _ambientPlaying = false;
  bool _ambientPaused = false;
  String? _ambientId;

  bool _pausedByLifecycle = false;
  DateTime _lastEffectAt = DateTime.fromMillisecondsSinceEpoch(0);
  SoundEffect? _lastEffect;
  bool _disposed = false;

  AppSettings get settings => _settings;

  bool get isMusicPlaying => _musicPlaying && !_musicPaused;

  bool get isAmbientPlaying => _ambientPlaying && !_ambientPaused;

  bool get isAmbientPaused => _ambientPlaying && _ambientPaused;

  String? get currentAmbientId => _ambientPlaying ? _ambientId : null;

  String? get currentMusicId => _musicPlaying ? _musicId : null;

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Audio no disponible: $e');
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Aplica ajustes nuevos. Si un canal se desactiva, se detiene de inmediato.
  Future<void> updateSettings(AppSettings next) async {
    final previous = _settings;
    _settings = next;

    if (_musicPlaying) {
      if (!next.musicEnabled) {
        await stopMusic();
      } else if (next.musicTrack != _musicId) {
        await playMusic(next.musicTrack);
      } else if (next.musicVolume != previous.musicVolume) {
        await _safe(
            () => _backend.setVolume(AudioChannel.music, next.musicVolume));
      }
    }

    if (_ambientPlaying) {
      if (!next.ambientEnabled) {
        await stopAmbient();
      } else if (next.ambientVolume != previous.ambientVolume) {
        await _safe(
          () => _backend.setVolume(AudioChannel.ambient, next.ambientVolume),
        );
      }
    }
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Música
  // ---------------------------------------------------------------------------

  /// Reproduce la música en bucle. Devuelve false si está desactivada.
  Future<bool> playMusic([String? trackId]) async {
    if (!_settings.musicEnabled) {
      return false;
    }
    final track = musicById(trackId ?? _settings.musicTrack);
    await _safe(
      () => _backend.playLoop(
        AudioChannel.music,
        track.asset,
        _settings.musicVolume,
      ),
    );
    _musicPlaying = true;
    _musicPaused = false;
    _musicId = track.id;
    _notify();
    return true;
  }

  Future<void> pauseMusic() async {
    if (!_musicPlaying || _musicPaused) {
      return;
    }
    await _safe(() => _backend.pause(AudioChannel.music));
    _musicPaused = true;
    _notify();
  }

  Future<void> resumeMusic() async {
    if (!_musicPlaying || !_musicPaused || !_settings.musicEnabled) {
      return;
    }
    await _safe(() => _backend.resume(AudioChannel.music));
    _musicPaused = false;
    _notify();
  }

  Future<void> stopMusic() async {
    if (!_musicPlaying) {
      return;
    }
    await _safe(() => _backend.stop(AudioChannel.music));
    _musicPlaying = false;
    _musicPaused = false;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Sonidos ambientales
  // ---------------------------------------------------------------------------

  /// Reproduce un sonido ambiental en bucle. Devuelve false si está
  /// desactivado en Ajustes.
  Future<bool> playAmbient([String? soundId]) async {
    if (!_settings.ambientEnabled) {
      return false;
    }
    final sound = ambientById(soundId ?? _settings.ambientSound);
    await _safe(
      () => _backend.playLoop(
        AudioChannel.ambient,
        sound.asset,
        _settings.ambientVolume,
      ),
    );
    _ambientPlaying = true;
    _ambientPaused = false;
    _ambientId = sound.id;
    _notify();
    return true;
  }

  Future<void> pauseAmbient() async {
    if (!_ambientPlaying || _ambientPaused) {
      return;
    }
    await _safe(() => _backend.pause(AudioChannel.ambient));
    _ambientPaused = true;
    _notify();
  }

  Future<void> resumeAmbient() async {
    if (!_ambientPlaying || !_ambientPaused || !_settings.ambientEnabled) {
      return;
    }
    await _safe(() => _backend.resume(AudioChannel.ambient));
    _ambientPaused = false;
    _notify();
  }

  Future<void> stopAmbient() async {
    if (!_ambientPlaying) {
      return;
    }
    await _safe(() => _backend.stop(AudioChannel.ambient));
    _ambientPlaying = false;
    _ambientPaused = false;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Efectos
  // ---------------------------------------------------------------------------

  /// Reproduce un efecto breve si los efectos están activados.
  /// Ignora repeticiones del mismo efecto en menos de 300 ms.
  Future<bool> playEffect(SoundEffect effect) async {
    if (!_settings.effectsEnabled) {
      return false;
    }
    final now = DateTime.now();
    if (_lastEffect == effect &&
        now.difference(_lastEffectAt) < const Duration(milliseconds: 300)) {
      return false;
    }
    _lastEffect = effect;
    _lastEffectAt = now;
    await _safe(
        () => _backend.playEffect(effect.asset, _settings.effectsVolume));
    return true;
  }

  // ---------------------------------------------------------------------------
  // Ciclo de vida
  // ---------------------------------------------------------------------------

  Future<void> stopAll() async {
    await stopMusic();
    await stopAmbient();
  }

  /// Pausa lo que suena cuando la app pasa a segundo plano.
  Future<void> onAppPaused() async {
    if (isMusicPlaying || isAmbientPlaying) {
      _pausedByLifecycle = true;
      await pauseMusic();
      await pauseAmbient();
    }
  }

  /// Reanuda solo lo que se pausó automáticamente.
  Future<void> onAppResumed() async {
    if (!_pausedByLifecycle) {
      return;
    }
    _pausedByLifecycle = false;
    await resumeMusic();
    await resumeAmbient();
  }

  @override
  void dispose() {
    _disposed = true;
    _backend.dispose();
    super.dispose();
  }
}
