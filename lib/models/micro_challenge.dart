/// Estado de un microreto. Omitirlo nunca penaliza.
enum ChallengeStatus {
  pending('Pendiente'),
  completed('Completado'),
  skipped('Omitido');

  const ChallengeStatus(this.label);

  final String label;

  static ChallengeStatus fromKey(String? key) {
    for (final s in ChallengeStatus.values) {
      if (s.name == key) {
        return s;
      }
    }
    return ChallengeStatus.pending;
  }
}

class MicroChallenge {
  const MicroChallenge({
    required this.day,
    required this.title,
    required this.text,
    this.status = ChallengeStatus.pending,
    this.updatedAt,
  });

  final int day;
  final String title;
  final String text;
  final ChallengeStatus status;
  final DateTime? updatedAt;

  MicroChallenge copyWith({ChallengeStatus? status, DateTime? updatedAt}) {
    return MicroChallenge(
      day: day,
      title: title,
      text: text,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'day': day,
        'title': title,
        'text': text,
        'status': status.name,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory MicroChallenge.fromJson(Map<String, dynamic> json) {
    final updated = json['updatedAt'];
    return MicroChallenge(
      day: (json['day'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      status: ChallengeStatus.fromKey(json['status'] as String?),
      updatedAt: updated is String ? DateTime.tryParse(updated) : null,
    );
  }
}
