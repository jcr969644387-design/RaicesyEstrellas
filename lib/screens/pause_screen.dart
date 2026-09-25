import 'dart:async';

import 'package:flutter/material.dart';

import '../data/meditation_scripts.dart';
import '../data/sound_catalog.dart';
import '../services/app_controller.dart';
import '../widgets/ambient_sound_panel.dart';
import '../widgets/app_scope.dart';
import '../widgets/breathing_circle.dart';
import '../widgets/common.dart';
import '../widgets/sky_background.dart';

/// PAUSA: un refugio con respiración guiada, temporizador de calma,
/// sonido ambiental opcional y frases breves de apoyo.
class PauseScreen extends StatefulWidget {
  const PauseScreen({super.key});

  @override
  State<PauseScreen> createState() => _PauseScreenState();
}

class _PauseScreenState extends State<PauseScreen> {
  static const List<int> _durations = <int>[1, 2, 5];

  Timer? _timer;
  int _minutes = 2;
  int _remaining = 120;
  bool _running = false;
  int _phrase = 0;
  late final AppController _app;
  bool _ambientBefore = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _app = AppScope.read(context);
      _ambientBefore = _app.audio.isAmbientPlaying;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_ambientBefore && _app.audio.isAmbientPlaying) {
      _app.audio.stopAmbient();
    }
    super.dispose();
  }

  void _start() {
    if (_remaining <= 0) {
      _remaining = _minutes * 60;
    }
    setState(() => _running = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _remaining--;
        if (_remaining % 10 == 0) {
          _phrase = (_phrase + 1) % pausePhrases.length;
        }
      });
      if (_remaining <= 0) {
        t.cancel();
        _finish();
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _running = false;
      _remaining = _minutes * 60;
    });
  }

  void _finish() {
    _timer = null;
    setState(() {
      _running = false;
      _remaining = _minutes * 60;
    });
    _app.playEffect(SoundEffect.bell);
    _app.vibrate();
    showMessage(context, 'Tu pausa terminó. Vuelve cuando quieras.');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pausa'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SkyBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: <Widget>[
              Text(
                'Este es tu refugio. Aquí no hay nada que lograr.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Center(
                child: BreathingCircle(
                  running: _running,
                  reduceMotion: app.settings.reduceMotion,
                  size: 220,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _format(_remaining),
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: AnimatedSwitcher(
                  duration: app.settings.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 600),
                  child: Text(
                    pausePhrases[_phrase],
                    key: ValueKey<int>(_phrase),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: SegmentedButton<int>(
                  segments: <ButtonSegment<int>>[
                    for (final m in _durations)
                      ButtonSegment<int>(value: m, label: Text('$m min')),
                  ],
                  selected: <int>{_minutes},
                  onSelectionChanged: _running
                      ? null
                      : (s) => setState(() {
                            _minutes = s.first;
                            _remaining = _minutes * 60;
                          }),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FilledButton.icon(
                    key: const ValueKey<String>('pause-start'),
                    onPressed: _running ? null : _start,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Comenzar'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    key: const ValueKey<String>('pause-stop'),
                    onPressed: _running ? _stop : null,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Detener'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionCard(child: AmbientSoundPanel()),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
