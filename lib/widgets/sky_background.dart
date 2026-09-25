import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_scope.dart';

class _Star {
  const _Star(this.x, this.y, this.radius, this.phase);

  final double x;
  final double y;
  final double radius;
  final double phase;
}

/// Fondo de cielo con gradiente suave y estrellas que titilan con discreción.
/// En modo claro se convierte en un cielo de amanecer.
class SkyBackground extends StatefulWidget {
  const SkyBackground({super.key, required this.child, this.starCount = 60});

  final Widget child;
  final int starCount;

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final random = math.Random(1801);
    _stars = <_Star>[
      for (var i = 0; i < widget.starCount; i++)
        _Star(
          random.nextDouble(),
          random.nextDouble(),
          0.4 + random.nextDouble() * 1.3,
          random.nextDouble() * math.pi * 2,
        ),
    ];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduce = AppScope.of(context).settings.reduceMotion;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (reduce || !dark) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = dark
        ? const <Color>[AppColors.nightDeep, AppColors.night, Color(0xFF1A2152)]
        : const <Color>[Color(0xFFE9E6FA), AppColors.dawn, Color(0xFFFBEFDD)];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: CustomPaint(
        painter: _StarFieldPainter(
          stars: _stars,
          animation: _controller,
          color: dark ? AppColors.starSoft : AppColors.dawnPrimary,
          opacity: dark ? 0.8 : 0.18,
        ),
        child: widget.child,
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter({
    required this.stars,
    required this.animation,
    required this.color,
    required this.opacity,
  }) : super(repaint: animation);

  final List<_Star> stars;
  final Animation<double> animation;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * math.pi * 2;
    final paint = Paint();
    for (final s in stars) {
      final twinkle = 0.55 + 0.45 * math.sin(t + s.phase);
      paint.color = color.withValues(alpha: opacity * twinkle);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}
