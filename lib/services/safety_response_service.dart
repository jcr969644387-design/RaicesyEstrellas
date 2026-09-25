/// Detecta, de forma local y sencilla, textos que podrían indicar una
/// emergencia. No diagnostica ni intenta resolver una crisis: solo muestra
/// un mensaje respetuoso que invita a buscar apoyo inmediato.
class SafetyResponseService {
  const SafetyResponseService();

  static const String supportMessage =
      'Lamento que estés atravesando un momento difícil. Esta aplicación no '
      'puede brindar ayuda de emergencia. Por favor, busca apoyo inmediato de '
      'una persona de confianza, un profesional de salud mental o los '
      'servicios de emergencia de tu país.';

  /// Frases normalizadas (sin tildes, en minúsculas).
  static const List<String> _patterns = <String>[
    'suicid',
    'matarme',
    'me quiero matar',
    'me voy a matar',
    'quitarme la vida',
    'quiero morir',
    'quisiera morir',
    'no quiero vivir',
    'no quiero seguir viviendo',
    'acabar con mi vida',
    'acabar con todo',
    'desaparecer para siempre',
    'hacerme dano',
    'lastimarme',
    'autolesion',
    'cortarme las venas',
    'cortarme a proposito',
    'hacerme cortes',
    'herirme',
    'me quiero hacer dano',
    'voy a matar',
    'lo voy a matar',
    'la voy a matar',
    'me van a matar',
    'me quieren matar',
    'me estan golpeando',
    'me esta golpeando',
    'me pegan',
    'estoy en peligro',
    'es una emergencia',
    'violencia en mi casa',
    'me amenazan',
    'me amenaza',
  ];

  /// Normaliza el texto para comparar sin tildes ni mayúsculas.
  static String normalize(String text) {
    const from = 'áàäâéèëêíìïîóòöôúùüûñ';
    const to = 'aaaaeeeeiiiioooouuuun';
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      final index = from.indexOf(ch);
      buffer.write(index >= 0 ? to[index] : ch);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Devuelve true si el texto requiere mostrar el mensaje de apoyo.
  bool needsSupport(String? text) {
    if (text == null || text.trim().isEmpty) {
      return false;
    }
    final normalized = normalize(text);
    for (final pattern in _patterns) {
      if (normalized.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Revisa varios textos a la vez.
  bool anyNeedsSupport(Iterable<String?> texts) {
    for (final t in texts) {
      if (needsSupport(t)) {
        return true;
      }
    }
    return false;
  }
}
