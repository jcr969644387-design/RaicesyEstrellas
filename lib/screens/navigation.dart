import 'package:flutter/material.dart';

import '../models/meditation_session.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import 'challenges_screen.dart';
import 'day_session_screen.dart';
import 'emotions_screen.dart';
import 'meditation_player_screen.dart';
import 'pause_screen.dart';
import 'tree_screen.dart';

/// Abre un día solo si está desbloqueado. Los días futuros no se pueden
/// abrir; los completados se abren en modo revisión.
Future<void> openDay(BuildContext context, int day) async {
  final app = AppScope.read(context);
  if (!app.progress.canOpen(day)) {
    showMessage(
      context,
      'El Día $day se desbloquea al completar el Día ${day - 1}.',
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => DaySessionScreen(day: day)),
  );
}

Future<void> openPause(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const PauseScreen(),
    ),
  );
}

Future<void> openMeditation(
  BuildContext context, {
  required MeditationType type,
  required int minutes,
  int? fromDay,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MeditationPlayerScreen(
        type: type,
        minutes: minutes,
        fromDay: fromDay,
      ),
    ),
  );
}

Future<void> openTree(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const TreeScreen()),
  );
}

Future<void> openEmotions(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const EmotionsScreen()),
  );
}

Future<void> openChallenges(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const ChallengesScreen()),
  );
}
