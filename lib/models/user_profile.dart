import 'life_stage.dart';

/// Perfil local y anónimo. No contiene nombre, correo ni datos de contacto.
class UserProfile {
  const UserProfile({
    this.onboardingCompleted = false,
    this.stage,
    this.goal,
    this.createdAt,
  });

  final bool onboardingCompleted;
  final LifeStage? stage;
  final String? goal;
  final DateTime? createdAt;

  /// Etapa usada para adaptar contenido. Si no se eligió, se usa 18–30.
  LifeStage get effectiveStage => stage ?? LifeStage.young;

  UserProfile copyWith({
    bool? onboardingCompleted,
    LifeStage? stage,
    String? goal,
    bool clearGoal = false,
    DateTime? createdAt,
  }) {
    return UserProfile(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      stage: stage ?? this.stage,
      goal: clearGoal ? null : (goal ?? this.goal),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'onboardingCompleted': onboardingCompleted,
        'stage': stage?.key,
        'goal': goal,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return UserProfile(
      onboardingCompleted: json['onboardingCompleted'] == true,
      stage: LifeStage.fromKey(json['stage'] as String?),
      goal: json['goal'] as String?,
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }
}
