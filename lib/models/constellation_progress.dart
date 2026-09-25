import 'day_content.dart';

/// Progreso de una de las cuatro constelaciones.
class ConstellationProgress {
  const ConstellationProgress({
    required this.info,
    required this.completedDays,
  });

  final ConstellationInfo info;
  final List<int> completedDays;

  int get total => info.length;

  int get completedCount => completedDays.length;

  bool get isComplete => completedCount >= total;

  double get fraction => total == 0 ? 0.0 : completedCount / total;
}
