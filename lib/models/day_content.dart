import 'life_stage.dart';

String _str(Map<String, dynamic> json, String key, [String fallback = '']) {
  final value = json[key];
  return value is String ? value : fallback;
}

int _int(Map<String, dynamic> json, String key, [int fallback = 0]) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

Map<String, dynamic> _map(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<dynamic> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is List ? value : const <dynamic>[];
}

/// Tipos de interacción disponibles en las sesiones diarias.
enum InteractionType {
  singleChoice,
  multiChoice,
  freeText,
  scale,
  fields,
  control,
  breathing,
  visualization,
  habitReview,
  futureLetter,
  futureMessage,
  letterReply;

  static InteractionType fromKey(String key) {
    for (final type in InteractionType.values) {
      if (type.name == key) {
        return type;
      }
    }
    return InteractionType.freeText;
  }

  /// Si la interacción produce texto libre que conviene revisar con
  /// el servicio de respuesta segura.
  bool get hasFreeText => !_nonTextTypes.contains(this);

  static const Set<InteractionType> _nonTextTypes = <InteractionType>{
    InteractionType.singleChoice,
    InteractionType.multiChoice,
    InteractionType.scale,
    InteractionType.breathing,
  };
}

class ChoiceOption {
  const ChoiceOption({required this.label, this.feedback = ''});

  final String label;
  final String feedback;

  factory ChoiceOption.fromJson(Map<String, dynamic> json) {
    return ChoiceOption(
      label: _str(json, 'label'),
      feedback: _str(json, 'feedback'),
    );
  }
}

class FieldSpec {
  const FieldSpec({required this.label, this.placeholder = ''});

  final String label;
  final String placeholder;

  factory FieldSpec.fromJson(Map<String, dynamic> json) {
    return FieldSpec(
      label: _str(json, 'label'),
      placeholder: _str(json, 'placeholder'),
    );
  }
}

class DayInteraction {
  const DayInteraction({
    required this.type,
    required this.prompt,
    this.placeholder = '',
    this.hint = '',
    this.choices = const <ChoiceOption>[],
    this.items = const <String>[],
    this.max = 1,
    this.minLabel = '',
    this.maxLabel = '',
    this.lowFeedback = '',
    this.midFeedback = '',
    this.highFeedback = '',
    this.fields = const <FieldSpec>[],
    this.minFilled = 1,
    this.cycles = 4,
    this.mantra = '',
    this.seconds = 60,
    this.steps = const <String>[],
    this.minLength = 3,
  });

  final InteractionType type;
  final String prompt;
  final String placeholder;
  final String hint;

  /// Opciones con retroalimentación (selección única y control).
  final List<ChoiceOption> choices;

  /// Opciones simples (selección múltiple) o hábitos (revisión de hábitos).
  final List<String> items;
  final int max;
  final String minLabel;
  final String maxLabel;
  final String lowFeedback;
  final String midFeedback;
  final String highFeedback;
  final List<FieldSpec> fields;
  final int minFilled;
  final int cycles;
  final String mantra;
  final int seconds;
  final List<String> steps;
  final int minLength;

  String feedbackForScale(int value) {
    if (value <= 3) {
      return lowFeedback;
    }
    if (value <= 7) {
      return midFeedback;
    }
    return highFeedback;
  }

  factory DayInteraction.fromJson(Map<String, dynamic> json) {
    final type = InteractionType.fromKey(_str(json, 'type'));
    final rawOptions = _list(json, 'options');
    final choices = <ChoiceOption>[];
    final items = <String>[];
    for (final option in rawOptions) {
      if (option is Map) {
        choices.add(ChoiceOption.fromJson(Map<String, dynamic>.from(option)));
      } else if (option is String) {
        items.add(option);
      }
    }
    for (final habit in _list(json, 'habits')) {
      if (habit is String) {
        items.add(habit);
      }
    }
    final fields = <FieldSpec>[];
    for (final field in _list(json, 'fields')) {
      if (field is Map) {
        fields.add(FieldSpec.fromJson(Map<String, dynamic>.from(field)));
      }
    }
    final steps = <String>[];
    for (final step in _list(json, 'steps')) {
      if (step is String) {
        steps.add(step);
      }
    }
    return DayInteraction(
      type: type,
      prompt: _str(json, 'prompt'),
      placeholder: _str(json, 'placeholder'),
      hint: _str(json, 'hint'),
      choices: choices,
      items: items,
      max: _int(json, 'max', 1),
      minLabel: _str(json, 'minLabel'),
      maxLabel: _str(json, 'maxLabel'),
      lowFeedback: _str(json, 'low'),
      midFeedback: _str(json, 'mid'),
      highFeedback: _str(json, 'high'),
      fields: fields,
      minFilled: _int(json, 'minFilled', 1),
      cycles: _int(json, 'cycles', 4),
      mantra: _str(json, 'mantra'),
      seconds: _int(json, 'seconds', 60),
      steps: steps,
      minLength: _int(json, 'minLength', 3),
    );
  }
}

/// Texto con variaciones por etapa de vida.
class StageText {
  const StageText(this.values, {this.fallback = ''});

  final Map<String, String> values;
  final String fallback;

  String forStage(LifeStage stage) => values[stage.key] ?? fallback;

  factory StageText.fromJson(Map<String, dynamic> json,
      {String fallback = ''}) {
    final values = <String, String>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is String) {
        values[entry.key] = value;
      }
    }
    return StageText(values, fallback: fallback);
  }
}

class ChallengeContent {
  const ChallengeContent({
    required this.title,
    required this.base,
    required this.stages,
  });

  final String title;
  final String base;
  final StageText stages;

  String textFor(LifeStage stage) {
    final text = stages.forStage(stage);
    return text.isEmpty ? base : text;
  }

  factory ChallengeContent.fromJson(Map<String, dynamic> json) {
    final base = _str(json, 'base');
    return ChallengeContent(
      title: _str(json, 'title'),
      base: base,
      stages: StageText.fromJson(_map(json, 'stages'), fallback: base),
    );
  }
}

class MeditationSuggestion {
  const MeditationSuggestion({
    required this.type,
    required this.minutes,
    required this.label,
  });

  final String type;
  final int minutes;
  final String label;

  factory MeditationSuggestion.fromJson(Map<String, dynamic> json) {
    return MeditationSuggestion(
      type: _str(json, 'type', 'breathing'),
      minutes: _int(json, 'minutes', 3),
      label: _str(json, 'label'),
    );
  }
}

class DayReward {
  const DayReward({required this.xp, required this.label});

  final int xp;
  final String label;

  factory DayReward.fromJson(Map<String, dynamic> json) {
    return DayReward(
      xp: _int(json, 'xp', 100),
      label: _str(json, 'label', 'Estrella'),
    );
  }
}

/// Contenido completo de un día del viaje.
class DayContent {
  const DayContent({
    required this.day,
    required this.title,
    required this.constellationId,
    required this.rootId,
    required this.theme,
    required this.objective,
    required this.minutes,
    required this.intro,
    required this.teaching,
    required this.philosophySource,
    required this.philosophyIdea,
    required this.question,
    required this.interaction,
    required this.examples,
    required this.challenge,
    required this.meditation,
    required this.ambient,
    required this.reward,
    required this.closing,
    this.recallDay,
  });

  final int day;
  final String title;
  final String constellationId;
  final String rootId;
  final String theme;
  final String objective;
  final int minutes;
  final String intro;
  final String teaching;
  final String philosophySource;
  final String philosophyIdea;
  final String question;
  final DayInteraction interaction;
  final StageText examples;
  final ChallengeContent challenge;
  final MeditationSuggestion meditation;
  final String ambient;
  final DayReward reward;
  final String closing;

  /// Día anterior cuya respuesta se recuerda en este día (continuidad).
  final int? recallDay;

  factory DayContent.fromJson(Map<String, dynamic> json) {
    final philosophy = _map(json, 'philosophy');
    final recall = json['recallDay'];
    return DayContent(
      day: _int(json, 'day'),
      title: _str(json, 'title'),
      constellationId: _str(json, 'constellation'),
      rootId: _str(json, 'root'),
      theme: _str(json, 'theme'),
      objective: _str(json, 'objective'),
      minutes: _int(json, 'minutes', 5),
      intro: _str(json, 'intro'),
      teaching: _str(json, 'teaching'),
      philosophySource: _str(philosophy, 'source'),
      philosophyIdea: _str(philosophy, 'idea'),
      question: _str(json, 'question'),
      interaction: DayInteraction.fromJson(_map(json, 'interaction')),
      examples: StageText.fromJson(_map(json, 'examples')),
      challenge: ChallengeContent.fromJson(_map(json, 'challenge')),
      meditation: MeditationSuggestion.fromJson(_map(json, 'meditation')),
      ambient: _str(json, 'ambient', 'rain'),
      reward: DayReward.fromJson(_map(json, 'reward')),
      closing: _str(json, 'closing'),
      recallDay: recall is int ? recall : null,
    );
  }
}

class ConstellationInfo {
  const ConstellationInfo({
    required this.id,
    required this.name,
    required this.firstDay,
    required this.lastDay,
    required this.subtitle,
    required this.milestoneTitle,
    required this.milestoneReflection,
    required this.treeUnlock,
  });

  final String id;
  final String name;
  final int firstDay;
  final int lastDay;
  final String subtitle;
  final String milestoneTitle;
  final String milestoneReflection;
  final String treeUnlock;

  bool contains(int day) => day >= firstDay && day <= lastDay;

  int get length => lastDay - firstDay + 1;

  factory ConstellationInfo.fromJson(Map<String, dynamic> json) {
    return ConstellationInfo(
      id: _str(json, 'id'),
      name: _str(json, 'name'),
      firstDay: _int(json, 'firstDay'),
      lastDay: _int(json, 'lastDay'),
      subtitle: _str(json, 'subtitle'),
      milestoneTitle: _str(json, 'milestoneTitle'),
      milestoneReflection: _str(json, 'milestoneReflection'),
      treeUnlock: _str(json, 'treeUnlock'),
    );
  }
}

class RootInfo {
  const RootInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.reflection,
  });

  final String id;
  final String name;
  final String description;
  final String reflection;

  factory RootInfo.fromJson(Map<String, dynamic> json) {
    return RootInfo(
      id: _str(json, 'id'),
      name: _str(json, 'name'),
      description: _str(json, 'description'),
      reflection: _str(json, 'reflection'),
    );
  }
}

/// Todo el contenido del viaje, separado del diseño.
class JourneyContent {
  const JourneyContent({
    required this.constellations,
    required this.roots,
    required this.days,
    required this.absenceMessage,
    required this.finalQuestion,
    required this.finalMessage,
  });

  final List<ConstellationInfo> constellations;
  final List<RootInfo> roots;
  final List<DayContent> days;
  final String absenceMessage;
  final String finalQuestion;
  final String finalMessage;

  int get totalDays => days.length;

  DayContent day(int number) {
    return days.firstWhere(
      (d) => d.day == number,
      orElse: () => days.first,
    );
  }

  ConstellationInfo constellationForDay(int day) {
    return constellations.firstWhere(
      (c) => c.contains(day),
      orElse: () => constellations.last,
    );
  }

  ConstellationInfo constellationById(String id) {
    return constellations.firstWhere(
      (c) => c.id == id,
      orElse: () => constellations.first,
    );
  }

  RootInfo rootById(String id) {
    return roots.firstWhere(
      (r) => r.id == id,
      orElse: () => roots.first,
    );
  }

  List<int> daysForRoot(String rootId) {
    return <int>[
      for (final d in days)
        if (d.rootId == rootId) d.day,
    ];
  }

  factory JourneyContent.fromJson(Map<String, dynamic> json) {
    final constellations = <ConstellationInfo>[];
    for (final item in _list(json, 'constellations')) {
      if (item is Map) {
        constellations.add(
          ConstellationInfo.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
    final roots = <RootInfo>[];
    for (final item in _list(json, 'roots')) {
      if (item is Map) {
        roots.add(RootInfo.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    final days = <DayContent>[];
    for (final item in _list(json, 'days')) {
      if (item is Map) {
        days.add(DayContent.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    days.sort((a, b) => a.day.compareTo(b.day));
    return JourneyContent(
      constellations: constellations,
      roots: roots,
      days: days,
      absenceMessage: _str(
        json,
        'absenceMessage',
        'Tu recorrido no desapareció. Puedes continuar hoy.',
      ),
      finalQuestion: _str(json, 'finalQuestion'),
      finalMessage:
          _str(json, 'finalMessage', 'Este no es el final de tu viaje.'),
    );
  }
}
