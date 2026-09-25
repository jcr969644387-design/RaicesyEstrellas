import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/reminder_messages.dart';
import '../models/reminder_settings.dart';
import 'settings_service.dart';

/// Operaciones de plataforma para notificaciones locales.
abstract class ReminderPlatform {
  Future<void> initialize();

  /// Solicita el permiso (Android 13+). Devuelve si quedó concedido.
  Future<bool> requestPermission();

  /// Consulta si las notificaciones están permitidas actualmente.
  Future<bool> permissionGranted();

  Future<bool> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  Future<void> cancel(int id);

  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
  });
}

/// Implementación real con flutter_local_notifications.
/// No usa servidores, push ni Internet: Android programa la alarma localmente.
class LocalNotificationsPlatform implements ReminderPlatform {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'rye_daily_reminder',
      'Recordatorio diario',
      channelDescription: 'Un recordatorio amable para continuar tu viaje.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    tzdata.initializeTimeZones();
    _configureLocalTimeZone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  /// Elige la zona horaria local comparando el desfase actual del dispositivo,
  /// sin depender de servicios externos.
  void _configureLocalTimeZone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final abbreviation = now.timeZoneName;
    tz.Location? byOffset;
    tz.Location? exact;
    for (final location in tz.timeZoneDatabase.locations.values) {
      final zone = location.currentTimeZone;
      if (zone.offset == offset) {
        byOffset ??= location;
        if (zone.abbreviation == abbreviation) {
          exact = location;
          break;
        }
      }
    }
    tz.setLocalLocation(exact ?? byOffset ?? tz.UTC);
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android = _android;
    if (android == null) {
      return false;
    }
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  @override
  Future<bool> permissionGranted() async {
    await initialize();
    final android = _android;
    if (android == null) {
      return false;
    }
    final enabled = await android.areNotificationsEnabled();
    return enabled ?? false;
  }

  @override
  Future<bool> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.cancel(id: id);
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: when,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  @override
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }

  @override
  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
    return true;
  }
}

/// Resultado de una operación de recordatorio.
enum ReminderResult {
  scheduled,
  disabled,
  permissionDenied,
  invalidTime,
  error,
}

/// Gestiona el recordatorio diario local: activar, desactivar, cambiar hora,
/// reintentar permiso y reprogramar al abrir la app.
class NotificationService {
  NotificationService(this._platform, this._settingsService)
      : _reminder = _settingsService.loadReminder();

  static const int dailyReminderId = 1801;
  static const int testReminderId = 1802;
  static const String title = 'Raíces y Estrellas';

  final ReminderPlatform _platform;
  final SettingsService _settingsService;
  ReminderSettings _reminder;

  ReminderSettings get reminder => _reminder;

  Future<void> _save(ReminderSettings next) async {
    _reminder = next;
    await _settingsService.saveReminder(next);
  }

  /// Revisa permisos y reprograma el recordatorio con un mensaje nuevo.
  Future<void> init() async {
    try {
      await _platform.initialize();
      if (!_reminder.enabled) {
        return;
      }
      final granted = await _platform.permissionGranted();
      if (!granted) {
        await _save(
          _reminder.copyWith(
            enabled: false,
            permission: NotificationPermission.denied,
          ),
        );
        return;
      }
      await _schedule(_reminder.hour, _reminder.minute);
    } catch (e) {
      debugPrint('Recordatorio no disponible: $e');
    }
  }

  Future<bool> _schedule(int hour, int minute) {
    return _platform.scheduleDaily(
      id: dailyReminderId,
      hour: hour,
      minute: minute,
      title: title,
      body: reminderMessageFor(DateTime.now()),
    );
  }

  /// Activa el recordatorio. Solicita permiso si hace falta.
  Future<ReminderResult> enable({int? hour, int? minute}) async {
    final h = hour ?? _reminder.hour;
    final m = minute ?? _reminder.minute;
    if (!ReminderSettings.isValidTime(h, m)) {
      return ReminderResult.invalidTime;
    }
    try {
      final granted = await _platform.requestPermission();
      if (!granted) {
        await _save(
          _reminder.copyWith(
            enabled: false,
            hour: h,
            minute: m,
            permission: NotificationPermission.denied,
          ),
        );
        return ReminderResult.permissionDenied;
      }
      await _schedule(h, m);
      await _save(
        _reminder.copyWith(
          enabled: true,
          hour: h,
          minute: m,
          permission: NotificationPermission.granted,
        ),
      );
      return ReminderResult.scheduled;
    } catch (e) {
      debugPrint('No se pudo programar el recordatorio: $e');
      await _save(_reminder.copyWith(enabled: false));
      return ReminderResult.error;
    }
  }

  /// Desactiva y cancela el recordatorio.
  Future<ReminderResult> disable() async {
    try {
      await _platform.cancel(dailyReminderId);
    } catch (e) {
      debugPrint('No se pudo cancelar el recordatorio: $e');
    }
    await _save(_reminder.copyWith(enabled: false));
    return ReminderResult.disabled;
  }

  /// Cambia la hora. Si el recordatorio está activo, se reprograma.
  Future<ReminderResult> updateTime(int hour, int minute) async {
    if (!ReminderSettings.isValidTime(hour, minute)) {
      return ReminderResult.invalidTime;
    }
    if (!_reminder.enabled) {
      await _save(_reminder.copyWith(hour: hour, minute: minute));
      return ReminderResult.disabled;
    }
    return enable(hour: hour, minute: minute);
  }

  /// Vuelve a pedir el permiso (desde Ajustes).
  Future<ReminderResult> retryPermission() => enable();

  /// Muestra una notificación de prueba inmediata.
  Future<bool> sendTest() async {
    try {
      final granted = await _platform.requestPermission();
      if (!granted) {
        await _save(
          _reminder.copyWith(permission: NotificationPermission.denied),
        );
        return false;
      }
      await _save(
        _reminder.copyWith(permission: NotificationPermission.granted),
      );
      return await _platform.showNow(
        id: testReminderId,
        title: title,
        body: reminderMessageFor(DateTime.now()),
      );
    } catch (e) {
      debugPrint('No se pudo mostrar la notificación: $e');
      return false;
    }
  }

  /// Limpia el recordatorio al borrar todos los datos.
  Future<void> reset() async {
    try {
      await _platform.cancel(dailyReminderId);
    } catch (e) {
      debugPrint('No se pudo cancelar el recordatorio: $e');
    }
    _reminder = const ReminderSettings();
  }
}

/// Plataforma simulada para pruebas.
class FakeReminderPlatform implements ReminderPlatform {
  FakeReminderPlatform({this.grant = true});

  bool grant;
  int initializeCalls = 0;
  final List<String> scheduled = <String>[];
  final List<int> cancelled = <int>[];
  int shown = 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<bool> permissionGranted() async => grant;

  @override
  Future<bool> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    scheduled.add('$id@$hour:$minute');
    return true;
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    shown++;
    return true;
  }
}
