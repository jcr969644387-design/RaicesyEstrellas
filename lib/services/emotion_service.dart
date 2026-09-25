import '../models/emotion_check_in.dart';
import '../utils/date_utils.dart';
import '../utils/validators.dart';
import 'storage_service.dart';

/// Punto diario de la tendencia semanal.
class DailyEmotionPoint {
  const DailyEmotionPoint({
    required this.date,
    required this.count,
    required this.averageIntensity,
  });

  final DateTime date;
  final int count;
  final double averageIntensity;

  bool get hasData => count > 0;
}

/// Registro local de check-ins emocionales. No realiza diagnósticos.
class EmotionService {
  EmotionService(this._storage, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    reload();
  }

  final StorageService _storage;
  final DateTime Function() _clock;
  final List<EmotionCheckIn> _records = <EmotionCheckIn>[];

  void reload() {
    _records
      ..clear()
      ..addAll(<EmotionCheckIn>[
        for (final item in _storage.readList(StorageKeys.emotions))
          EmotionCheckIn.fromJson(item),
      ]);
    _records.sort((a, b) => b.date.compareTo(a.date));
  }

  /// Registros del más reciente al más antiguo.
  List<EmotionCheckIn> get records =>
      List<EmotionCheckIn>.unmodifiable(_records);

  EmotionCheckIn? get latest => _records.isEmpty ? null : _records.first;

  /// Último check-in asociado a un día del viaje.
  EmotionCheckIn? forJourneyDay(int day) {
    for (final r in _records) {
      if (r.journeyDay == day) {
        return r;
      }
    }
    return null;
  }

  /// Guarda un check-in. Devuelve null si la intensidad no es válida.
  Future<EmotionCheckIn?> add({
    required Emotion emotion,
    required int intensity,
    String note = '',
    int? journeyDay,
  }) async {
    if (!EmotionCheckIn.isValidIntensity(intensity)) {
      return null;
    }
    final record = EmotionCheckIn(
      id: LocalId.next('e'),
      date: _clock(),
      emotion: emotion,
      intensity: intensity,
      note: Validators.clean(note),
      journeyDay: journeyDay,
    );
    _records.insert(0, record);
    await _save();
    return record;
  }

  Future<bool> delete(String id) async {
    final before = _records.length;
    _records.removeWhere((r) => r.id == id);
    if (before == _records.length) {
      return false;
    }
    await _save();
    return true;
  }

  Future<void> deleteAll() async {
    _records.clear();
    await _storage.remove(StorageKeys.emotions);
  }

  /// Promedio de intensidad de todos los registros (0 si no hay).
  double get averageIntensity {
    if (_records.isEmpty) {
      return 0;
    }
    final total = _records.fold<int>(0, (sum, r) => sum + r.intensity);
    return total / _records.length;
  }

  /// Número de registros por emoción, ordenado de mayor a menor.
  List<MapEntry<Emotion, int>> distribution() {
    final counts = <Emotion, int>{};
    for (final r in _records) {
      counts[r.emotion] = (counts[r.emotion] ?? 0) + 1;
    }
    final list = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  /// Tendencia de los últimos 7 días (del más antiguo al más reciente).
  List<DailyEmotionPoint> weeklyTrend([DateTime? now]) {
    final today = DateUtilsX.startOfDay(now ?? _clock());
    final points = <DailyEmotionPoint>[];
    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final key = DateUtilsX.dayKey(day);
      final sameDay =
          _records.where((r) => DateUtilsX.dayKey(r.date) == key).toList();
      final avg = sameDay.isEmpty
          ? 0.0
          : sameDay.fold<int>(0, (sum, r) => sum + r.intensity) /
              sameDay.length;
      points.add(
        DailyEmotionPoint(
          date: day,
          count: sameDay.length,
          averageIntensity: avg,
        ),
      );
    }
    return points;
  }

  Future<void> _save() async {
    await _storage.writeList(
      StorageKeys.emotions,
      <Map<String, dynamic>>[for (final r in _records) r.toJson()],
    );
  }
}
