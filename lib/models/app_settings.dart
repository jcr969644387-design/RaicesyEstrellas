/// Preferencia de tema.
enum ThemePreference {
  system('Sistema'),
  light('Claro'),
  dark('Oscuro');

  const ThemePreference(this.label);

  final String label;

  static ThemePreference fromKey(String? key) {
    for (final t in ThemePreference.values) {
      if (t.name == key) {
        return t;
      }
    }
    return ThemePreference.dark;
  }
}

/// Ajustes persistentes de la aplicación.
class AppSettings {
  const AppSettings({
    this.theme = ThemePreference.dark,
    this.textScale = 1.0,
    this.reduceMotion = false,
    this.musicEnabled = true,
    this.musicVolume = 0.35,
    this.musicTrack = 'calm_pad',
    this.ambientEnabled = true,
    this.ambientVolume = 0.45,
    this.ambientSound = 'rain',
    this.effectsEnabled = true,
    this.effectsVolume = 0.5,
    this.vibrationEnabled = true,
  });

  final ThemePreference theme;

  /// Escala de texto entre [minTextScale] y [maxTextScale].
  final double textScale;
  final bool reduceMotion;
  final bool musicEnabled;
  final double musicVolume;
  final String musicTrack;
  final bool ambientEnabled;
  final double ambientVolume;
  final String ambientSound;
  final bool effectsEnabled;
  final double effectsVolume;
  final bool vibrationEnabled;

  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.4;

  static double clampVolume(double v) => v.clamp(0.0, 1.0).toDouble();

  static double clampTextScale(double v) =>
      v.clamp(minTextScale, maxTextScale).toDouble();

  AppSettings copyWith({
    ThemePreference? theme,
    double? textScale,
    bool? reduceMotion,
    bool? musicEnabled,
    double? musicVolume,
    String? musicTrack,
    bool? ambientEnabled,
    double? ambientVolume,
    String? ambientSound,
    bool? effectsEnabled,
    double? effectsVolume,
    bool? vibrationEnabled,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      textScale: clampTextScale(textScale ?? this.textScale),
      reduceMotion: reduceMotion ?? this.reduceMotion,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      musicVolume: clampVolume(musicVolume ?? this.musicVolume),
      musicTrack: musicTrack ?? this.musicTrack,
      ambientEnabled: ambientEnabled ?? this.ambientEnabled,
      ambientVolume: clampVolume(ambientVolume ?? this.ambientVolume),
      ambientSound: ambientSound ?? this.ambientSound,
      effectsEnabled: effectsEnabled ?? this.effectsEnabled,
      effectsVolume: clampVolume(effectsVolume ?? this.effectsVolume),
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'theme': theme.name,
        'textScale': textScale,
        'reduceMotion': reduceMotion,
        'musicEnabled': musicEnabled,
        'musicVolume': musicVolume,
        'musicTrack': musicTrack,
        'ambientEnabled': ambientEnabled,
        'ambientVolume': ambientVolume,
        'ambientSound': ambientSound,
        'effectsEnabled': effectsEnabled,
        'effectsVolume': effectsVolume,
        'vibrationEnabled': vibrationEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const d = AppSettings();
    double readDouble(String key, double fallback) {
      final v = json[key];
      return v is num ? v.toDouble() : fallback;
    }

    bool readBool(String key, bool fallback) {
      final v = json[key];
      return v is bool ? v : fallback;
    }

    return AppSettings(
      theme: ThemePreference.fromKey(json['theme'] as String?),
      textScale: clampTextScale(readDouble('textScale', d.textScale)),
      reduceMotion: readBool('reduceMotion', d.reduceMotion),
      musicEnabled: readBool('musicEnabled', d.musicEnabled),
      musicVolume: clampVolume(readDouble('musicVolume', d.musicVolume)),
      musicTrack: json['musicTrack'] as String? ?? d.musicTrack,
      ambientEnabled: readBool('ambientEnabled', d.ambientEnabled),
      ambientVolume: clampVolume(readDouble('ambientVolume', d.ambientVolume)),
      ambientSound: json['ambientSound'] as String? ?? d.ambientSound,
      effectsEnabled: readBool('effectsEnabled', d.effectsEnabled),
      effectsVolume: clampVolume(readDouble('effectsVolume', d.effectsVolume)),
      vibrationEnabled: readBool('vibrationEnabled', d.vibrationEnabled),
    );
  }
}
