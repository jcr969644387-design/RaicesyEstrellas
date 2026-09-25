import '../models/app_settings.dart';
import '../models/reminder_settings.dart';
import '../models/user_profile.dart';
import 'storage_service.dart';

/// Lee y guarda perfil, ajustes y configuración del recordatorio.
class SettingsService {
  SettingsService(this._storage);

  final StorageService _storage;

  UserProfile loadProfile() {
    final json = _storage.readMap(StorageKeys.profile);
    return json == null ? const UserProfile() : UserProfile.fromJson(json);
  }

  Future<void> saveProfile(UserProfile profile) =>
      _storage.writeMap(StorageKeys.profile, profile.toJson());

  AppSettings loadSettings() {
    final json = _storage.readMap(StorageKeys.settings);
    return json == null ? const AppSettings() : AppSettings.fromJson(json);
  }

  Future<void> saveSettings(AppSettings settings) =>
      _storage.writeMap(StorageKeys.settings, settings.toJson());

  ReminderSettings loadReminder() {
    final json = _storage.readMap(StorageKeys.reminder);
    return json == null
        ? const ReminderSettings()
        : ReminderSettings.fromJson(json);
  }

  Future<void> saveReminder(ReminderSettings reminder) =>
      _storage.writeMap(StorageKeys.reminder, reminder.toJson());
}
