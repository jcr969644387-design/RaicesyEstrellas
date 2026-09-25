import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/achievements_data.dart';
import '../data/sound_catalog.dart';
import '../models/achievement.dart';
import '../models/app_settings.dart';
import '../models/daily_progress.dart';
import '../models/day_content.dart';
import '../models/emotion_check_in.dart';
import '../models/journal_entry.dart';
import '../models/life_stage.dart';
import '../models/meditation_session.dart';
import '../models/micro_challenge.dart';
import '../models/reminder_settings.dart';
import '../models/user_profile.dart';
import 'audio_service.dart';
import 'content_service.dart';
import 'emotion_service.dart';
import 'journal_service.dart';
import 'meditation_service.dart';
import 'notification_service.dart';
import 'personal_guide_service.dart';
import 'progress_service.dart';
import 'safety_response_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';

/// Intensidad de la vibración para momentos importantes.
enum HapticLevel { light, medium, strong }

/// Punto central de estado de la app. Conecta servicios locales con la UI.
class AppController extends ChangeNotifier {
  AppController({
    required this.storage,
    required this.contentService,
    required this.audio,
    required this.notifications,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        settingsService = SettingsService(storage) {
    progress = ProgressService(storage, content, clock: _clock);
    journal = JournalService(storage, clock: _clock);
    emotions = EmotionService(storage, clock: _clock);
    meditations = MeditationService(storage, clock: _clock);
    _profile = settingsService.loadProfile();
    _settings = settingsService.loadSettings();
    audio.updateSettings(_settings);
  }

  /// Crea el controlador con las implementaciones reales o simuladas.
  static Future<AppController> create({
    AudioBackend? audioBackend,
    ReminderPlatform? reminderPlatform,
    AssetBundle? bundle,
    DateTime Function()? clock,
  }) async {
    final storage = await StorageService.create();
    final content = await ContentService.load(bundle: bundle);
    final settingsService = SettingsService(storage);
    return AppController(
      storage: storage,
      contentService: content,
      audio: AudioService(
        audioBackend ?? AudioplayersBackend(),
        settings: settingsService.loadSettings(),
      ),
      notifications: NotificationService(
        reminderPlatform ?? LocalNotificationsPlatform(),
        settingsService,
      ),
      clock: clock,
    );
  }

  final StorageService storage;
  final ContentService contentService;
  final AudioService audio;
  final NotificationService notifications;
  final SettingsService settingsService;
  final DateTime Function() _clock;
  final PersonalGuideService guide = const PersonalGuideService();
  final SafetyResponseService safety = const SafetyResponseService();

  late final ProgressService progress;
  late final JournalService journal;
  late final EmotionService emotions;
  late final MeditationService meditations;

  late UserProfile _profile;
  late AppSettings _settings;

  JourneyContent get content => contentService.content;

  UserProfile get profile => _profile;

  AppSettings get settings => _settings;

  ReminderSettings get reminder => notifications.reminder;

  LifeStage get stage => _profile.effectiveStage;

  DateTime now() => _clock();

  /// Tareas de arranque que pueden tardar (permisos, reprogramación).
  Future<void> init() async {
    await notifications.init();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Onboarding y perfil
  // ---------------------------------------------------------------------------

  Future<void> completeOnboarding({
    required LifeStage stage,
    String? goal,
  }) async {
    _profile = UserProfile(
      onboardingCompleted: true,
      stage: stage,
      goal: goal,
      createdAt: _profile.createdAt ?? _clock(),
    );
    await settingsService.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> updateStage(LifeStage stage) async {
    _profile = _profile.copyWith(stage: stage);
    await settingsService.saveProfile(_profile);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Ajustes, audio y vibración
  // ---------------------------------------------------------------------------

  Future<void> updateSettings(AppSettings next) async {
    _settings = next;
    await settingsService.saveSettings(next);
    await audio.updateSettings(next);
    notifyListeners();
  }

  /// Vibración discreta, solo si está activada en Ajustes.
  Future<bool> vibrate([HapticLevel level = HapticLevel.light]) async {
    if (!_settings.vibrationEnabled) {
      return false;
    }
    try {
      switch (level) {
        case HapticLevel.light:
          await HapticFeedback.lightImpact();
        case HapticLevel.medium:
          await HapticFeedback.mediumImpact();
        case HapticLevel.strong:
          await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint('Vibración no disponible: $e');
    }
    return true;
  }

  Future<void> playEffect(SoundEffect effect) => audio.playEffect(effect);

  // ---------------------------------------------------------------------------
  // Recordatorios
  // ---------------------------------------------------------------------------

  Future<ReminderResult> enableReminder({int? hour, int? minute}) async {
    final r = await notifications.enable(hour: hour, minute: minute);
    notifyListeners();
    return r;
  }

  Future<ReminderResult> disableReminder() async {
    final r = await notifications.disable();
    notifyListeners();
    return r;
  }

  Future<ReminderResult> updateReminderTime(int hour, int minute) async {
    final r = await notifications.updateTime(hour, minute);
    notifyListeners();
    return r;
  }

  Future<ReminderResult> retryReminderPermission() async {
    final r = await notifications.retryPermission();
    notifyListeners();
    return r;
  }

  Future<bool> sendTestReminder() async {
    final ok = await notifications.sendTest();
    notifyListeners();
    return ok;
  }

  // ---------------------------------------------------------------------------
  // Viaje de 30 días
  // ---------------------------------------------------------------------------

  DayContent day(int number) => content.day(number);

  String exampleFor(DayContent d) => contentService.exampleFor(d, stage);

  String challengeTextFor(DayContent d) =>
      contentService.challengeFor(d, stage);

  Future<void> startDay(int day) async {
    await progress.markStarted(day);
    notifyListeners();
  }

  Future<bool> saveDayResponse(DailyProgress response) async {
    final ok = await progress.saveResponse(response);
    notifyListeners();
    return ok;
  }

  Future<EmotionCheckIn?> recordCheckIn({
    required Emotion emotion,
    required int intensity,
    String note = '',
    int? journeyDay,
  }) async {
    final record = await emotions.add(
      emotion: emotion,
      intensity: intensity,
      note: note,
      journeyDay: journeyDay,
    );
    notifyListeners();
    return record;
  }

  Future<bool> deleteCheckIn(String id) async {
    final ok = await emotions.delete(id);
    notifyListeners();
    return ok;
  }

  /// Marca un microreto. Devuelve una insignia si es la primera acción.
  Future<Achievement?> setChallengeStatus(
    int day,
    ChallengeStatus status,
  ) async {
    final d = content.day(day);
    final achievement = await progress.setChallengeStatus(
      day: day,
      title: d.challenge.title,
      text: challengeTextFor(d),
      status: status,
    );
    if (status == ChallengeStatus.completed) {
      await vibrate();
      await playEffect(
          achievement != null ? SoundEffect.badge : SoundEffect.tap);
    }
    notifyListeners();
    return achievement;
  }

  /// Completa un día, guarda respuestas guiadas en el diario y dispara
  /// efectos de audio y vibración según los ajustes.
  Future<DayCompletionResult> completeDay(int day) async {
    final result = await progress.completeDay(day);
    if (!result.accepted) {
      return result;
    }
    await _saveGuidedAnswer(day);
    if (result.journeyCompleted) {
      await _saveLettersToJournal();
    }

    if (result.journeyCompleted) {
      await playEffect(SoundEffect.journeyComplete);
      await vibrate(HapticLevel.strong);
    } else {
      // Día completado + el sonido del logro más importante (estrella,
      // insignia, raíz o constelación). El grupo de efectos admite dos
      // sonidos a la vez, nunca más.
      await playEffect(SoundEffect.dayComplete);
      if (result.isMilestone) {
        await playEffect(SoundEffect.constellation);
        await vibrate(HapticLevel.medium);
      } else if (result.newlyIlluminatedRoots.isNotEmpty) {
        await playEffect(SoundEffect.root);
        await vibrate(HapticLevel.medium);
      } else if (result.newAchievements.isNotEmpty) {
        await playEffect(SoundEffect.badge);
        await vibrate(HapticLevel.medium);
      } else {
        await playEffect(SoundEffect.star);
        await vibrate();
      }
    }
    notifyListeners();
    return result;
  }

  Future<void> _saveGuidedAnswer(int day) async {
    final d = content.day(day);
    final type = d.interaction.type;
    if (type == InteractionType.futureLetter ||
        type == InteractionType.letterReply) {
      return;
    }
    final summary = progress.progressFor(day).summary;
    if (summary.trim().isEmpty) {
      return;
    }
    await journal.upsertGuided(
      day: day,
      title: 'Día $day · ${d.title}',
      text: '${d.question}\n\n$summary',
      tags: <String>[d.theme],
    );
  }

  Future<void> _saveLettersToJournal() async {
    final letter = progress.journey.day1Letter.trim();
    if (letter.isNotEmpty) {
      await journal.add(
        title: 'Carta de mi yo del Día 1',
        text: letter,
        day: 1,
        kind: JournalKind.letter,
        tags: const <String>['Carta'],
      );
    }
    final reply = progress.day30Reply.trim();
    if (reply.isNotEmpty) {
      await journal.add(
        title: 'Respuesta a mi yo del futuro',
        text: reply,
        day: content.totalDays,
        kind: JournalKind.letter,
        tags: const <String>['Carta'],
      );
    }
  }

  Future<bool> saveDay1Letter(String text) async {
    final ok = await progress.saveDay1Letter(text);
    notifyListeners();
    return ok;
  }

  Future<String?> revealLetter() async {
    final hadIt = progress.hasAchievement(AchievementIds.letterRevealed);
    final letter = await progress.revealLetter();
    if (letter != null && !hadIt) {
      await playEffect(SoundEffect.badge);
      await vibrate(HapticLevel.medium);
    }
    notifyListeners();
    return letter;
  }

  Future<bool> saveDay30Reply(String text) async {
    final ok = await progress.saveDay30Reply(text);
    notifyListeners();
    return ok;
  }

  Future<bool> saveDeclaration(String text) async {
    final ok = await progress.saveDeclaration(text);
    if (ok && text.trim().isNotEmpty) {
      await journal.add(
        title: 'Lo que quiero construir',
        text: text,
        day: content.totalDays,
        tags: const <String>['Declaración'],
      );
    }
    notifyListeners();
    return ok;
  }

  // ---------------------------------------------------------------------------
  // Meditación
  // ---------------------------------------------------------------------------

  Future<Achievement?> recordMeditation({
    required MeditationType type,
    required int minutes,
    required int secondsPracticed,
    int? fromDay,
  }) async {
    await meditations.record(
      type: type,
      minutes: minutes,
      secondsPracticed: secondsPracticed,
      fromDay: fromDay,
    );
    final achievement =
        await progress.unlockAchievement(AchievementIds.calmSeed);
    await playEffect(
        achievement != null ? SoundEffect.badge : SoundEffect.bell);
    await vibrate();
    notifyListeners();
    return achievement;
  }

  // ---------------------------------------------------------------------------
  // Diario
  // ---------------------------------------------------------------------------

  Future<JournalEntry?> addJournalEntry({
    required String text,
    String title = '',
    List<String> tags = const <String>[],
    int? day,
  }) async {
    final entry = await journal.add(
      text: text,
      title: title,
      tags: tags,
      day: day,
    );
    notifyListeners();
    return entry;
  }

  Future<bool> updateJournalEntry(JournalEntry entry) async {
    final ok = await journal.update(entry);
    notifyListeners();
    return ok;
  }

  Future<bool> deleteJournalEntry(String id) async {
    final ok = await journal.delete(id);
    notifyListeners();
    return ok;
  }

  // ---------------------------------------------------------------------------
  // Guía local
  // ---------------------------------------------------------------------------

  String guideMessage() {
    final current = progress.currentDay;
    final d = content.day(current);
    final last = emotions.latest;
    MicroChallenge? pending;
    for (final c in progress.challenges.reversed) {
      if (c.status == ChallengeStatus.pending) {
        pending = c;
        break;
      }
    }
    final now = _clock();
    return guide.message(
      GuideContext(
        currentDay: current,
        totalDays: content.totalDays,
        completedCount: progress.completedCount,
        constellationName: content.constellationForDay(current).name,
        rootName: content.rootById(d.rootId).name,
        streak: progress.effectiveStreak(now),
        stage: stage,
        lastEmotion: last?.emotion,
        lastIntensity: last?.intensity,
        returningAfterAbsence: progress.isReturningAfterAbsence(now),
        pendingChallenge: pending,
        journeyComplete: progress.journeyComplete,
        hour: now.hour,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Privacidad y datos
  // ---------------------------------------------------------------------------

  Future<void> deleteJournal() async {
    await journal.deleteAll();
    notifyListeners();
  }

  Future<void> deleteEmotions() async {
    await emotions.deleteAll();
    notifyListeners();
  }

  Future<void> resetJourney() async {
    await progress.resetJourney();
    notifyListeners();
  }

  Future<void> startNewCycle() async {
    await progress.startNewCycle();
    notifyListeners();
  }

  /// Borra todos los datos locales. La app vuelve al onboarding.
  Future<void> deleteAllData() async {
    await audio.stopAll();
    await notifications.reset();
    await storage.clearAll();
    progress.clearMemory();
    progress.reload();
    journal.reload();
    emotions.reload();
    meditations.reload();
    _profile = const UserProfile();
    _settings = const AppSettings();
    await audio.updateSettings(_settings);
    notifyListeners();
  }

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }
}
