import 'dart:math' as math;

import '../data/achievements_data.dart';
import '../models/achievement.dart';
import '../models/constellation_progress.dart';
import '../models/daily_progress.dart';
import '../models/day_content.dart';
import '../models/micro_challenge.dart';
import '../models/root_progress.dart';
import '../utils/date_utils.dart';
import 'storage_service.dart';

/// Resultado de completar un día.
class DayCompletionResult {
  const DayCompletionResult({
    required this.day,
    required this.accepted,
    this.xpGained = 0,
    this.newAchievements = const <Achievement>[],
    this.completedConstellation,
    this.newlyIlluminatedRoots = const <RootInfo>[],
    this.journeyCompleted = false,
    this.returnedAfterAbsence = false,
    this.reason = '',
  });

  const DayCompletionResult.rejected(this.day, this.reason)
      : accepted = false,
        xpGained = 0,
        newAchievements = const <Achievement>[],
        completedConstellation = null,
        newlyIlluminatedRoots = const <RootInfo>[],
        journeyCompleted = false,
        returnedAfterAbsence = false;

  final int day;
  final bool accepted;
  final int xpGained;
  final List<Achievement> newAchievements;
  final ConstellationInfo? completedConstellation;
  final List<RootInfo> newlyIlluminatedRoots;
  final bool journeyCompleted;
  final bool returnedAfterAbsence;
  final String reason;

  bool get isMilestone => completedConstellation != null;
}

/// Etapas visuales del árbol del crecimiento.
enum TreeStage {
  seed('Semilla'),
  sprout('Brote visible'),
  young('Árbol joven'),
  growing('Árbol en crecimiento'),
  full('Árbol completo');

  const TreeStage(this.label);

  final String label;
}

/// Lógica de progreso secuencial, rachas, estrellas, raíces, constelaciones,
/// cartas, microretos e insignias. Todo se guarda localmente.
class ProgressService {
  ProgressService(
    this._storage,
    this._content, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _load();
  }

  final StorageService _storage;
  final JourneyContent _content;
  final DateTime Function() _clock;

  static const int xpPerLevel = 500;

  JourneyProgress _journey = const JourneyProgress();
  final Map<int, DailyProgress> _daily = <int, DailyProgress>{};
  final Map<String, DateTime> _achievements = <String, DateTime>{};
  final Map<int, MicroChallenge> _challenges = <int, MicroChallenge>{};

  void _load() {
    final journeyJson = _storage.readMap(StorageKeys.journey);
    _journey = journeyJson == null
        ? const JourneyProgress()
        : JourneyProgress.fromJson(journeyJson);
    _daily.clear();
    for (final item in _storage.readList(StorageKeys.dailyProgress)) {
      final p = DailyProgress.fromJson(item);
      if (p.day > 0) {
        _daily[p.day] = p;
      }
    }
    _achievements.clear();
    final ach = _storage.readMap(StorageKeys.achievements);
    if (ach != null) {
      for (final entry in ach.entries) {
        final date = DateTime.tryParse('${entry.value}');
        if (date != null) {
          _achievements[entry.key] = date;
        }
      }
    }
    _challenges.clear();
    for (final item in _storage.readList(StorageKeys.challenges)) {
      final c = MicroChallenge.fromJson(item);
      if (c.day > 0) {
        _challenges[c.day] = c;
      }
    }
    // Normaliza los datos por si vienen de una versión anterior.
    _journey = _normalized(_journey);
  }

  /// Vuelve a leer los datos persistidos (por ejemplo, tras borrar datos).
  void reload() => _load();

  // ---------------------------------------------------------------------------
  // Estado básico
  // ---------------------------------------------------------------------------

  JourneyProgress get journey => _journey;

  int get totalDays => _content.totalDays;

  int get cycle => _journey.cycle;

  List<int> get completedDays {
    final list = List<int>.of(_journey.completedDays)..sort();
    return list;
  }

  int get completedCount => _journey.completedDays.toSet().length;

  bool isCompleted(int day) => _journey.completedDays.contains(day);

  bool isStarted(int day) => _journey.startedDays.contains(day);

  /// Último día desbloqueado según la regla estrictamente secuencial.
  int get unlockedDay => _computeUnlocked(_journey.completedDays);

  int _computeUnlocked(List<int> completed) {
    final set = completed.toSet();
    var contiguous = 0;
    while (set.contains(contiguous + 1)) {
      contiguous++;
    }
    return math.min(contiguous + 1, math.max(totalDays, 1));
  }

  bool isUnlocked(int day) => day >= 1 && day <= unlockedDay;

  /// Un día se puede abrir si está desbloqueado (disponible o completado).
  bool canOpen(int day) => isUnlocked(day);

  bool get journeyComplete => totalDays > 0 && completedCount >= totalDays;

  /// Día que corresponde hacer ahora (o el último si el viaje terminó).
  int get currentDay => journeyComplete ? totalDays : unlockedDay;

  DayStatus status(int day) {
    if (isCompleted(day)) {
      return DayStatus.completed;
    }
    if (!isUnlocked(day)) {
      return DayStatus.locked;
    }
    if (isStarted(day)) {
      return DayStatus.inProgress;
    }
    return DayStatus.available;
  }

  DailyProgress progressFor(int day) => _daily[day] ?? DailyProgress(day: day);

  int get stars => completedCount;

  int get xp => _journey.xp;

  int get level => 1 + _journey.xp ~/ xpPerLevel;

  double get levelProgress => (_journey.xp % xpPerLevel) / xpPerLevel;

  // ---------------------------------------------------------------------------
  // Rachas (visuales, nunca borran progreso)
  // ---------------------------------------------------------------------------

  /// Racha visible hoy: si pasó más de un día sin actividad, se muestra 0,
  /// pero el progreso, las estrellas y las insignias se conservan.
  int effectiveStreak([DateTime? now]) {
    final last = DateUtilsX.parseDayKey(_journey.lastActivityDate);
    if (last == null) {
      return 0;
    }
    final diff = DateUtilsX.daysBetween(last, now ?? _clock());
    return diff <= 1 ? _journey.currentStreak : 0;
  }

  int get longestStreak => _journey.longestStreak;

  /// Días desde la última actividad del viaje (null si nunca hubo).
  int? daysSinceLastActivity([DateTime? now]) {
    final last = DateUtilsX.parseDayKey(_journey.lastActivityDate);
    if (last == null) {
      return null;
    }
    return DateUtilsX.daysBetween(last, now ?? _clock());
  }

  /// Verdadero si la persona vuelve tras dos o más días sin actividad.
  bool isReturningAfterAbsence([DateTime? now]) {
    if (journeyComplete || completedCount == 0) {
      return false;
    }
    final days = daysSinceLastActivity(now);
    return days != null && days >= 2;
  }

  // ---------------------------------------------------------------------------
  // Días
  // ---------------------------------------------------------------------------

  Future<void> markStarted(int day) async {
    if (!canOpen(day) || isCompleted(day) || isStarted(day)) {
      return;
    }
    _journey = _journey.copyWith(
      startedDays: <int>[..._journey.startedDays, day],
    );
    final current = progressFor(day);
    _daily[day] = current.copyWith(startedAt: current.startedAt ?? _clock());
    await _saveJourney();
    await _saveDaily();
  }

  /// Guarda respuestas de un día abierto. No permite escribir en días
  /// bloqueados.
  Future<bool> saveResponse(DailyProgress progress) async {
    if (!canOpen(progress.day)) {
      return false;
    }
    _daily[progress.day] = progress;
    await _saveDaily();
    return true;
  }

  Future<DayCompletionResult> completeDay(int day) async {
    if (day < 1 || day > totalDays) {
      return DayCompletionResult.rejected(day, 'Día inexistente');
    }
    if (!canOpen(day)) {
      return DayCompletionResult.rejected(day, 'Día bloqueado');
    }
    if (isCompleted(day)) {
      return DayCompletionResult.rejected(day, 'Día ya completado');
    }
    if (day != unlockedDay) {
      return DayCompletionResult.rejected(day, 'Progreso secuencial');
    }

    final now = _clock();
    final rootsBefore = <String>{
      for (final r in rootProgress())
        if (r.state == RootState.illuminated) r.info.id,
    };

    // Racha: se basa en días de calendario, nunca borra progreso.
    final last = DateUtilsX.parseDayKey(_journey.lastActivityDate);
    var streak = _journey.currentStreak;
    var returned = false;
    if (last == null) {
      streak = 1;
    } else {
      final diff = DateUtilsX.daysBetween(last, now);
      if (diff <= 0) {
        streak = math.max(streak, 1);
      } else if (diff == 1) {
        streak = streak + 1;
      } else {
        streak = 1;
        returned = completedCount > 0;
      }
    }

    final dayContent = _content.day(day);
    final completed = <int>[..._journey.completedDays, day]..sort();
    final xpGained = dayContent.reward.xp;
    _journey = _journey.copyWith(
      completedDays: completed,
      unlockedDay: _computeUnlocked(completed),
      currentDay: completed.length >= totalDays
          ? totalDays
          : _computeUnlocked(completed),
      lastActivityDate: DateUtilsX.dayKey(now),
      currentStreak: streak,
      longestStreak: math.max(_journey.longestStreak, streak),
      xp: _journey.xp + xpGained,
      journeyCompletedAt: completed.length >= totalDays ? now : null,
    );
    final current = progressFor(day);
    _daily[day] = current.copyWith(
      startedAt: current.startedAt ?? now,
      completedAt: now,
    );

    // Insignias.
    final unlocked = <Achievement>[];
    Future<void> award(String id) async {
      final a = await unlockAchievement(id, save: false);
      if (a != null) {
        unlocked.add(a);
      }
    }

    final count = completed.length;
    if (count >= 1) {
      await award(AchievementIds.firstStep);
    }
    if (count >= 7) {
      await award(AchievementIds.sevenDays);
    }
    if (count >= 21) {
      await award(AchievementIds.twentyOneDays);
    }
    if (returned) {
      await award(AchievementIds.beginAgain);
    }

    ConstellationInfo? constellation;
    for (final c in _content.constellations) {
      if (c.lastDay == day && _isConstellationComplete(c)) {
        constellation = c;
      }
    }
    if (constellation != null) {
      final index = _content.constellations.indexOf(constellation);
      if (index == 0) {
        await award(AchievementIds.firstConstellation);
      } else if (index == 1) {
        await award(AchievementIds.strength);
      } else if (index == 2) {
        await award(AchievementIds.action);
      }
    }

    final rootsAfter = rootProgress();
    final newRoots = <RootInfo>[
      for (final r in rootsAfter)
        if (r.state == RootState.illuminated &&
            !rootsBefore.contains(r.info.id))
          r.info,
    ];
    if (newRoots.isNotEmpty) {
      await award(AchievementIds.firstRoot);
    }
    if (rootsAfter.isNotEmpty &&
        rootsAfter.every((r) => r.state == RootState.illuminated)) {
      await award(AchievementIds.allRoots);
    }
    final journeyDone = count >= totalDays;
    if (journeyDone) {
      await award(AchievementIds.journeyComplete);
    }

    await _saveJourney();
    await _saveDaily();
    await _saveAchievements();

    return DayCompletionResult(
      day: day,
      accepted: true,
      xpGained: xpGained,
      newAchievements: unlocked,
      completedConstellation: constellation,
      newlyIlluminatedRoots: newRoots,
      journeyCompleted: journeyDone,
      returnedAfterAbsence: returned,
    );
  }

  // ---------------------------------------------------------------------------
  // Constelaciones, raíces y árbol
  // ---------------------------------------------------------------------------

  bool _isConstellationComplete(ConstellationInfo c) {
    for (var d = c.firstDay; d <= c.lastDay; d++) {
      if (!isCompleted(d)) {
        return false;
      }
    }
    return true;
  }

  List<ConstellationProgress> constellationProgress() {
    return <ConstellationProgress>[
      for (final c in _content.constellations)
        ConstellationProgress(
          info: c,
          completedDays: <int>[
            for (var d = c.firstDay; d <= c.lastDay; d++)
              if (isCompleted(d)) d,
          ],
        ),
    ];
  }

  int get completedConstellations =>
      constellationProgress().where((c) => c.isComplete).length;

  ConstellationInfo get activeConstellation =>
      _content.constellationForDay(currentDay);

  List<RootProgress> rootProgress() {
    return <RootProgress>[
      for (final root in _content.roots) _rootProgressFor(root),
    ];
  }

  RootProgress _rootProgressFor(RootInfo root) {
    final days = _content.daysForRoot(root.id);
    final titles = <int, String>{
      for (final d in days) d: _content.day(d).title,
    };
    final challengeTitles = <String>[];
    var challengesDone = 0;
    for (final d in days) {
      challengeTitles.add(_content.day(d).challenge.title);
      if (_challenges[d]?.status == ChallengeStatus.completed) {
        challengesDone++;
      }
    }
    return RootProgress(
      info: root,
      days: days,
      completedDays: <int>[
        for (final d in days)
          if (isCompleted(d)) d,
      ],
      challengesCompleted: challengesDone,
      dayTitles: titles,
      challengeTitles: challengeTitles,
    );
  }

  TreeStage get treeStage {
    final c = completedCount;
    if (c >= totalDays && totalDays > 0) {
      return TreeStage.full;
    }
    if (c >= 21) {
      return TreeStage.growing;
    }
    if (c >= 14) {
      return TreeStage.young;
    }
    if (c >= 7) {
      return TreeStage.sprout;
    }
    return TreeStage.seed;
  }

  /// Crecimiento continuo entre 0 y 1 para animar el árbol.
  double get treeGrowth => totalDays == 0 ? 0.0 : completedCount / totalDays;

  // ---------------------------------------------------------------------------
  // Cartas del Día 1 y del Día 30
  // ---------------------------------------------------------------------------

  /// La carta puede editarse solo antes de completar el Día 1.
  bool get isLetterEditable => !isCompleted(1);

  bool get hasDay1Letter => _journey.day1Letter.trim().isNotEmpty;

  /// Texto editable de la carta; solo disponible mientras no esté sellada.
  String get editableDay1Letter => isLetterEditable ? _journey.day1Letter : '';

  Future<bool> saveDay1Letter(String text) async {
    if (!isLetterEditable) {
      return false;
    }
    _journey = _journey.copyWith(day1Letter: text);
    await _saveJourney();
    return true;
  }

  /// La carta se revela solo cuando el Día 30 está desbloqueado.
  bool get canRevealLetter => totalDays > 0 && isUnlocked(totalDays);

  bool get letterRevealed => _journey.letterRevealed;

  /// Devuelve la carta completa solo si ya corresponde revelarla.
  String? readDay1Letter() {
    if (!canRevealLetter) {
      return null;
    }
    return _journey.day1Letter;
  }

  Future<String?> revealLetter() async {
    if (!canRevealLetter) {
      return null;
    }
    if (!_journey.letterRevealed) {
      _journey = _journey.copyWith(letterRevealed: true);
      await unlockAchievement(AchievementIds.letterRevealed);
      await _saveJourney();
    }
    return _journey.day1Letter;
  }

  String get day30Reply => _journey.day30Reply;

  Future<bool> saveDay30Reply(String text) async {
    if (!canRevealLetter) {
      return false;
    }
    _journey = _journey.copyWith(day30Reply: text);
    await _saveJourney();
    return true;
  }

  String get finalDeclaration => _journey.finalDeclaration;

  Future<bool> saveDeclaration(String text) async {
    if (!journeyComplete) {
      return false;
    }
    _journey = _journey.copyWith(finalDeclaration: text);
    await _saveJourney();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Microretos
  // ---------------------------------------------------------------------------

  MicroChallenge? challengeFor(int day) => _challenges[day];

  List<MicroChallenge> get challenges {
    final list = _challenges.values.toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return list;
  }

  int get challengesCompleted => _challenges.values
      .where((c) => c.status == ChallengeStatus.completed)
      .length;

  /// Marca un microreto. Omitirlo no resta nada.
  Future<Achievement?> setChallengeStatus({
    required int day,
    required String title,
    required String text,
    required ChallengeStatus status,
  }) async {
    if (!canOpen(day)) {
      return null;
    }
    final existing = _challenges[day];
    _challenges[day] =
        (existing ?? MicroChallenge(day: day, title: title, text: text))
            .copyWith(status: status, updatedAt: _clock());
    await _saveChallenges();
    if (status == ChallengeStatus.completed) {
      return unlockAchievement(AchievementIds.smallAction);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Insignias
  // ---------------------------------------------------------------------------

  List<Achievement> get achievements {
    return <Achievement>[
      for (final a in achievementCatalog)
        _achievements.containsKey(a.id) ? a.unlock(_achievements[a.id]!) : a,
    ];
  }

  int get unlockedAchievementCount => _achievements.length;

  bool hasAchievement(String id) => _achievements.containsKey(id);

  /// Desbloquea una insignia. Devuelve la insignia si es nueva.
  Future<Achievement?> unlockAchievement(String id, {bool save = true}) async {
    if (_achievements.containsKey(id)) {
      return null;
    }
    Achievement? def;
    for (final a in achievementCatalog) {
      if (a.id == id) {
        def = a;
      }
    }
    if (def == null) {
      return null;
    }
    final now = _clock();
    _achievements[id] = now;
    if (save) {
      await _saveAchievements();
    }
    return def.unlock(now);
  }

  // ---------------------------------------------------------------------------
  // Reinicios
  // ---------------------------------------------------------------------------

  /// Reinicia el viaje actual. Las insignias obtenidas se conservan.
  Future<void> resetJourney() async {
    _journey = JourneyProgress(
      cycle: _journey.cycle,
      previousCycles: _journey.previousCycles,
    );
    _daily.clear();
    _challenges.clear();
    await _saveJourney();
    await _saveDaily();
    await _saveChallenges();
  }

  /// Inicia un nuevo ciclo guardando un resumen del anterior.
  Future<void> startNewCycle() async {
    final summary = CycleSummary(
      cycle: _journey.cycle,
      completedDays: completedCount,
      longestStreak: _journey.longestStreak,
      xp: _journey.xp,
      finishedAt: _journey.journeyCompletedAt,
      declaration:
          _journey.finalDeclaration.isEmpty ? null : _journey.finalDeclaration,
    );
    _journey = JourneyProgress(
      cycle: _journey.cycle + 1,
      xp: _journey.xp,
      longestStreak: _journey.longestStreak,
      previousCycles: <CycleSummary>[..._journey.previousCycles, summary],
    );
    _daily.clear();
    _challenges.clear();
    await _saveJourney();
    await _saveDaily();
    await _saveChallenges();
  }

  /// Limpia el estado en memoria (usado al borrar todos los datos).
  void clearMemory() {
    _journey = const JourneyProgress();
    _daily.clear();
    _challenges.clear();
    _achievements.clear();
  }

  // ---------------------------------------------------------------------------
  // Persistencia
  // ---------------------------------------------------------------------------

  JourneyProgress _normalized(JourneyProgress p) {
    final valid = <int>{
      for (final d in p.completedDays)
        if (d >= 1 && d <= totalDays) d,
    }.toList()
      ..sort();
    final unlocked = _computeUnlocked(valid);
    return p.copyWith(
      completedDays: valid,
      unlockedDay: unlocked,
      currentDay: valid.length >= totalDays ? totalDays : unlocked,
    );
  }

  Future<void> _saveJourney() async {
    await _storage.writeMap(StorageKeys.journey, _journey.toJson());
  }

  Future<void> _saveDaily() async {
    await _storage.writeList(
      StorageKeys.dailyProgress,
      <Map<String, dynamic>>[for (final p in _daily.values) p.toJson()],
    );
  }

  Future<void> _saveChallenges() async {
    await _storage.writeList(
      StorageKeys.challenges,
      <Map<String, dynamic>>[for (final c in _challenges.values) c.toJson()],
    );
  }

  Future<void> _saveAchievements() async {
    await _storage.writeMap(
      StorageKeys.achievements,
      <String, dynamic>{
        for (final e in _achievements.entries) e.key: e.value.toIso8601String(),
      },
    );
  }
}
