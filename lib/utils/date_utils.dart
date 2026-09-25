/// Utilidades de fecha basadas en días locales (sin horas).
class DateUtilsX {
  const DateUtilsX._();

  /// Clave `yyyy-MM-dd` para una fecha local.
  static String dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Convierte una clave `yyyy-MM-dd` en una fecha local a medianoche.
  static DateTime? parseDayKey(String? key) {
    if (key == null) {
      return null;
    }
    final parts = key.split('-');
    if (parts.length != 3) {
      return null;
    }
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) {
      return null;
    }
    return DateTime(y, m, d);
  }

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Diferencia en días de calendario (independiente de horarios de verano).
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  static const List<String> _weekdays = <String>[
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  static const List<String> _months = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static String weekdayShort(DateTime date) => _weekdays[date.weekday - 1];

  /// Formato breve en español: «12 mar 2026».
  static String shortDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  /// Formato breve con hora: «12 mar · 08:30».
  static String dateTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_months[date.month - 1]} · $h:$m';
  }
}

/// Genera identificadores locales únicos sin dependencias externas.
class LocalId {
  const LocalId._();

  static int _counter = 0;

  static String next(String prefix) {
    _counter = (_counter + 1) % 100000;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}
