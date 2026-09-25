import '../models/meditation_session.dart';

/// Patrón de respiración en segundos.
class BreathingPattern {
  const BreathingPattern({
    required this.inhale,
    required this.hold,
    required this.exhale,
  });

  final int inhale;
  final int hold;
  final int exhale;

  int get cycleSeconds => inhale + hold + exhale;
}

/// Patrón general, suave y seguro para la mayoría de personas.
const BreathingPattern calmBreathing = BreathingPattern(
  inhale: 4,
  hold: 4,
  exhale: 6,
);

/// Patrón más corto para meditaciones de concentración o activación.
const BreathingPattern lightBreathing = BreathingPattern(
  inhale: 4,
  hold: 2,
  exhale: 4,
);

BreathingPattern patternFor(MeditationType type) {
  switch (type) {
    case MeditationType.focus:
    case MeditationType.morning:
    case MeditationType.confidence:
      return lightBreathing;
    case MeditationType.breathing:
    case MeditationType.relaxation:
    case MeditationType.gratitude:
    case MeditationType.selfAcceptance:
    case MeditationType.sleep:
      return calmBreathing;
  }
}

/// Indicaciones de texto que se muestran a lo largo de la sesión.
const Map<MeditationType, List<String>> meditationGuides =
    <MeditationType, List<String>>{
  MeditationType.breathing: <String>[
    'Encuentra una postura cómoda.',
    'Sigue el círculo con tu respiración.',
    'Si tu mente se va, vuelve al aire que entra y sale.',
    'No hay nada que lograr. Solo respirar.',
    'Nota cómo el cuerpo se suaviza con cada exhalación.',
  ],
  MeditationType.relaxation: <String>[
    'Afloja la frente y la mandíbula.',
    'Deja caer los hombros.',
    'Suelta las manos y los brazos.',
    'Siente el peso de tu cuerpo apoyado.',
    'Relaja las piernas y los pies.',
    'Todo tu cuerpo puede descansar un momento.',
  ],
  MeditationType.focus: <String>[
    'Elige un punto de atención: tu respiración.',
    'Cuenta cada exhalación, del uno al diez.',
    'Si pierdes la cuenta, vuelve a empezar sin juzgarte.',
    'Volver es el verdadero ejercicio.',
    'Tu atención es como un músculo: se fortalece al volver.',
  ],
  MeditationType.gratitude: <String>[
    'Trae a tu mente algo sencillo que agradeces.',
    'Puede ser una persona, un lugar o un momento.',
    'Nota qué sientes en el cuerpo al recordarlo.',
    'Agradece también algo de ti.',
    'Deja que esa sensación te acompañe unos segundos más.',
  ],
  MeditationType.confidence: <String>[
    'Recuerda un momento en que lograste algo difícil.',
    '¿Qué cualidades usaste en ese momento?',
    'Esas cualidades siguen en ti.',
    'Respira como alguien que confía en sus pasos.',
    'No necesitas certeza total para avanzar.',
  ],
  MeditationType.selfAcceptance: <String>[
    'Coloca una mano sobre el pecho si te resulta cómodo.',
    'Reconoce cómo estás, sin intentar cambiarlo.',
    'Dite en silencio: «Estoy haciendo lo mejor que puedo».',
    'Eres una persona en crecimiento, no un proyecto terminado.',
    'Puedes tratarte con la amabilidad que ofreces a otros.',
  ],
  MeditationType.sleep: <String>[
    'El día ya terminó. Ya no hay nada que resolver ahora.',
    'Deja que cada exhalación sea un poco más larga.',
    'Suelta lo que pasó hoy, como hojas que se lleva el agua.',
    'Tu cuerpo sabe descansar.',
    'Mañana será otro día y lo recibirás cuando llegue.',
  ],
  MeditationType.morning: <String>[
    'Siente cómo despierta tu cuerpo.',
    'Elige una intención sencilla para hoy.',
    '¿Cómo quieres tratarte hoy?',
    'Imagina un pequeño momento del día saliendo bien.',
    'Empieza con calma. Hay tiempo.',
  ],
};

/// Frases breves de apoyo para la sección Pausa.
const List<String> pausePhrases = <String>[
  'Estás aquí. Eso es suficiente por ahora.',
  'No tienes que resolver todo en este momento.',
  'Respira. Este momento también pasará.',
  'Puedes ir más despacio.',
  'Tu cuerpo sabe volver a la calma.',
  'Suelta un poco los hombros.',
  'Un paso a la vez.',
  'Te estás cuidando al detenerte.',
];
