import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/daily_progress.dart';
import '../theme/app_theme.dart';

/// Formas originales de las cuatro constelaciones en coordenadas relativas.
const List<List<Offset>> _shapes = <List<Offset>>[
  // Origen (días 1–7)
  <Offset>[
    Offset(0.10, 0.72),
    Offset(0.30, 0.60),
    Offset(0.46, 0.68),
    Offset(0.60, 0.50),
    Offset(0.82, 0.56),
    Offset(0.86, 0.30),
    Offset(0.62, 0.22),
  ],
  // Fortaleza (días 8–14)
  <Offset>[
    Offset(0.18, 0.22),
    Offset(0.50, 0.10),
    Offset(0.82, 0.22),
    Offset(0.76, 0.56),
    Offset(0.50, 0.82),
    Offset(0.24, 0.56),
    Offset(0.50, 0.44),
  ],
  // Acción (días 15–21)
  <Offset>[
    Offset(0.10, 0.82),
    Offset(0.28, 0.66),
    Offset(0.46, 0.52),
    Offset(0.64, 0.38),
    Offset(0.86, 0.20),
    Offset(0.66, 0.14),
    Offset(0.84, 0.42),
  ],
  // Legado (días 22–30)
  <Offset>[
    Offset(0.50, 0.90),
    Offset(0.50, 0.66),
    Offset(0.28, 0.50),
    Offset(0.72, 0.50),
    Offset(0.14, 0.28),
    Offset(0.38, 0.24),
    Offset(0.62, 0.24),
    Offset(0.86, 0.28),
    Offset(0.50, 0.06),
  ],
];

/// Primer día de cada constelación.
const List<int> _firstDays = <int>[1, 8, 15, 22];

const List<String> _names = <String>['Origen', 'Fortaleza', 'Acción', 'Legado'];

/// Posición de cada estrella para un tamaño dado.
Map<int, Offset> starPositions(Size size) {
  final result = <int, Offset>{};
  final halfW = size.width / 2;
  final halfH = size.height / 2;
  const pad = 0.12;
  for (var c = 0; c < _shapes.length; c++) {
    final col = c % 2;
    final row = c ~/ 2;
    final origin = Offset(col * halfW, row * halfH);
    for (var i = 0; i < _shapes[c].length; i++) {
      final p = _shapes[c][i];
      final x = origin.dx + halfW * (pad + p.dx * (1 - pad * 2));
      final y = origin.dy + halfH * (pad + 0.06 + p.dy * (1 - pad * 2 - 0.06));
      result[_firstDays[c] + i] = Offset(x, y);
    }
  }
  return result;
}

/// Mapa de 30 estrellas: apagadas (bloqueadas), disponibles o encendidas.
/// Las líneas de una constelación aparecen al completar su etapa.
class ConstellationMap extends StatefulWidget {
  const ConstellationMap({
    super.key,
    required this.statuses,
    this.currentDay,
    this.onStarTap,
    this.reduceMotion = false,
    this.revealConstellation,
    this.aspectRatio = 1.0,
  });

  /// Estado de cada día (1..30).
  final Map<int, DayStatus> statuses;
  final int? currentDay;
  final ValueChanged<int>? onStarTap;
  final bool reduceMotion;

  /// Índice (0..3) de una constelación cuyas líneas se dibujan animadas.
  final int? revealConstellation;
  final double aspectRatio;

  @override
  State<ConstellationMap> createState() => _ConstellationMapState();
}

class _ConstellationMapState extends State<ConstellationMap>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _reveal;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
      value:
          widget.revealConstellation == null || widget.reduceMotion ? 1.0 : 0.0,
    );
    if (!widget.reduceMotion) {
      _pulse.repeat(reverse: true);
      if (widget.revealConstellation != null) {
        _reveal.forward();
      }
    }
  }

  @override
  void didUpdateWidget(covariant ConstellationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && _pulse.isAnimating) {
      _pulse.stop();
    } else if (!widget.reduceMotion && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, Size size) {
    final onTap = widget.onStarTap;
    if (onTap == null) {
      return;
    }
    final positions = starPositions(size);
    int? nearest;
    var best = double.infinity;
    for (final entry in positions.entries) {
      final d = (entry.value - details.localPosition).distance;
      if (d < best) {
        best = d;
        nearest = entry.key;
      }
    }
    if (nearest != null && best <= 28) {
      onTap(nearest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed =
        widget.statuses.values.where((s) => s == DayStatus.completed).length;
    final theme = Theme.of(context);
    return Semantics(
      label: 'Mapa de constelaciones: $completed de 30 estrellas encendidas',
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final paint = CustomPaint(
              size: size,
              painter: _ConstellationPainter(
                statuses: widget.statuses,
                currentDay: widget.currentDay,
                pulse: _pulse,
                reveal: _reveal,
                revealIndex: widget.revealConstellation,
                dark: theme.brightness == Brightness.dark,
                ink: theme.colorScheme.onSurface,
                primary: theme.colorScheme.primary,
                textStyle: theme.textTheme.labelMedium ?? const TextStyle(),
              ),
            );
            if (widget.onStarTap == null) {
              return paint;
            }
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _handleTap(d, size),
              child: paint,
            );
          },
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({
    required this.statuses,
    required this.currentDay,
    required this.pulse,
    required this.reveal,
    required this.revealIndex,
    required this.dark,
    required this.ink,
    required this.primary,
    required this.textStyle,
  }) : super(repaint: Listenable.merge(<Listenable>[pulse, reveal]));

  final Map<int, DayStatus> statuses;
  final int? currentDay;
  final Animation<double> pulse;
  final Animation<double> reveal;
  final int? revealIndex;
  final bool dark;
  final Color ink;
  final Color primary;
  final TextStyle textStyle;

  bool _complete(int index) {
    final first = _firstDays[index];
    final count = _shapes[index].length;
    for (var d = first; d < first + count; d++) {
      if (statuses[d] != DayStatus.completed) {
        return false;
      }
    }
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final positions = starPositions(size);
    final starColor = dark ? AppColors.star : const Color(0xFFD08A1E);
    final lit = dark ? AppColors.starSoft : const Color(0xFFB7700F);

    // Nombres de constelaciones.
    for (var c = 0; c < _names.length; c++) {
      final complete = _complete(c);
      final painter = TextPainter(
        text: TextSpan(
          text: complete ? '${_names[c]} ✦' : _names[c],
          style: textStyle.copyWith(
            color:
                complete ? starColor : ink.withValues(alpha: dark ? 0.55 : 0.6),
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width / 2);
      final origin =
          Offset((c % 2) * size.width / 2, (c ~/ 2) * size.height / 2);
      painter.paint(canvas, origin + const Offset(10, 6));
      painter.dispose();
    }

    // Líneas de constelaciones completas.
    for (var c = 0; c < _shapes.length; c++) {
      if (!_complete(c)) {
        continue;
      }
      final progress = c == revealIndex ? reveal.value : 1.0;
      final linePaint = Paint()
        ..color = starColor.withValues(alpha: 0.55)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      final first = _firstDays[c];
      final segments = _shapes[c].length - 1;
      final drawn = progress * segments;
      for (var i = 0; i < segments; i++) {
        if (drawn <= i) {
          break;
        }
        final a = positions[first + i]!;
        final b = positions[first + i + 1]!;
        final f = math.min(1.0, drawn - i);
        canvas.drawLine(a, Offset.lerp(a, b, f)!, linePaint);
      }
    }

    // Estrellas.
    final glowPaint = Paint();
    final corePaint = Paint();
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final entry in positions.entries) {
      final day = entry.key;
      final p = entry.value;
      final status = statuses[day] ?? DayStatus.locked;
      switch (status) {
        case DayStatus.completed:
          glowPaint
            ..color = starColor.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.drawCircle(p, 9, glowPaint);
          corePaint.color = lit;
          _drawStar(canvas, p, 6.5, corePaint);
        case DayStatus.available:
        case DayStatus.inProgress:
          final isCurrent = day == currentDay;
          final pulseValue = isCurrent ? pulse.value : 0.0;
          ringPaint.color = primary.withValues(alpha: 0.5 + 0.4 * pulseValue);
          canvas.drawCircle(p, 7 + 3 * pulseValue, ringPaint);
          corePaint.color = primary.withValues(alpha: 0.85);
          canvas.drawCircle(p, 3.2, corePaint);
        case DayStatus.locked:
          corePaint.color = ink.withValues(alpha: dark ? 0.22 : 0.25);
          canvas.drawCircle(p, 2.4, corePaint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final point = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return oldDelegate.statuses != statuses ||
        oldDelegate.currentDay != currentDay ||
        oldDelegate.dark != dark ||
        oldDelegate.revealIndex != revealIndex;
  }
}
