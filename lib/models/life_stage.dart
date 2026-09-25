/// Etapas de vida que adaptan el tono, los ejemplos y los microretos.
enum LifeStage {
  teen('teen', '13–17 años', 'Identidad, amistades, estudios y confianza'),
  young('young', '18–30 años', 'Propósito, hábitos, decisiones y metas'),
  adult('adult', '31–50 años', 'Equilibrio, trabajo, relaciones y cambios'),
  senior('senior', '51 años o más', 'Sabiduría, gratitud, legado y curiosidad');

  const LifeStage(this.key, this.label, this.focus);

  /// Clave estable usada en el contenido JSON y en la persistencia.
  final String key;

  /// Texto visible para el usuario.
  final String label;

  /// Temas en los que se enfoca la adaptación.
  final String focus;

  static LifeStage? fromKey(String? key) {
    for (final stage in LifeStage.values) {
      if (stage.key == key) {
        return stage;
      }
    }
    return null;
  }
}
