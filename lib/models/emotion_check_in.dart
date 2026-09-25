/// Emociones disponibles en el check-in. No son categorías clínicas.
enum Emotion {
  happy('Feliz', EmotionTone.pleasant),
  calm('Tranquilo', EmotionTone.pleasant),
  motivated('Motivado', EmotionTone.pleasant),
  tired('Cansado', EmotionTone.neutral),
  anxious('Ansioso', EmotionTone.difficult),
  sad('Triste', EmotionTone.difficult),
  confused('Confundido', EmotionTone.neutral),
  angry('Enojado', EmotionTone.difficult),
  hopeful('Esperanzado', EmotionTone.pleasant),
  other('Otro', EmotionTone.neutral);

  const Emotion(this.label, this.tone);

  final String label;
  final EmotionTone tone;

  static Emotion fromKey(String? key) {
    for (final e in Emotion.values) {
      if (e.name == key) {
        return e;
      }
    }
    return Emotion.other;
  }
}

/// Tono general de la emoción, usado solo para adaptar mensajes del guía.
enum EmotionTone { pleasant, neutral, difficult }

class EmotionCheckIn {
  const EmotionCheckIn({
    required this.id,
    required this.date,
    required this.emotion,
    required this.intensity,
    this.note = '',
    this.journeyDay,
  });

  final String id;
  final DateTime date;
  final Emotion emotion;

  /// Intensidad de 0 a 10.
  final int intensity;
  final String note;
  final int? journeyDay;

  /// Valida que la intensidad esté en el rango permitido.
  static bool isValidIntensity(int value) => value >= 0 && value <= 10;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date.toIso8601String(),
        'emotion': emotion.name,
        'intensity': intensity,
        'note': note,
        'journeyDay': journeyDay,
      };

  factory EmotionCheckIn.fromJson(Map<String, dynamic> json) {
    final rawIntensity = (json['intensity'] as num?)?.toInt() ?? 0;
    return EmotionCheckIn(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      emotion: Emotion.fromKey(json['emotion'] as String?),
      intensity: rawIntensity.clamp(0, 10).toInt(),
      note: json['note'] as String? ?? '',
      journeyDay: (json['journeyDay'] as num?)?.toInt(),
    );
  }
}
