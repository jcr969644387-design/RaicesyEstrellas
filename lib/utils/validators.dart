/// Validaciones simples de datos introducidos por el usuario.
class Validators {
  const Validators._();

  /// Longitud máxima para textos del diario y respuestas.
  static const int maxTextLength = 5000;

  /// Longitud máxima para etiquetas.
  static const int maxTagLength = 24;

  static bool hasMinLength(String? value, int min) =>
      value != null && value.trim().length >= min;

  static String clean(String value) {
    final trimmed = value.trim();
    if (trimmed.length > maxTextLength) {
      return trimmed.substring(0, maxTextLength);
    }
    return trimmed;
  }

  static String? cleanTag(String value) {
    final t = value.trim();
    if (t.isEmpty) {
      return null;
    }
    return t.length > maxTagLength ? t.substring(0, maxTagLength) : t;
  }

  static bool isValidDay(int day, int totalDays) =>
      day >= 1 && day <= totalDays;
}
