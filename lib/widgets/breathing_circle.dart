import 'package:flutter/material.dart';

import '../data/meditation_scripts.dart';
import '../theme/app_theme.dart';

/// Fase actual del ciclo de respiración.
enum BreathPhase {
  inhale('Inhala'),
  hold('Mantén'),
  exhale('Exhala');

  const BreathPhase(this.label);

  final String label;
}

/// Calcula la fase y la escala para un instante del ciclo (0..1).
({BreathPhase phase, double scale}) breathAt(
  double t,
  BreathingPattern pattern,
) {
  final total = pattern.cycleSeconds.toDouble();
  final s = t.clamp(0.0, 1.0).toDouble() * total;
  const minScale = 0.62;
  const maxScale = 1.0;
  if (s < pattern.inhale) {
    final p = Curves.easeInOut.transform(s / pattern.inhale);
    return (
      phase: BreathPhase.inhale,
      scale: minScale + (maxScale - minScale) * p
    );
  }
  if (s < pattern.inhale + pattern.hold) {
    return (phase: BreathPhase.hold, scale: maxScale);
  }
  final e = (s - pattern.inhale - pattern.hold) / pattern.exhale;
  final p = Curves.easeInOut.transform(e.clamp(0.0, 1.0).toDouble());
  return (
    phase: BreathPhase.exhale,
    scale: maxScale - (maxScale - minScale) * p
  );
}

/// Círculo que se expande y contrae lentamente: Inhala, Mantén, Exhala.
/// Con «reducir animaciones» el tamaño queda fijo y solo cambia el texto.
class BreathingCircle extends StatefulWidget {
  const BreathingCircle({
    super.key,
    required this.running,
    this.pattern = calmBreathing,
    this.reduceMotion = false,
    this.size = 240,
    this.onCycleComplete,
  });

  final bool running;
  final BreathingPattern pattern;
  final bool reduceMotion;
  final double size;
  final VoidCallback? onCycleComplete;

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _last = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.pattern.cycleSeconds),
    )..addListener(_onTick);
    if (widget.running) {
      _controller.repeat();
    }
  }

  void _onTick() {
    final v = _controller.value;
    if (v < _last) {
      widget.onCycleComplete?.call();
    }
    _last = v;
  }

  @override
  void didUpdateWidget(covariant BreathingCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pattern.cycleSeconds != widget.pattern.cycleSeconds) {
      _controller.duration = Duration(seconds: widget.pattern.cycleSeconds);
    }
    if (widget.running && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.running && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final glow = dark ? AppColors.star : theme.colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final state = breathAt(_controller.value, widget.pattern);
        final scale = widget.reduceMotion ? 0.85 : state.scale;
        final label = widget.running ? state.phase.label : 'En pausa';
        final d = widget.size * scale;
        return Semantics(
          liveRegion: true,
          label: 'Respiración: $label',
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: glow.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        glow.withValues(alpha: 0.55),
                        glow.withValues(alpha: 0.12),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: glow.withValues(alpha: 0.28),
                        blurRadius: 40 * scale,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
