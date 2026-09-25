import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raices_y_estrellas/app.dart';
import 'package:raices_y_estrellas/models/app_settings.dart';
import 'package:raices_y_estrellas/models/daily_progress.dart';
import 'package:raices_y_estrellas/models/life_stage.dart';
import 'package:raices_y_estrellas/screens/meditate_screen.dart';
import 'package:raices_y_estrellas/widgets/day_tile.dart';

import 'test_helpers.dart';

Future<TestApp> _startedApp() async {
  final app = await buildTestApp();
  await app.controller.completeOnboarding(stage: LifeStage.young);
  // Reducir animaciones hace las pruebas más estables.
  await app.controller.updateSettings(
    app.controller.settings.copyWith(reduceMotion: true),
  );
  return app;
}

void main() {
  testWidgets('El onboarding carga, guarda la etapa y lleva a Inicio',
      (tester) async {
    await usePhoneSize(tester);
    final app = await buildTestApp();
    await tester.pumpWidget(RaicesApp(controller: app.controller));
    await pumpFrames(tester);

    expect(find.text('Raíces y Estrellas'), findsWidgets);
    expect(
      find.textContaining('Un viaje personal de 30 días'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('onboarding-next')));
    await pumpFrames(tester);
    expect(find.text('Cómo funciona'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('onboarding-next')));
    await pumpFrames(tester);
    expect(find.text('¿En qué etapa de tu vida estás?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('stage-adult')));
    await pumpFrames(tester, 2);
    await tester.tap(find.byKey(const ValueKey<String>('onboarding-next')));
    await pumpFrames(tester);

    expect(find.text('Continuar sin elegir'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('onboarding-next')));
    await pumpFrames(tester);

    await tester.tap(find.byKey(const ValueKey<String>('onboarding-start')));
    await pumpFrames(tester, 20);

    expect(app.controller.profile.onboardingCompleted, isTrue);
    expect(app.controller.profile.stage, LifeStage.adult);
    expect(find.text('Tu guía'), findsOneWidget);
  });

  testWidgets('Inicio carga con saludo, estrella actual y accesos',
      (tester) async {
    await usePhoneSize(tester);
    final app = await _startedApp();
    await tester.pumpWidget(RaicesApp(controller: app.controller));
    await pumpFrames(tester);

    expect(find.text('Raíces y Estrellas'), findsOneWidget);
    expect(find.text('Tu estrella de hoy · Día 1'), findsOneWidget);
    expect(find.text('Comenzar Día 1'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('guide-message')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('home-pause')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('home-meditate')), findsOneWidget);
  });

  testWidgets('Navegación a Hoy, Mi Viaje y Medítate', (tester) async {
    await usePhoneSize(tester);
    final app = await _startedApp();
    await tester.pumpWidget(RaicesApp(controller: app.controller));
    await pumpFrames(tester);

    await tester.tap(find.byKey(const ValueKey<String>('nav-today')));
    await pumpFrames(tester);
    expect(find.text('Día 1 de 30'), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('today-open-day')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('nav-journey')));
    await pumpFrames(tester);
    expect(find.text('0 de 30 estrellas encendidas'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('nav-meditate')));
    await pumpFrames(tester);
    final start = find.byKey(const ValueKey<String>('meditate-start'));
    final scrollable = find.descendant(
      of: find.byType(MeditateScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(start, 200, scrollable: scrollable.first);
    await pumpFrames(tester, 2);
    expect(start, findsOneWidget);
    expect(find.text('Comenzar · 3 min'), findsOneWidget);
  });

  testWidgets('Registro de emoción desde la sesión del día', (tester) async {
    await usePhoneSize(tester);
    final app = await _startedApp();
    await tester.pumpWidget(RaicesApp(controller: app.controller));
    await pumpFrames(tester);

    await tester.tap(find.byKey(const ValueKey<String>('home-open-day')));
    await pumpFrames(tester);
    expect(find.text('El punto de partida'), findsOneWidget);

    final next = find.byKey(const ValueKey<String>('session-next'));
    await tester.ensureVisible(next);
    await tester.tap(next);
    await pumpFrames(tester);
    expect(find.text('¿Cómo te sientes hoy?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('emotion-calm')));
    await pumpFrames(tester, 2);
    final save = find.byKey(const ValueKey<String>('session-save-checkin'));
    await tester.ensureVisible(save);
    await pumpFrames(tester, 2);
    await tester.tap(save);
    await pumpFrames(tester);

    final records = app.controller.emotions.records;
    expect(records.length, 1);
    expect(records.first.journeyDay, 1);
    expect(find.text('Enseñanza'), findsOneWidget);
  });

  testWidgets('Cambio de tema desde Ajustes', (tester) async {
    await usePhoneSize(tester);
    final app = await _startedApp();
    await tester.pumpWidget(RaicesApp(controller: app.controller));
    await pumpFrames(tester);

    await tester.tap(find.byKey(const ValueKey<String>('nav-settings')));
    await pumpFrames(tester);
    expect(app.controller.settings.theme, ThemePreference.dark);

    await tester.tap(find.text('Claro'));
    await pumpFrames(tester);
    expect(app.controller.settings.theme, ThemePreference.light);
    final context =
        tester.element(find.byKey(const ValueKey<String>('theme-selector')));
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('Estados bloqueado, disponible y completado de un día',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              DayTile(
                day: 1,
                title: 'El punto de partida',
                status: DayStatus.completed,
                onTap: () {},
              ),
              DayTile(
                day: 2,
                title: 'Conocerte sin juzgarte',
                status: DayStatus.available,
                onTap: () {},
              ),
              DayTile(
                day: 3,
                title: 'Tus fortalezas silenciosas',
                status: DayStatus.locked,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Completado'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Bloqueado'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    // Un día bloqueado no revela su título.
    expect(find.text('Tus fortalezas silenciosas'), findsNothing);
    expect(find.text('Día 3'), findsOneWidget);
  });

  testWidgets('Un día bloqueado no se abre desde Hoy', (tester) async {
    await usePhoneSize(tester);
    final app = await _startedApp();
    await tester.pumpWidget(RaicesApp(controller: app.controller));
    await pumpFrames(tester);

    await tester.tap(find.byKey(const ValueKey<String>('nav-today')));
    await pumpFrames(tester);
    final tile = find.byKey(const ValueKey<String>('day-tile-2'));
    await tester.ensureVisible(tile);
    await pumpFrames(tester, 2);
    // La barra de navegación inferior puede tapar la fila en pantallas
    // pequeñas; se invoca el toque directamente sobre la fila.
    tester.widget<InkWell>(tile).onTap!();
    await pumpFrames(tester);

    expect(
      find.text('El Día 2 se desbloquea al completar el Día 1.'),
      findsOneWidget,
    );
    expect(find.text('Conocerte sin juzgarte'), findsNothing);
  });
}
