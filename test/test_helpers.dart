import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raices_y_estrellas/models/day_content.dart';
import 'package:raices_y_estrellas/services/app_controller.dart';
import 'package:raices_y_estrellas/services/audio_service.dart';
import 'package:raices_y_estrellas/services/content_service.dart';
import 'package:raices_y_estrellas/services/notification_service.dart';
import 'package:raices_y_estrellas/services/settings_service.dart';
import 'package:raices_y_estrellas/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reloj controlable para pruebas de rachas y ausencias.
class TestClock {
  TestClock(this.current);

  DateTime current;

  DateTime call() => current;

  void advanceDays(int days) {
    current = current.add(Duration(days: days));
  }
}

JourneyContent loadContent() {
  final raw = File('assets/content/days_es.json').readAsStringSync();
  return ContentService.parse(raw);
}

Future<StorageService> freshStorage([
  Map<String, Object> values = const <String, Object>{},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return StorageService.create();
}

class TestApp {
  TestApp(this.controller, this.audioBackend, this.reminderPlatform);

  final AppController controller;
  final SilentAudioBackend audioBackend;
  final FakeReminderPlatform reminderPlatform;
}

/// Construye un controlador completo con audio y notificaciones simulados.
Future<TestApp> buildTestApp({
  TestClock? clock,
  bool grantNotifications = true,
  StorageService? storage,
}) async {
  final store = storage ?? await freshStorage();
  final settingsService = SettingsService(store);
  final backend = SilentAudioBackend();
  final platform = FakeReminderPlatform(grant: grantNotifications);
  final controller = AppController(
    storage: store,
    contentService: ContentService(loadContent()),
    audio: AudioService(backend, settings: settingsService.loadSettings()),
    notifications: NotificationService(platform, settingsService),
    clock: clock,
  );
  return TestApp(controller, backend, platform);
}

/// Avanza fotogramas sin esperar a que terminen animaciones infinitas
/// (el cielo estrellado titila continuamente).
Future<void> pumpFrames(WidgetTester tester, [int frames = 15]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Tamaño de pantalla similar a un teléfono.
Future<void> usePhoneSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
