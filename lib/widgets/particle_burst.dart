import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class _Particle {
  _Particle(math.Random r)
      : angle = r.nextDouble() * math.pi * 2,
        speed = 0.25 + r.nextDouble() * 0.75,
        size = 1.2 + r.nextDouble() * 2.6,
        hue = r.nextInt(3);

  final double angle;
  final double speed;
  final double size;
  final int hue;
}

/// Animación de partículas discreta para celebraciones.
/// No se muestra si el usuario pidió reducir animaciones.
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    this.enabled = true,
    this.count = 48,
    this.duration = const Duration(milliseconds: 2600),
  });

  final bool enabled;
  final int count;
  final Duration duration;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final r = math.Random(30);
    _particles = <_Particle>[
      for (var i = 0; i < widget.count; i++) _Particle(r),
    ];
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.enabled) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ParticlePainter(_particles, _controller),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles, this.animation) : super(repaint: animation);

  final List<_Particle> particles;
  final Animation<double> animation;

  static const List<Color> _colors = <Color>[
    AppColors.star,
    AppColors.starSoft,
    AppColors.lavender,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(animation.value);
    if (t <= 0 || t >= 1) {
      return;
    }
    final center = Offset(size.width / 2, size.height * 0.38);
    final maxR = math.min(size.width, size.height) * 0.55;
    final paint = Paint();
    for (final p in particles) {
      final d = maxR * p.speed * t;
      final pos = center + Offset(math.cos(p.angle) * d, math.sin(p.angle) * d);
      paint.color = _colors[p.hue].withValues(alpha: (1 - t) * 0.9);
      canvas.drawCircle(pos, p.size * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => false;
}
