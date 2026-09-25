import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/day_content.dart';
import '../models/life_stage.dart';

/// Carga el contenido del viaje desde `assets/content/days_es.json`.
class ContentService {
  ContentService(this.content);

  static const String assetPath = 'assets/content/days_es.json';

  final JourneyContent content;

  static Future<ContentService> load({AssetBundle? bundle}) async {
    final source = bundle ?? rootBundle;
    final raw = await source.loadString(assetPath);
    return ContentService(parse(raw));
  }

  /// Convierte el JSON en modelos. Útil también en pruebas.
  static JourneyContent parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Contenido del viaje inválido');
    }
    return JourneyContent.fromJson(Map<String, dynamic>.from(decoded));
  }

  int get totalDays => content.totalDays;

  DayContent day(int number) => content.day(number);

  /// Ejemplo adaptado a la etapa de vida.
  String exampleFor(DayContent day, LifeStage stage) =>
      day.examples.forStage(stage);

  /// Microreto adaptado a la etapa de vida.
  String challengeFor(DayContent day, LifeStage stage) =>
      day.challenge.textFor(stage);
}
