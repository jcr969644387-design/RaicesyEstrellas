/// Último estado conocido del permiso de notificaciones.
enum NotificationPermission {
  unknown('Sin solicitar'),
  granted('Concedido'),
  denied('Rechazado');

  const NotificationPermission(this.label);

  final String label;

  static NotificationPermission fromKey(String? key) {
    for (final p in NotificationPermission.values) {
      if (p.name == key) {
        return p;
      }
    }
    return NotificationPermission.unknown;
  }
}

/// Configuración del recordatorio diario local.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
    this.permission = NotificationPermission.unknown,
  });

  final bool enabled;
  final int hour;
  final int minute;
  final NotificationPermission permission;

  static bool isValidTime(int hour, int minute) =>
      hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;

  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    NotificationPermission? permission,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      permission: permission ?? this.permission,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
        'permission': permission.name,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    final hour = (json['hour'] as num?)?.toInt() ?? 20;
    final minute = (json['minute'] as num?)?.toInt() ?? 0;
    final valid = isValidTime(hour, minute);
    return ReminderSettings(
      enabled: json['enabled'] == true,
      hour: valid ? hour : 20,
      minute: valid ? minute : 0,
      permission: NotificationPermission.fromKey(json['permission'] as String?),
    );
  }
}
