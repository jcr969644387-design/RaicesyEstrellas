/// Mensajes posibles del recordatorio diario local.
const List<String> reminderMessages = <String>[
  'Tu estrella de hoy te está esperando.',
  'Regálate unos minutos para ti.',
  'Hoy no necesitas ser perfecto. Solo necesitas dar un pequeño paso.',
  'Tu recorrido continúa cuando decidas volver.',
];

/// Elige un mensaje de forma determinista según la fecha.
String reminderMessageFor(DateTime date) {
  final index =
      (date.year + date.month * 31 + date.day) % reminderMessages.length;
  return reminderMessages[index];
}
