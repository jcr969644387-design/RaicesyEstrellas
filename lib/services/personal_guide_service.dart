import '../models/emotion_check_in.dart';
import '../models/life_stage.dart';
import '../models/micro_challenge.dart';

/// Contexto que el guía local usa para elegir un mensaje.
class GuideContext {
  const GuideContext({
    required this.currentDay,
    required this.totalDays,
    required this.completedCount,
    required this.constellationName,
    required this.rootName,
    required this.streak,
    required this.stage,
    this.lastEmotion,
    this.lastIntensity,
    this.returningAfterAbsence = false,
    this.pendingChallenge,
    this.journeyComplete = false,
    this.hour = 12,
  });

  final int currentDay;
  final int totalDays;
  final int completedCount;
  final String constellationName;
  final String rootName;
  final int streak;
  final LifeStage stage;
  final Emotion? lastEmotion;
  final int? lastIntensity;
  final bool returningAfterAbsence;
  final MicroChallenge? pendingChallenge;
  final bool journeyComplete;
  final int hour;
}

/// Guía personal basado en reglas locales. Sin IA externa ni Internet.
/// Es breve, empático y nunca da consejo clínico.
class PersonalGuideService {
  const PersonalGuideService();

  static const String absenceMessage =
      'Tu recorrido no desapareció. Puedes continuar hoy.';

  /// Saludo según la hora local.
  String greeting(int hour) {
    if (hour < 6) {
      return 'Buenas noches';
    }
    if (hour < 12) {
      return 'Buenos días';
    }
    if (hour < 19) {
      return 'Buenas tardes';
    }
    return 'Buenas noches';
  }

  /// Mensaje principal del guía.
  String message(GuideContext c) {
    if (c.journeyComplete) {
      return 'Este no es el final de tu viaje. Puedes seguir escribiendo, '
          'meditando y volviendo a ti cuando lo necesites.';
    }
    if (c.returningAfterAbsence) {
      return absenceMessage;
    }
    final emotion = c.lastEmotion;
    final intensity = c.lastIntensity ?? 0;
    if (emotion != null &&
        emotion.tone == EmotionTone.difficult &&
        intensity >= 7) {
      return 'Hoy puede ser un día para ir más despacio. '
          'Pausa está aquí cuando la necesites.';
    }
    if (c.completedCount == 0) {
      return _firstDayMessage(c.stage);
    }
    if (_isMilestoneDay(c.currentDay, c.totalDays)) {
      return 'Hoy puedes completar la ${c.constellationName}. '
          'Una estrella más y se encenderá entera.';
    }
    if (emotion != null && emotion.tone == EmotionTone.difficult) {
      return 'Gracias por ser honesto contigo. '
          'Hoy basta con dar un paso pequeño.';
    }
    if (emotion == Emotion.tired) {
      return 'El cansancio también merece respeto. '
          'Una sesión breve cuenta tanto como una larga.';
    }
    final pending = c.pendingChallenge;
    if (pending != null) {
      return 'Tu microreto «${pending.title}» sigue ahí, sin prisa. '
          'Puedes hacerlo cuando te venga bien.';
    }
    if (c.streak >= 3) {
      return 'Estás construyendo constancia. ${_stageNote(c.stage)}';
    }
    if (emotion != null && emotion.tone == EmotionTone.pleasant) {
      return 'Qué bueno verte con esa energía. '
          'Hoy trabajas tu raíz de ${c.rootName}.';
    }
    final note = _stageNote(c.stage);
    return 'Hoy tu raíz de ${c.rootName} sigue creciendo. $note';
  }

  /// Mensaje breve tras completar un día.
  String completionMessage(int day, int totalDays, int streak) {
    if (day >= totalDays) {
      return 'Completaste tu viaje. Mira todo lo que construiste.';
    }
    if (day == 1) {
      return 'Diste el primer paso. Eso es lo más difícil.';
    }
    if (streak >= 3) {
      return 'Estás construyendo constancia.';
    }
    return 'Una estrella más brilla en tu cielo.';
  }

  /// Reacción amable al check-in emocional. Nunca clasifica clínicamente.
  String checkInResponse(Emotion emotion, int intensity) {
    switch (emotion.tone) {
      case EmotionTone.pleasant:
        return 'Qué bien. Aprovecha esa energía con calma.';
      case EmotionTone.neutral:
        if (emotion == Emotion.tired) {
          return 'Gracias por notarlo. Hoy puedes ir a tu ritmo.';
        }
        return 'Gracias por registrarlo. Nombrar lo que sientes ya ayuda.';
      case EmotionTone.difficult:
        if (intensity >= 7) {
          return 'Gracias por ser honesto contigo. Puedes usar Pausa '
              'en cualquier momento y avanzar solo lo que puedas.';
        }
        return 'Gracias por ser honesto contigo. Este espacio es para ti.';
    }
  }

  bool _isMilestoneDay(int day, int total) =>
      day == 7 || day == 14 || day == 21 || day == total;

  String _firstDayMessage(LifeStage stage) {
    switch (stage) {
      case LifeStage.teen:
        return 'Este viaje es tuyo. No hay respuestas correctas, '
            'solo curiosidad por conocerte.';
      case LifeStage.young:
        return 'Treinta días para descubrir lo que puedes construir. '
            'Empieza con un paso pequeño.';
      case LifeStage.adult:
        return 'Unos minutos al día para ti también cuentan. '
            'Empieza cuando estés listo.';
      case LifeStage.senior:
        return 'Toda etapa es buena para seguir descubriéndote. '
            'Tu viaje comienza hoy.';
    }
  }

  String _stageNote(LifeStage stage) {
    switch (stage) {
      case LifeStage.teen:
        return 'Vas a tu ritmo, y eso está bien.';
      case LifeStage.young:
        return 'Cada paso pequeño suma.';
      case LifeStage.adult:
        return 'Unos minutos para ti también son importantes.';
      case LifeStage.senior:
        return 'La calma también es una forma de avanzar.';
    }
  }
}
