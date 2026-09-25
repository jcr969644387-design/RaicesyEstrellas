import 'package:flutter/material.dart';

import '../services/app_controller.dart';

/// Hace disponible el [AppController] a todo el árbol de widgets y
/// reconstruye a quienes dependen de él cuando cambia.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Obtiene el controlador y se suscribe a sus cambios.
  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el contexto');
    return scope!.notifier!;
  }

  /// Obtiene el controlador sin suscribirse (para acciones).
  static AppController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el contexto');
    return scope!.notifier!;
  }
}
