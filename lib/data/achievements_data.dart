import '../models/achievement.dart';

/// Identificadores estables de insignias.
class AchievementIds {
  const AchievementIds._();

  static const String firstStep = 'primer_paso';
  static const String sevenDays = 'siete_dias';
  static const String firstRoot = 'primera_raiz';
  static const String firstConstellation = 'primera_constelacion';
  static const String strength = 'fortaleza';
  static const String action = 'accion';
  static const String twentyOneDays = 'veintiun_dias';
  static const String journeyComplete = 'viaje_completo';
  static const String letterRevealed = 'carta_revelada';
  static const String calmSeed = 'semilla_calma';
  static const String smallAction = 'pequena_accion';
  static const String beginAgain = 'vuelvo_a_empezar';
  static const String allRoots = 'siete_raices';
}

/// Catálogo de insignias. Nunca se pierden al perder una racha.
const List<Achievement> achievementCatalog = <Achievement>[
  Achievement(
    id: AchievementIds.firstStep,
    title: 'Primer paso',
    description: 'Completaste el Día 1 y encendiste tu primera estrella.',
  ),
  Achievement(
    id: AchievementIds.sevenDays,
    title: '7 días',
    description: 'Una semana completa de viaje.',
  ),
  Achievement(
    id: AchievementIds.firstRoot,
    title: 'Primera raíz',
    description: 'Iluminaste por completo una de tus 7 raíces.',
  ),
  Achievement(
    id: AchievementIds.firstConstellation,
    title: 'Primera constelación',
    description: 'Formaste la Constelación Origen.',
  ),
  Achievement(
    id: AchievementIds.strength,
    title: 'Fortaleza',
    description: 'Formaste la Constelación Fortaleza.',
  ),
  Achievement(
    id: AchievementIds.action,
    title: 'Acción',
    description: 'Formaste la Constelación Acción.',
  ),
  Achievement(
    id: AchievementIds.twentyOneDays,
    title: '21 días',
    description: 'Tres semanas sosteniendo tu viaje.',
  ),
  Achievement(
    id: AchievementIds.journeyComplete,
    title: 'Completaste el viaje',
    description: 'Encendiste las 30 estrellas.',
  ),
  Achievement(
    id: AchievementIds.letterRevealed,
    title: 'Carta revelada',
    description: 'Leíste la carta de tu yo del Día 1.',
  ),
  Achievement(
    id: AchievementIds.calmSeed,
    title: 'Semilla de calma',
    description: 'Completaste tu primera meditación.',
  ),
  Achievement(
    id: AchievementIds.smallAction,
    title: 'Pequeña acción',
    description: 'Completaste tu primer microreto.',
  ),
  Achievement(
    id: AchievementIds.beginAgain,
    title: 'Vuelvo a empezar',
    description: 'Regresaste después de una pausa. Volver también es avanzar.',
  ),
  Achievement(
    id: AchievementIds.allRoots,
    title: 'Siete raíces',
    description: 'Iluminaste las 7 raíces de tu árbol.',
  ),
];
