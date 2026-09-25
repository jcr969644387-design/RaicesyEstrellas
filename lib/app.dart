import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/app_settings.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scope.dart';

/// Raíz de la aplicación «Raíces y Estrellas».
class RaicesApp extends StatefulWidget {
  const RaicesApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<RaicesApp> createState() => _RaicesAppState();
}

class _RaicesAppState extends State<RaicesApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: () => widget.controller.audio.onAppPaused(),
      onResume: () => widget.controller.audio.onAppResumed(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  ThemeMode _themeMode(ThemePreference preference) {
    switch (preference) {
      case ThemePreference.system:
        return ThemeMode.system;
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: widget.controller,
      child: Builder(
        builder: (context) {
          final app = AppScope.of(context);
          return MaterialApp(
            title: 'Raíces y Estrellas',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _themeMode(app.settings.theme),
            locale: const Locale('es'),
            supportedLocales: const <Locale>[Locale('es'), Locale('en')],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeAnimationDuration: app.settings.reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 250),
            builder: (context, child) {
              final media = MediaQuery.of(context);
              final system = media.textScaler.scale(1.0);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(
                    system * app.settings.textScale,
                  ),
                  disableAnimations:
                      media.disableAnimations || app.settings.reduceMotion,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const _RootGate(),
          );
        },
      ),
    );
  }
}

/// Decide entre el onboarding y la navegación principal. Escucha al
/// controlador, así el cambio ocurre en cuanto termina el onboarding o se
/// borran todos los datos.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final completed = AppScope.of(context).profile.onboardingCompleted;
    return completed ? const HomeShell() : const OnboardingScreen();
  }
}
