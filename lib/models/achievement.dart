/// Insignia desbloqueable. Una vez obtenida, nunca se pierde.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  Achievement unlock(DateTime when) => Achievement(
        id: id,
        title: title,
        description: description,
        unlockedAt: when,
      );
}
