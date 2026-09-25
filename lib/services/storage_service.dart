import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Claves de persistencia local. Todas usan el prefijo [StorageKeys.prefix].
class StorageKeys {
  const StorageKeys._();

  static const String prefix = 'rye.';
  static const String profile = '${prefix}profile';
  static const String journey = '${prefix}journey';
  static const String dailyProgress = '${prefix}daily';
  static const String achievements = '${prefix}achievements';
  static const String challenges = '${prefix}challenges';
  static const String journal = '${prefix}journal';
  static const String emotions = '${prefix}emotions';
  static const String meditations = '${prefix}meditations';
  static const String settings = '${prefix}settings';
  static const String reminder = '${prefix}reminder';
  static const String lastOpened = '${prefix}lastOpened';
}

/// Almacén clave-valor local basado en SharedPreferences.
///
/// No realiza ninguna comunicación de red: todo queda en el dispositivo.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Map<String, dynamic>? readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException catch (e) {
      debugPrint('Dato local dañado en $key: $e');
    }
    return null;
  }

  List<Map<String, dynamic>> readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return <Map<String, dynamic>>[
          for (final item in decoded)
            if (item is Map) Map<String, dynamic>.from(item),
        ];
      }
    } on FormatException catch (e) {
      debugPrint('Lista local dañada en $key: $e');
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> writeMap(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  String? readString(String key) => _prefs.getString(key);

  Future<void> writeString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  /// Borra todos los datos de la aplicación guardados en este dispositivo.
  Future<void> clearAll() async {
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith(StorageKeys.prefix))
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
