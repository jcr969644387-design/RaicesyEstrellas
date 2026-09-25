/// Estado visual de un día del viaje.
enum DayStatus {
  locked('Bloqueado'),
  available('Disponible'),
  inProgress('En progreso'),
  completed('Completado');

  const DayStatus(this.label);

  final String label;
}

/// Respuestas y marcas de tiempo de un día concreto.
class DailyProgress {
  const DailyProgress({
    required this.day,
    this.startedAt,
    this.completedAt,
    this.choice,
    this.choices = const <String>[],
    this.text,
    this.fields = const <String>[],
    this.scale,
    this.marks = const <String, String>{},
    this.interactionDone = false,
  });

  final int day;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? choice;
  final List<String> choices;
  final String? text;
  final List<String> fields;
  final int? scale;
  final Map<String, String> marks;

  /// Para interacciones sin texto (respiración, visualización).
  final bool interactionDone;

  bool get hasAnswer =>
      (choice != null && choice!.isNotEmpty) ||
      choices.isNotEmpty ||
      (text != null && text!.trim().isNotEmpty) ||
      fields.any((f) => f.trim().isNotEmpty) ||
      scale != null ||
      marks.isNotEmpty ||
      interactionDone;

  /// Resumen legible de la respuesta, útil para recordar días anteriores.
  String get summary {
    final parts = <String>[];
    if (choice != null && choice!.isNotEmpty) {
      parts.add(choice!);
    }
    if (choices.isNotEmpty) {
      parts.add(choices.join(', '));
    }
    for (final f in fields) {
      if (f.trim().isNotEmpty) {
        parts.add(f.trim());
      }
    }
    if (text != null && text!.trim().isNotEmpty) {
      parts.add(text!.trim());
    }
    if (scale != null) {
      parts.add('Valor: $scale/10');
    }
    return parts.join(' · ');
  }

  DailyProgress copyWith({
    DateTime? startedAt,
    DateTime? completedAt,
    String? choice,
    List<String>? choices,
    String? text,
    List<String>? fields,
    int? scale,
    Map<String, String>? marks,
    bool? interactionDone,
  }) {
    return DailyProgress(
      day: day,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      choice: choice ?? this.choice,
      choices: choices ?? this.choices,
      text: text ?? this.text,
      fields: fields ?? this.fields,
      scale: scale ?? this.scale,
      marks: marks ?? this.marks,
      interactionDone: interactionDone ?? this.interactionDone,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'day': day,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'choice': choice,
        'choices': choices,
        'text': text,
        'fields': fields,
        'scale': scale,
        'marks': marks,
        'interactionDone': interactionDone,
      };

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;
    final rawMarks = json['marks'];
    final marks = <String, String>{};
    if (rawMarks is Map) {
      for (final entry in rawMarks.entries) {
        marks['${entry.key}'] = '${entry.value}';
      }
    }
    return DailyProgress(
      day: (json['day'] as num?)?.toInt() ?? 0,
      startedAt: parseDate(json['startedAt']),
      completedAt: parseDate(json['completedAt']),
      choice: json['choice'] as String?,
      choices: _stringList(json['choices']),
      text: json['text'] as String?,
      fields: _stringList(json['fields']),
      scale: (json['scale'] as num?)?.toInt(),
      marks: marks,
      interactionDone: json['interactionDone'] == true,
    );
  }
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return <String>[
      for (final item in value)
        if (item is String) item,
    ];
  }
  return const <String>[];
}

List<int> _intList(Object? value) {
  if (value is List) {
    return <int>[
      for (final item in value)
        if (item is num) item.toInt(),
    ];
  }
  return const <int>[];
}

/// Resumen de un ciclo anterior, conservado al iniciar un ciclo nuevo.
class CycleSummary {
  const CycleSummary({
    required this.cycle,
    required this.completedDays,
    required this.longestStreak,
    required this.xp,
    this.finishedAt,
    this.declaration,
  });

  final int cycle;
  final int completedDays;
  final int longestStreak;
  final int xp;
  final DateTime? finishedAt;
  final String? declaration;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cycle': cycle,
        'completedDays': completedDays,
        'longestStreak': longestStreak,
        'xp': xp,
        'finishedAt': finishedAt?.toIso8601String(),
        'declaration': declaration,
      };

  factory CycleSummary.fromJson(Map<String, dynamic> json) {
    final finished = json['finishedAt'];
    return CycleSummary(
      cycle: (json['cycle'] as num?)?.toInt() ?? 1,
      completedDays: (json['completedDays'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      finishedAt: finished is String ? DateTime.tryParse(finished) : null,
      declaration: json['declaration'] as String?,
    );
  }
}

/// Estado global del viaje de 30 días. Se guarda localmente.
class JourneyProgress {
  const JourneyProgress({
    this.cycle = 1,
    this.completedDays = const <int>[],
    this.startedDays = const <int>[],
    this.currentDay = 1,
    this.unlockedDay = 1,
    this.lastActivityDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.xp = 0,
    this.day1Letter = '',
    this.day30Reply = '',
    this.finalDeclaration = '',
    this.letterRevealed = false,
    this.journeyCompletedAt,
    this.previousCycles = const <CycleSummary>[],
  });

  final int cycle;
  final List<int> completedDays;
  final List<int> startedDays;
  final int currentDay;
  final int unlockedDay;

  /// Fecha local (yyyy-MM-dd) de la última actividad que sumó a la racha.
  final String? lastActivityDate;
  final int currentStreak;
  final int longestStreak;
  final int xp;
  final String day1Letter;
  final String day30Reply;
  final String finalDeclaration;
  final bool letterRevealed;
  final DateTime? journeyCompletedAt;
  final List<CycleSummary> previousCycles;

  JourneyProgress copyWith({
    int? cycle,
    List<int>? completedDays,
    List<int>? startedDays,
    int? currentDay,
    int? unlockedDay,
    String? lastActivityDate,
    int? currentStreak,
    int? longestStreak,
    int? xp,
    String? day1Letter,
    String? day30Reply,
    String? finalDeclaration,
    bool? letterRevealed,
    DateTime? journeyCompletedAt,
    List<CycleSummary>? previousCycles,
  }) {
    return JourneyProgress(
      cycle: cycle ?? this.cycle,
      completedDays: completedDays ?? this.completedDays,
      startedDays: startedDays ?? this.startedDays,
      currentDay: currentDay ?? this.currentDay,
      unlockedDay: unlockedDay ?? this.unlockedDay,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      xp: xp ?? this.xp,
      day1Letter: day1Letter ?? this.day1Letter,
      day30Reply: day30Reply ?? this.day30Reply,
      finalDeclaration: finalDeclaration ?? this.finalDeclaration,
      letterRevealed: letterRevealed ?? this.letterRevealed,
      journeyCompletedAt: journeyCompletedAt ?? this.journeyCompletedAt,
      previousCycles: previousCycles ?? this.previousCycles,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cycle': cycle,
        'completedDays': completedDays,
        'startedDays': startedDays,
        'currentDay': currentDay,
        'unlockedDay': unlockedDay,
        'lastActivityDate': lastActivityDate,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'xp': xp,
        'day1Letter': day1Letter,
        'day30Reply': day30Reply,
        'finalDeclaration': finalDeclaration,
        'letterRevealed': letterRevealed,
        'journeyCompletedAt': journeyCompletedAt?.toIso8601String(),
        'previousCycles': <Map<String, dynamic>>[
          for (final c in previousCycles) c.toJson(),
        ],
      };

  factory JourneyProgress.fromJson(Map<String, dynamic> json) {
    final completedAt = json['journeyCompletedAt'];
    final cycles = <CycleSummary>[];
    final rawCycles = json['previousCycles'];
    if (rawCycles is List) {
      for (final item in rawCycles) {
        if (item is Map) {
          cycles.add(CycleSummary.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return JourneyProgress(
      cycle: (json['cycle'] as num?)?.toInt() ?? 1,
      completedDays: _intList(json['completedDays']),
      startedDays: _intList(json['startedDays']),
      currentDay: (json['currentDay'] as num?)?.toInt() ?? 1,
      unlockedDay: (json['unlockedDay'] as num?)?.toInt() ?? 1,
      lastActivityDate: json['lastActivityDate'] as String?,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      day1Letter: json['day1Letter'] as String? ?? '',
      day30Reply: json['day30Reply'] as String? ?? '',
      finalDeclaration: json['finalDeclaration'] as String? ?? '',
      letterRevealed: json['letterRevealed'] == true,
      journeyCompletedAt:
          completedAt is String ? DateTime.tryParse(completedAt) : null,
      previousCycles: cycles,
    );
  }
}
