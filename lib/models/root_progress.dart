import 'day_content.dart';

/// Estado visual de una raíz.
enum RootState {
  locked('Bloqueada'),
  growing('Creciendo'),
  illuminated('Iluminada');

  const RootState(this.label);

  final String label;
}

/// Progreso calculado de una de las 7 raíces.
class RootProgress {
  const RootProgress({
    required this.info,
    required this.days,
    required this.completedDays,
    this.challengesCompleted = 0,
    this.dayTitles = const <int, String>{},
    this.challengeTitles = const <String>[],
  });

  final RootInfo info;

  /// Días del viaje asociados a esta raíz.
  final List<int> days;

  /// Días asociados que ya se completaron.
  final List<int> completedDays;
  final int challengesCompleted;
  final Map<int, String> dayTitles;
  final List<String> challengeTitles;

  double get fraction {
    if (days.isEmpty) {
      return 0.0;
    }
    return (completedDays.length / days.length).clamp(0.0, 1.0).toDouble();
  }

  int get percent => (fraction * 100).round();

  RootState get state {
    if (completedDays.isEmpty) {
      return RootState.locked;
    }
    if (completedDays.length >= days.length) {
      return RootState.illuminated;
    }
    return RootState.growing;
  }

  /// La reflexión se desbloquea al iluminar la raíz.
  bool get reflectionUnlocked => state == RootState.illuminated;
}
