/// Tipos de meditación de la sección Medítate.
enum MeditationType {
  breathing(
      'breathing', 'Respiración', 'Ritmo 4 · 4 · 6 para calmar el cuerpo'),
  relaxation('relaxation', 'Relajación', 'Soltar tensión parte por parte'),
  focus('focus', 'Concentración', 'Volver una y otra vez al presente'),
  gratitude('gratitude', 'Gratitud', 'Reconocer lo que sí está bien'),
  confidence('confidence', 'Confianza', 'Recordar tus recursos'),
  selfAcceptance(
    'selfAcceptance',
    'Autoaceptación',
    'Mirarte con amabilidad',
  ),
  sleep('sleep', 'Antes de dormir', 'Cerrar el día con suavidad'),
  morning('morning', 'Preparación para el día', 'Empezar con intención');

  const MeditationType(this.key, this.label, this.description);

  final String key;
  final String label;
  final String description;

  static MeditationType fromKey(String? key) {
    for (final t in MeditationType.values) {
      if (t.key == key) {
        return t;
      }
    }
    return MeditationType.breathing;
  }
}

/// Duraciones disponibles en minutos.
const List<int> meditationDurations = <int>[1, 3, 5, 10];

class MeditationSession {
  const MeditationSession({
    required this.id,
    required this.type,
    required this.minutes,
    required this.completedAt,
    this.fromDay,
    this.secondsPracticed = 0,
  });

  final String id;
  final MeditationType type;
  final int minutes;
  final DateTime completedAt;
  final int? fromDay;
  final int secondsPracticed;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.key,
        'minutes': minutes,
        'completedAt': completedAt.toIso8601String(),
        'fromDay': fromDay,
        'secondsPracticed': secondsPracticed,
      };

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      id: json['id'] as String? ?? '',
      type: MeditationType.fromKey(json['type'] as String?),
      minutes: (json['minutes'] as num?)?.toInt() ?? 1,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      fromDay: (json['fromDay'] as num?)?.toInt(),
      secondsPracticed: (json['secondsPracticed'] as num?)?.toInt() ?? 0,
    );
  }
}
