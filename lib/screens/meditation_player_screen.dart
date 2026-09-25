import 'dart:async';

import 'package:flutter/material.dart';

import '../data/meditation_scripts.dart';
import '../models/meditation_session.dart';
import '../services/app_controller.dart';
import '../widgets/app_scope.dart';
import '../widgets/breathing_circle.dart';
import '../widgets/common.dart';
import '../widgets/sky_background.dart';

/// Sonido que acompaña una meditación.
enum Accompaniment {
  none('Silencio'),
  music('Música'),
  ambient('Ambiente');

  const Accompaniment(this.label);

  final String label;
}

/// Sesión de meditación con temporizador, animación de respiración,
/// indicaciones de texto y sonido opcional.
class MeditationPlayerScreen extends StatefulWidget {
  const MeditationPlayerScreen({
    super.key,
    required this.type,
    required this.minutes,
    this.fromDay,
    this.accompaniment = Accompaniment.none,
  });

  final MeditationType type;
  final int minutes;
  final int? fromDay;
  final Accompaniment accompaniment;

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen> {
  Timer? _timer;
  int _elapsed = 0;
  bool _running = false;
  bool _finished = false;
  bool _startedSound = false;
  late final AppController _app;
  bool _initialized = false;

  int get _total => widget.minutes * 60;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _app = AppScope.read(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_startedSound) {
      _stopSound();
    }
    super.dispose();
  }

  Future<void> _startSound() async {
    switch (widget.accompaniment) {
      case Accompaniment.none:
        return;
      case Accompaniment.music:
        _startedSound = await _app.audio.playMusic();
      case Accompaniment.ambient:
        _startedSound = await _app.audio.playAmbient();
    }
  }

  void _stopSound() {
    switch (widget.accompaniment) {
      case Accompaniment.none:
        return;
      case Accompaniment.music:
        _app.audio.stopMusic();
      case Accompaniment.ambient:
        _app.audio.stopAmbient();
    }
    _startedSound = false;
  }

  void _pauseSound() {
    if (widget.accompaniment == Accompaniment.music) {
      _app.audio.pauseMusic();
    } else if (widget.accompaniment == Accompaniment.ambient) {
      _app.audio.pauseAmbient();
    }
  }

  void _resumeSound() {
    if (widget.accompaniment == Accompaniment.music) {
      _app.audio.resumeMusic();
    } else if (widget.accompaniment == Accompaniment.ambient) {
      _app.audio.resumeAmbient();
    }
  }

  void _start() {
    if (_finished) {
      return;
    }
    if (_elapsed == 0 && !_startedSound) {
      _startSound();
    } else {
      _resumeSound();
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _elapsed++);
      if (_elapsed >= _total) {
        t.cancel();
        _complete();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    _pauseSound();
    setState(() => _running = false);
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    _stopSound();
    setState(() {
      _running = false;
      _elapsed = 0;
    });
    showMessage(
      context,
      'Sesión detenida. Solo se guardan las sesiones completas.',
    );
  }

  Future<void> _complete() async {
    _timer = null;
    _stopSound();
    setState(() {
      _running = false;
      _finished = true;
    });
    final achievement = await _app.recordMeditation(
      type: widget.type,
      minutes: widget.minutes,
      secondsPracticed: _elapsed,
      fromDay: widget.fromDay,
    );
    if (!mounted) {
      return;
    }
    if (achievement != null) {
      showMessage(context, 'Nueva insignia: ${achievement.title}');
    }
  }

  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final guides = meditationGuides[widget.type] ?? const <String>[];
    final interval = guides.isEmpty ? 1 : (_total / guides.length).ceil();
    final guideIndex = guides.isEmpty
        ? 0
        : (_elapsed ~/ interval).clamp(0, guides.length - 1).toInt();
    final remaining = (_total - _elapsed).clamp(0, _total).toInt();

    return Scaffold(
      appBar: AppBar(title: Text(widget.type.label)),
      extendBodyBehindAppBar: true,
      body: SkyBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: <Widget>[
                Text(
                  '${widget.minutes} min · ${widget.accompaniment.label}',
                  style: theme.textTheme.labelLarge,
                ),
                const Spacer(),
                if (_finished) ...<Widget>[
                  Icon(Icons.spa, size: 64, color: theme.colorScheme.secondary),
                  const SizedBox(height: 16),
                  Text(
                    'Sesión completada',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gracias por regalarte este tiempo.',
                    textAlign: TextAlign.center,
                  ),
                ] else ...<Widget>[
                  BreathingCircle(
                    running: _running,
                    pattern: patternFor(widget.type),
                    reduceMotion: app.settings.reduceMotion,
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: 'Tiempo restante ${_format(remaining)}',
                    excludeSemantics: true,
                    child: Text(
                      _format(remaining),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 72,
                    child: AnimatedSwitcher(
                      duration: app.settings.reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 700),
                      child: Text(
                        guides.isEmpty ? '' : guides[guideIndex],
                        key: ValueKey<int>(guideIndex),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (_finished)
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Volver'),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FilledButton.icon(
                        key: const ValueKey<String>('player-toggle'),
                        onPressed: _running ? _pause : _start,
                        icon: Icon(
                          _running
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          _running
                              ? 'Pausar'
                              : (_elapsed == 0 ? 'Comenzar' : 'Reanudar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _elapsed == 0 && !_running ? null : _stop,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Detener'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
