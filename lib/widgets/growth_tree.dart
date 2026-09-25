import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/root_progress.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

/// Fracción visible de una raíz según su progreso.
double _visible(RootProgress r) =>
    r.state == RootState.locked ? 0.18 : 0.35 + 0.65 * r.fraction;

/// Geometría compartida entre el dibujo y la detección de toques.
class _TreeGeometry {
  _TreeGeometry(this.size, this.roots);

  final Size size;
  final List<RootProgress> roots;

  double get groundY => size.height * 0.56;

  Offset get base => Offset(size.width / 2, groundY);

  double angleFor(int i) {
    final n = math.max(roots.length - 1, 1);
    final deg = 160 - (140 * i / n);
    return deg * math.pi / 180;
  }

  double lengthFor(int i) {
    final depth = size.height - groundY;
    return depth * 0.92 * _visible(roots[i]);
  }

  Offset endFor(int i) {
    final a = angleFor(i);
    final l = lengthFor(i);
    return base + Offset(math.cos(a) * l * 1.25, math.sin(a) * l);
  }

  Offset controlFor(int i) {
    final a = angleFor(i);
    final l = lengthFor(i);
    final mid = base + Offset(math.cos(a) * l * 0.55, math.sin(a) * l * 0.4);
    final side = i.isEven ? 1.0 : -1.0;
    return mid + Offset(-math.sin(a) * 10 * side, math.cos(a) * 10 * side);
  }
}

/// Árbol del crecimiento con sus 7 raíces. Tocar una raíz la selecciona.
class GrowthTree extends StatelessWidget {
  const GrowthTree({
    super.key,
    required this.stage,
    required this.growth,
    required this.roots,
    this.onRootTap,
    this.selectedRoot,
    this.height = 320,
  });

  final TreeStage stage;
  final double growth;
  final List<RootProgress> roots;
  final ValueChanged<int>? onRootTap;
  final int? selectedRoot;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final illuminated =
        roots.where((r) => r.state == RootState.illuminated).length;
    return Semantics(
      label: 'Árbol del crecimiento: ${stage.label}. '
          '$illuminated de ${roots.length} raíces iluminadas.',
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, height);
            final painter = CustomPaint(
              size: size,
              painter: _TreePainter(
                stage: stage,
                growth: growth,
                roots: roots,
                selected: selectedRoot,
                dark: theme.brightness == Brightness.dark,
                ink: theme.colorScheme.onSurface,
              ),
            );
            final onTap = onRootTap;
            if (onTap == null || roots.isEmpty) {
              return painter;
            }
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final geo = _TreeGeometry(size, roots);
                var best = double.infinity;
                var index = -1;
                for (var i = 0; i < roots.length; i++) {
                  final d = (geo.endFor(i) - details.localPosition).distance;
                  if (d < best) {
                    best = d;
                    index = i;
                  }
                }
                if (index >= 0 && best < 40) {
                  onTap(index);
                }
              },
              child: painter,
            );
          },
        ),
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter({
    required this.stage,
    required this.growth,
    required this.roots,
    required this.selected,
    required this.dark,
    required this.ink,
  });

  final TreeStage stage;
  final double growth;
  final List<RootProgress> roots;
  final int? selected;
  final bool dark;
  final Color ink;

  static const Color _trunk = Color(0xFF8A5A3B);
  static const Color _leafDark = Color(0xFF3E8E6A);

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _TreeGeometry(size, roots);
    _paintGround(canvas, size, geo);
    _paintRoots(canvas, geo);
    _paintPlant(canvas, size, geo);
  }

  void _paintGround(Canvas canvas, Size size, _TreeGeometry geo) {
    final rect = Rect.fromLTWH(0, geo.groundY, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? <Color>[const Color(0xFF2A2140), const Color(0xFF120E1F)]
            : <Color>[const Color(0xFFE8D9C4), const Color(0xFFD6C0A2)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(24),
        topRight: const Radius.circular(24),
      ),
      paint,
    );
    final line = Paint()
      ..color = (dark ? AppColors.leaf : const Color(0xFF6B8F5E))
          .withValues(alpha: 0.6)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.08, geo.groundY),
      Offset(size.width * 0.92, geo.groundY),
      line,
    );
  }

  void _paintRoots(Canvas canvas, _TreeGeometry geo) {
    for (var i = 0; i < roots.length; i++) {
      final r = roots[i];
      final end = geo.endFor(i);
      final control = geo.controlFor(i);
      final path = Path()
        ..moveTo(geo.base.dx, geo.base.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      final Color color;
      switch (r.state) {
        case RootState.locked:
          color = ink.withValues(alpha: 0.22);
        case RootState.growing:
          color = AppColors.root;
        case RootState.illuminated:
          color = AppColors.rootGlow;
      }
      if (r.state == RootState.illuminated || i == selected) {
        final glow = Paint()
          ..color = color.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawPath(path, glow);
      }
      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2 + 3 * r.fraction;
      canvas.drawPath(path, stroke);
      final dot = Paint()..color = color;
      canvas.drawCircle(end, i == selected ? 7.0 : 5.0, dot);
      if (i == selected) {
        final ring = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(end, 11, ring);
      }
    }
  }

  void _paintPlant(Canvas canvas, Size size, _TreeGeometry geo) {
    final base = geo.base;
    final leaf = Paint()..color = dark ? AppColors.leaf : _leafDark;
    final trunk = Paint()
      ..color = _trunk
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (stage) {
      case TreeStage.seed:
        final seed = Paint()..color = _trunk;
        canvas.drawOval(
          Rect.fromCenter(center: base.translate(0, -5), width: 18, height: 12),
          seed,
        );
        if (growth > 0) {
          final h = 10 + 60 * (growth / (7 / 30)).clamp(0.0, 1.0).toDouble();
          trunk.strokeWidth = 2.5;
          canvas.drawLine(base, base.translate(0, -h), trunk);
          _leafPair(canvas, base.translate(0, -h), 10, leaf);
        }
      case TreeStage.sprout:
        trunk.strokeWidth = 3.5;
        final top = base.translate(0, -size.height * 0.18);
        final path = Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(base.dx - 12, base.dy - 40, top.dx, top.dy);
        canvas.drawPath(path, trunk);
        _leafPair(canvas, top, 18, leaf);
        _leafPair(canvas, base.translate(-6, -size.height * 0.09), 12, leaf);
      case TreeStage.young:
        _tree(canvas, size, base, trunk, leaf,
            height: 0.30, width: 6, crown: 3);
      case TreeStage.growing:
        _tree(canvas, size, base, trunk, leaf,
            height: 0.40, width: 9, crown: 5);
      case TreeStage.full:
        _tree(canvas, size, base, trunk, leaf,
            height: 0.46, width: 12, crown: 7);
        _fruits(canvas, size, base);
    }
  }

  void _leafPair(Canvas canvas, Offset at, double s, Paint paint) {
    for (final dir in const <double>[-1.0, 1.0]) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(dir * 0.7);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(dir * s * 0.6, 0), width: s * 1.3, height: s * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  void _tree(
    Canvas canvas,
    Size size,
    Offset base,
    Paint trunk,
    Paint leaf, {
    required double height,
    required double width,
    required int crown,
  }) {
    final h = size.height * height;
    final top = base.translate(0, -h);
    trunk.strokeWidth = width;
    canvas.drawLine(base, top, trunk);

    // Ramas
    trunk.strokeWidth = width * 0.45;
    final branches = crown;
    final tips = <Offset>[top];
    for (var i = 0; i < branches; i++) {
      final t = 0.45 + 0.5 * (i / math.max(branches - 1, 1));
      final start = Offset.lerp(base, top, t)!;
      final dir = i.isEven ? -1.0 : 1.0;
      final len = h * (0.34 - 0.12 * t);
      final end = start.translate(dir * len, -len * 0.7);
      canvas.drawLine(start, end, trunk);
      tips.add(end);
    }

    // Copa
    final radius = size.width * 0.05 + crown * 4.0;
    final leafSoft = Paint()..color = leaf.color.withValues(alpha: 0.75);
    for (var i = 0; i < tips.length; i++) {
      final p = tips[i];
      canvas.drawCircle(p, radius * (i == 0 ? 1.15 : 0.85), leafSoft);
    }
    canvas.drawCircle(top.translate(0, -radius * 0.4), radius * 1.1, leaf);
  }

  void _fruits(Canvas canvas, Size size, Offset base) {
    final h = size.height * 0.46;
    final center = base.translate(0, -h);
    final glow = Paint()
      ..color = AppColors.star.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final core = Paint()..color = AppColors.starSoft;
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + (i - 3) * 0.45;
      final r = size.width * 0.12 + (i.isEven ? 10 : 22);
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r * 0.7 + 18);
      canvas.drawCircle(p, 6, glow);
      canvas.drawCircle(p, 2.6, core);
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) {
    return oldDelegate.stage != stage ||
        oldDelegate.growth != growth ||
        oldDelegate.roots != roots ||
        oldDelegate.selected != selected ||
        oldDelegate.dark != dark;
  }
}
