import 'package:flutter_test/flutter_test.dart';
import 'package:raices_y_estrellas/data/sound_catalog.dart';
import 'package:raices_y_estrellas/models/app_settings.dart';
import 'package:raices_y_estrellas/models/day_content.dart';
import 'package:raices_y_estrellas/models/emotion_check_in.dart';
import 'package:raices_y_estrellas/models/life_stage.dart';
import 'package:raices_y_estrellas/models/reminder_settings.dart';
import 'package:raices_y_estrellas/services/audio_service.dart';
import 'package:raices_y_estrellas/services/emotion_service.dart';
import 'package:raices_y_estrellas/services/journal_service.dart';
import 'package:raices_y_estrellas/services/notification_service.dart';
import 'package:raices_y_estrellas/services/personal_guide_service.dart';
import 'package:raices_y_estrellas/services/safety_response_service.dart';
import 'package:raices_y_estrellas/services/settings_service.dart';
import 'package:raices_y_estrellas/utils/validators.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Contenido de 30 días', () {
    test('Existen 30 días completos y ordenados', () {
      final content = loadContent();
      expect(content.days.length, 30);
      expect(content.constellations.length, 4);
      expect(content.roots.length, 7);
      final types = <InteractionType>{};
      for (var i = 0; i < 30; i++) {
        final d = content.days[i];
        expect(d.day, i + 1);
        expect(d.title, isNotEmpty);
        expect(d.intro, isNotEmpty);
        expect(d.teaching, isNotEmpty);
        expect(d.philosophyIdea, isNotEmpty);
        expect(d.question, isNotEmpty);
        expect(d.challenge.base, isNotEmpty);
        expect(d.closing, isNotEmpty);
        expect(d.minutes, inInclusiveRange(3, 10));
        expect(content.constellationById(d.constellationId).contains(d.day),
            isTrue);
        for (final stage in LifeStage.values) {
          expect(d.challenge.textFor(stage), isNotEmpty);
          expect(d.examples.forStage(stage), isNotEmpty);
        }
        expect(ambientSounds.any((s) => s.id == d.ambient), isTrue);
        types.add(d.interaction.type);
      }
      expect(content.days.first.interaction.type, InteractionType.futureLetter);
      expect(content.days.last.interaction.type, InteractionType.letterReply);
      expect(types.length, greaterThanOrEqualTo(8),
          reason: 'Los días no deben repetir la misma estructura');
    });
  });

  group('Check-in emocional', () {
    test('Guarda, valida, resume y elimina registros', () async {
      final storage = await freshStorage();
      final clock = TestClock(DateTime(2026, 5, 10, 8));
      final service = EmotionService(storage, clock: clock.call);

      expect(
        await service.add(emotion: Emotion.happy, intensity: 11),
        isNull,
        reason: 'Intensidad fuera de 0–10',
      );
      final a = await service.add(
        emotion: Emotion.calm,
        intensity: 4,
        note: 'tranquilo',
        journeyDay: 1,
      );
      clock.advanceDays(1);
      await service.add(emotion: Emotion.calm, intensity: 6);
      await service.add(emotion: Emotion.tired, intensity: 8);

      expect(service.records.length, 3);
      expect(service.latest?.emotion, Emotion.tired);
      expect(service.forJourneyDay(1)?.id, a?.id);
      expect(service.averageIntensity, closeTo(6, 0.001));
      expect(service.distribution().first.key, Emotion.calm);
      final trend = service.weeklyTrend(clock.current);
      expect(trend.length, 7);
      expect(trend.last.count, 2);
      expect(trend.last.averageIntensity, 7);

      final reopened = EmotionService(storage, clock: clock.call);
      expect(reopened.records.length, 3);

      expect(await service.delete(a!.id), isTrue);
      expect(service.records.length, 2);
      await service.deleteAll();
      expect(EmotionService(storage).records, isEmpty);
    });
  });

  group('Diario', () {
    test('Guarda, edita y elimina entradas', () async {
      final storage = await freshStorage();
      final journal = JournalService(storage);
      expect(await journal.add(text: '   '), isNull);

      final entry = await journal.add(
        text: 'Hoy aprendí algo',
        title: 'Aprendizaje',
        tags: <String>['Calma', 'Calma', ' '],
        day: 3,
      );
      expect(entry, isNotNull);
      expect(entry!.tags, <String>['Calma']);
      expect(journal.byDay(3).length, 1);

      final ok = await journal.update(entry.copyWith(text: 'Texto editado'));
      expect(ok, isTrue);
      final reopened = JournalService(storage);
      expect(reopened.entries.single.text, 'Texto editado');
      expect(reopened.byTag('Calma').length, 1);

      await journal.upsertGuided(day: 2, title: 'Día 2', text: 'Respuesta');
      await journal.upsertGuided(day: 2, title: 'Día 2', text: 'Nueva');
      expect(journal.byDay(2).single.text, 'Nueva');

      expect(await journal.delete(entry.id), isTrue);
      expect(journal.byDay(3), isEmpty);
    });
  });

  group('Guía personal local', () {
    const guide = PersonalGuideService();
    GuideContext ctx({
      int completed = 3,
      bool returning = false,
      Emotion? emotion,
      int? intensity,
      int streak = 0,
      bool complete = false,
      int day = 4,
    }) =>
        GuideContext(
          currentDay: day,
          totalDays: 30,
          completedCount: completed,
          constellationName: 'Constelación Origen',
          rootName: 'Mente',
          streak: streak,
          stage: LifeStage.young,
          lastEmotion: emotion,
          lastIntensity: intensity,
          returningAfterAbsence: returning,
          journeyComplete: complete,
        );

    test('Muestra el mensaje de regreso sin culpa', () {
      expect(
        guide.message(ctx(returning: true)),
        'Tu recorrido no desapareció. Puedes continuar hoy.',
      );
    });

    test('Es cuidadoso con emociones difíciles intensas', () {
      expect(
        guide.message(ctx(emotion: Emotion.anxious, intensity: 9)),
        contains('Pausa'),
      );
    });

    test('Reconoce la constancia y el final del viaje', () {
      expect(guide.message(ctx(streak: 4)), contains('constancia'));
      expect(
        guide.message(ctx(complete: true)),
        contains('Este no es el final de tu viaje'),
      );
      expect(guide.message(ctx(day: 7)), contains('Constelación Origen'));
    });

    test('La respuesta al check-in nunca diagnostica', () {
      final r = guide.checkInResponse(Emotion.sad, 8);
      expect(r, contains('Gracias por ser honesto contigo'));
      expect(r.toLowerCase(), isNot(contains('depresión')));
    });
  });

  group('Respuesta segura', () {
    const safety = SafetyResponseService();

    test('Detecta frases de riesgo sin importar tildes o mayúsculas', () {
      expect(safety.needsSupport('A veces quiero MORIR'), isTrue);
      expect(safety.needsSupport('pienso en hacerme daño'), isTrue);
      expect(safety.needsSupport('Hoy fue un buen día'), isFalse);
      expect(safety.needsSupport('Voy a cortarme el pelo'), isFalse);
      expect(safety.anyNeedsSupport(<String?>[null, 'suicidio']), isTrue);
    });
  });

  group('Validación de datos', () {
    test('Valida textos, horas, intensidades y días', () {
      expect(Validators.hasMinLength('  ab ', 3), isFalse);
      expect(Validators.hasMinLength('abc', 3), isTrue);
      expect(Validators.cleanTag('   '), isNull);
      expect(Validators.cleanTag('x' * 40)!.length, Validators.maxTagLength);
      expect(Validators.isValidDay(0, 30), isFalse);
      expect(Validators.isValidDay(30, 30), isTrue);
      expect(ReminderSettings.isValidTime(24, 0), isFalse);
      expect(ReminderSettings.isValidTime(7, 30), isTrue);
      expect(EmotionCheckIn.isValidIntensity(-1), isFalse);
      expect(EmotionCheckIn.isValidIntensity(10), isTrue);
      final s = const AppSettings().copyWith(musicVolume: 3, textScale: 9);
      expect(s.musicVolume, 1.0);
      expect(s.textScale, AppSettings.maxTextScale);
    });
  });

  group('Recordatorios', () {
    test('Activar, cambiar hora, desactivar y persistir', () async {
      final storage = await freshStorage();
      final settings = SettingsService(storage);
      final platform = FakeReminderPlatform();
      final service = NotificationService(platform, settings);

      expect(
          await service.enable(hour: 8, minute: 15), ReminderResult.scheduled);
      expect(platform.scheduled.last,
          '${NotificationService.dailyReminderId}@8:15');
      var saved = settings.loadReminder();
      expect(saved.enabled, isTrue);
      expect(saved.hour, 8);
      expect(saved.minute, 15);
      expect(saved.permission, NotificationPermission.granted);

      expect(await service.updateTime(21, 5), ReminderResult.scheduled);
      expect(settings.loadReminder().formattedTime, '21:05');

      expect(await service.disable(), ReminderResult.disabled);
      expect(platform.cancelled, contains(NotificationService.dailyReminderId));
      saved = settings.loadReminder();
      expect(saved.enabled, isFalse);
      expect(saved.hour, 21);
    });

    test('Si se rechaza el permiso, la app lo recuerda y permite reintentar',
        () async {
      final storage = await freshStorage();
      final settings = SettingsService(storage);
      final platform = FakeReminderPlatform(grant: false);
      final service = NotificationService(platform, settings);

      expect(await service.enable(), ReminderResult.permissionDenied);
      expect(settings.loadReminder().permission, NotificationPermission.denied);
      expect(settings.loadReminder().enabled, isFalse);

      platform.grant = true;
      expect(await service.retryPermission(), ReminderResult.scheduled);
      expect(settings.loadReminder().enabled, isTrue);
    });
  });

  group('Audio', () {
    test('Las preferencias de audio se guardan', () async {
      final app = await buildTestApp();
      final c = app.controller;
      await c.updateSettings(
        c.settings.copyWith(
          musicEnabled: false,
          ambientVolume: 0.2,
          ambientSound: 'sea',
          effectsEnabled: false,
          vibrationEnabled: false,
        ),
      );
      final loaded = SettingsService(c.storage).loadSettings();
      expect(loaded.musicEnabled, isFalse);
      expect(loaded.ambientVolume, closeTo(0.2, 0.0001));
      expect(loaded.ambientSound, 'sea');
      expect(loaded.effectsEnabled, isFalse);
      expect(loaded.vibrationEnabled, isFalse);
    });

    test('Los controles cambian realmente el comportamiento', () async {
      final backend = SilentAudioBackend();
      final audio = AudioService(backend);

      expect(await audio.playAmbient('forest'), isTrue);
      expect(audio.isAmbientPlaying, isTrue);
      expect(backend.calls.last, 'loop:ambient:audio/nature/forest.ogg');

      await audio.updateSettings(
        const AppSettings().copyWith(ambientEnabled: false),
      );
      expect(audio.isAmbientPlaying, isFalse);
      expect(backend.calls.last, 'stop:ambient');
      expect(await audio.playAmbient(), isFalse);

      await audio.updateSettings(
        const AppSettings().copyWith(effectsEnabled: false),
      );
      final before = backend.calls.length;
      expect(await audio.playEffect(SoundEffect.star), isFalse);
      expect(backend.calls.length, before);

      await audio.updateSettings(const AppSettings());
      expect(await audio.playMusic(), isTrue);
      await audio.pauseMusic();
      expect(audio.isMusicPlaying, isFalse);
      await audio.resumeMusic();
      expect(audio.isMusicPlaying, isTrue);
      await audio.stopAll();
      expect(audio.isMusicPlaying, isFalse);
    });
  });

  group('Borrado de datos locales', () {
    test('Borrar todo vuelve al estado inicial', () async {
      final app = await buildTestApp();
      final c = app.controller;
      await c.completeOnboarding(
          stage: LifeStage.adult, goal: 'Encontrar dirección');
      await c.completeDay(1);
      await c.addJournalEntry(text: 'Una nota');
      await c.recordCheckIn(emotion: Emotion.happy, intensity: 6);
      await c.enableReminder(hour: 7, minute: 0);

      expect(c.progress.completedCount, 1);
      expect(c.journal.count, greaterThan(0));

      await c.deleteAllData();
      expect(c.profile.onboardingCompleted, isFalse);
      expect(c.progress.completedCount, 0);
      expect(c.journal.count, 0);
      expect(c.emotions.records, isEmpty);
      expect(c.reminder.enabled, isFalse);

      final reopened = await buildTestApp(storage: c.storage);
      expect(reopened.controller.profile.onboardingCompleted, isFalse);
      expect(reopened.controller.progress.completedCount, 0);
    });

    test('Eliminar diario y emociones por separado', () async {
      final app = await buildTestApp();
      final c = app.controller;
      await c.addJournalEntry(text: 'Una nota');
      await c.recordCheckIn(emotion: Emotion.calm, intensity: 3);
      await c.deleteJournal();
      expect(c.journal.count, 0);
      expect(c.emotions.records.length, 1);
      await c.deleteEmotions();
      expect(c.emotions.records, isEmpty);
    });
  });
}
