import 'package:flutter_test/flutter_test.dart';
import 'package:raices_y_estrellas/data/achievements_data.dart';
import 'package:raices_y_estrellas/models/daily_progress.dart';
import 'package:raices_y_estrellas/models/root_progress.dart';
import 'package:raices_y_estrellas/services/progress_service.dart';
import 'package:raices_y_estrellas/services/storage_service.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late TestClock clock;
  late ProgressService progress;

  setUp(() async {
    storage = await freshStorage();
    clock = TestClock(DateTime(2026, 3, 2, 9));
    progress = ProgressService(storage, loadContent(), clock: clock.call);
  });

  Future<void> completeUpTo(int day, {bool advanceClock = true}) async {
    for (var d = progress.completedCount + 1; d <= day; d++) {
      final r = await progress.completeDay(d);
      expect(r.accepted, isTrue, reason: 'Día $d debería completarse');
      if (advanceClock) {
        clock.advanceDays(1);
      }
    }
  }

  group('Progresión secuencial', () {
    test('El Día 1 empieza desbloqueado', () {
      expect(progress.isUnlocked(1), isTrue);
      expect(progress.status(1), DayStatus.available);
      expect(progress.currentDay, 1);
    });

    test('El Día 2 está bloqueado antes de completar el Día 1', () {
      expect(progress.isUnlocked(2), isFalse);
      expect(progress.canOpen(2), isFalse);
      expect(progress.status(2), DayStatus.locked);
    });

    test('Completar el Día 1 desbloquea el Día 2', () async {
      await progress.completeDay(1);
      expect(progress.status(1), DayStatus.completed);
      expect(progress.isUnlocked(2), isTrue);
      expect(progress.status(2), DayStatus.available);
      expect(progress.unlockedDay, 2);
    });

    test('Los días completados siguen disponibles para revisión', () async {
      await completeUpTo(3);
      for (var d = 1; d <= 3; d++) {
        expect(progress.canOpen(d), isTrue);
        expect(progress.status(d), DayStatus.completed);
      }
    });

    test('No se puede acceder ni completar un día futuro bloqueado', () async {
      await progress.completeDay(1);
      expect(progress.canOpen(5), isFalse);
      final r = await progress.completeDay(5);
      expect(r.accepted, isFalse);
      expect(progress.isCompleted(5), isFalse);
      final again = await progress.completeDay(1);
      expect(again.accepted, isFalse,
          reason: 'Un día no se completa dos veces');
    });

    test('El Día 30 está bloqueado hasta completar el Día 29', () async {
      await completeUpTo(28);
      expect(progress.isUnlocked(30), isFalse);
      expect((await progress.completeDay(30)).accepted, isFalse);
      await completeUpTo(29);
      expect(progress.isUnlocked(30), isTrue);
      expect(progress.status(30), DayStatus.available);
    });

    test('Marcar un día como iniciado lo muestra en progreso', () async {
      await progress.markStarted(1);
      expect(progress.status(1), DayStatus.inProgress);
      await progress.markStarted(3);
      expect(progress.isStarted(3), isFalse, reason: 'Día bloqueado');
    });
  });

  group('Rachas', () {
    test('La racha crece en días consecutivos y se reinicia tras una pausa',
        () async {
      await progress.completeDay(1);
      expect(progress.journey.currentStreak, 1);
      clock.advanceDays(1);
      await progress.completeDay(2);
      expect(progress.journey.currentStreak, 2);
      clock.advanceDays(1);
      await progress.completeDay(3);
      expect(progress.journey.currentStreak, 3);

      clock.advanceDays(4);
      expect(progress.effectiveStreak(), 0);
      expect(progress.isReturningAfterAbsence(), isTrue);
      expect(progress.completedCount, 3, reason: 'Nunca se borra progreso');

      final r = await progress.completeDay(4);
      expect(r.returnedAfterAbsence, isTrue);
      expect(progress.journey.currentStreak, 1);
      expect(progress.longestStreak, 3);
      expect(progress.hasAchievement(AchievementIds.beginAgain), isTrue);
    });

    test('Varios días en la misma fecha no duplican la racha', () async {
      await progress.completeDay(1);
      await progress.completeDay(2);
      expect(progress.journey.currentStreak, 1);
      expect(progress.completedCount, 2);
    });

    test('Perder la racha no elimina insignias ni estrellas', () async {
      await completeUpTo(7);
      clock.advanceDays(10);
      expect(progress.effectiveStreak(), 0);
      expect(progress.stars, 7);
      expect(progress.hasAchievement(AchievementIds.sevenDays), isTrue);
      expect(progress.hasAchievement(AchievementIds.firstStep), isTrue);
    });
  });

  group('Persistencia', () {
    test('El progreso se conserva al reabrir la app', () async {
      await completeUpTo(4);
      await progress.saveDay1Letter('no debería guardarse');
      final reopened =
          ProgressService(storage, loadContent(), clock: clock.call);
      expect(reopened.completedDays, <int>[1, 2, 3, 4]);
      expect(reopened.unlockedDay, 5);
      expect(reopened.xp, progress.xp);
      expect(reopened.longestStreak, progress.longestStreak);
    });

    test('Las respuestas del día se guardan', () async {
      await progress.saveResponse(
        const DailyProgress(day: 1, choice: 'Opción', scale: 7),
      );
      final reopened =
          ProgressService(storage, loadContent(), clock: clock.call);
      expect(reopened.progressFor(1).choice, 'Opción');
      expect(reopened.progressFor(1).scale, 7);
      final denied = await progress.saveResponse(
        const DailyProgress(day: 9, text: 'bloqueado'),
      );
      expect(denied, isFalse);
    });
  });

  group('Estrellas, constelaciones, raíces y árbol', () {
    test('Cada día completado enciende una estrella', () async {
      expect(progress.stars, 0);
      await completeUpTo(5);
      expect(progress.stars, 5);
    });

    test('El Día 7 completa la Constelación Origen', () async {
      await completeUpTo(6);
      final r = await progress.completeDay(7);
      expect(r.isMilestone, isTrue);
      expect(r.completedConstellation?.id, 'origen');
      expect(progress.completedConstellations, 1);
      expect(progress.constellationProgress().first.isComplete, isTrue);
      expect(
          progress.hasAchievement(AchievementIds.firstConstellation), isTrue);
      expect(progress.treeStage, TreeStage.sprout);
    });

    test('Los hitos 14 y 21 evolucionan el árbol', () async {
      await completeUpTo(14);
      expect(progress.treeStage, TreeStage.young);
      expect(progress.hasAchievement(AchievementIds.strength), isTrue);
      await completeUpTo(21);
      expect(progress.treeStage, TreeStage.growing);
      expect(progress.hasAchievement(AchievementIds.action), isTrue);
      expect(progress.hasAchievement(AchievementIds.twentyOneDays), isTrue);
    });

    test('El progreso de raíces responde a los días completados', () async {
      final initial = progress.rootProgress();
      expect(initial.length, 7);
      expect(initial.every((r) => r.state == RootState.locked), isTrue);

      await completeUpTo(6);
      final auto = progress
          .rootProgress()
          .firstWhere((r) => r.info.id == 'autoconocimiento');
      expect(auto.state, RootState.illuminated);
      expect(auto.percent, 100);
      expect(auto.reflectionUnlocked, isTrue);
      final mente =
          progress.rootProgress().firstWhere((r) => r.info.id == 'mente');
      expect(mente.state, RootState.growing);
      expect(progress.hasAchievement(AchievementIds.firstRoot), isTrue);
    });

    test('Completar los 30 días ilumina todo', () async {
      await completeUpTo(30);
      expect(progress.journeyComplete, isTrue);
      expect(progress.stars, 30);
      expect(progress.completedConstellations, 4);
      expect(progress.treeStage, TreeStage.full);
      expect(
        progress.rootProgress().every((r) => r.state == RootState.illuminated),
        isTrue,
      );
      expect(progress.hasAchievement(AchievementIds.journeyComplete), isTrue);
    });
  });

  group('Carta del Día 1', () {
    test('Se edita antes del Día 1 y queda sellada hasta el Día 30', () async {
      expect(await progress.saveDay1Letter('Hola, futuro yo'), isTrue);
      expect(progress.editableDay1Letter, 'Hola, futuro yo');
      await progress.completeDay(1);

      expect(progress.isLetterEditable, isFalse);
      expect(await progress.saveDay1Letter('cambio'), isFalse);
      expect(progress.editableDay1Letter, isEmpty);
      expect(progress.readDay1Letter(), isNull);
      expect(await progress.revealLetter(), isNull);

      clock.advanceDays(1);
      await completeUpTo(28);
      expect(progress.readDay1Letter(), isNull);
      await completeUpTo(29);
      expect(progress.canRevealLetter, isTrue);
      expect(await progress.revealLetter(), 'Hola, futuro yo');
      expect(progress.hasAchievement(AchievementIds.letterRevealed), isTrue);
      expect(await progress.saveDay30Reply('Gracias'), isTrue);
    });
  });

  group('Reinicios', () {
    test('Nuevo ciclo guarda un resumen y vuelve al Día 1', () async {
      await completeUpTo(30);
      await progress.startNewCycle();
      expect(progress.cycle, 2);
      expect(progress.completedCount, 0);
      expect(progress.currentDay, 1);
      expect(progress.journey.previousCycles.single.completedDays, 30);
      expect(progress.hasAchievement(AchievementIds.journeyComplete), isTrue);
    });

    test('Reiniciar el viaje conserva las insignias', () async {
      await completeUpTo(2);
      await progress.resetJourney();
      expect(progress.completedCount, 0);
      expect(progress.hasAchievement(AchievementIds.firstStep), isTrue);
    });
  });
}
