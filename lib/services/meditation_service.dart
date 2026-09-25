import '../models/meditation_session.dart';
import '../utils/date_utils.dart';
import 'storage_service.dart';

/// Guarda las meditaciones completadas localmente.
class MeditationService {
  MeditationService(this._storage, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    reload();
  }

  final StorageService _storage;
  final DateTime Function() _clock;
  final List<MeditationSession> _sessions = <MeditationSession>[];

  void reload() {
    _sessions
      ..clear()
      ..addAll(<MeditationSession>[
        for (final item in _storage.readList(StorageKeys.meditations))
          MeditationSession.fromJson(item),
      ]);
    _sessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<MeditationSession> get sessions =>
      List<MeditationSession>.unmodifiable(_sessions);

  int get count => _sessions.length;

  int get totalMinutes =>
      _sessions.fold<int>(0, (sum, s) => sum + (s.secondsPracticed ~/ 60));

  Future<MeditationSession> record({
    required MeditationType type,
    required int minutes,
    required int secondsPracticed,
    int? fromDay,
  }) async {
    final session = MeditationSession(
      id: LocalId.next('m'),
      type: type,
      minutes: minutes,
      completedAt: _clock(),
      fromDay: fromDay,
      secondsPracticed: secondsPracticed,
    );
    _sessions.insert(0, session);
    await _storage.writeList(
      StorageKeys.meditations,
      <Map<String, dynamic>>[for (final s in _sessions) s.toJson()],
    );
    return session;
  }

  Future<void> clear() async {
    _sessions.clear();
    await _storage.remove(StorageKeys.meditations);
  }
}
