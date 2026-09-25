/// Tipo de entrada del diario.
enum JournalKind {
  free('Libre'),
  guided('Respuesta guiada'),
  letter('Carta');

  const JournalKind(this.label);

  final String label;

  static JournalKind fromKey(String? key) {
    for (final k in JournalKind.values) {
      if (k.name == key) {
        return k;
      }
    }
    return JournalKind.free;
  }
}

/// Entrada privada del diario. Solo se guarda en el dispositivo.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.text,
    this.title = '',
    this.tags = const <String>[],
    this.day,
    this.kind = JournalKind.free,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String text;
  final List<String> tags;
  final int? day;
  final JournalKind kind;

  /// Una entrada es válida si tiene algo de contenido.
  bool get isValid => text.trim().isNotEmpty || title.trim().isNotEmpty;

  JournalEntry copyWith({
    DateTime? updatedAt,
    String? title,
    String? text,
    List<String>? tags,
    int? day,
    bool clearDay = false,
    JournalKind? kind,
  }) {
    return JournalEntry(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      text: text ?? this.text,
      tags: tags ?? this.tags,
      day: clearDay ? null : (day ?? this.day),
      kind: kind ?? this.kind,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'title': title,
        'text': text,
        'tags': tags,
        'day': day,
        'kind': kind.name,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final created =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    final rawTags = json['tags'];
    return JournalEntry(
      id: json['id'] as String? ?? '',
      createdAt: created,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? created,
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      tags: rawTags is List
          ? <String>[
              for (final t in rawTags)
                if (t is String) t,
            ]
          : const <String>[],
      day: (json['day'] as num?)?.toInt(),
      kind: JournalKind.fromKey(json['kind'] as String?),
    );
  }
}
