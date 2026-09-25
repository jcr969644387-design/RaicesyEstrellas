/// Sonido ambiental local incluido en la aplicación.
class AmbientSound {
  const AmbientSound({
    required this.id,
    required this.label,
    required this.asset,
  });

  final String id;
  final String label;

  /// Ruta relativa a `assets/` (formato esperado por audioplayers).
  final String asset;
}

/// Pista de música ambiental local.
class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.label,
    required this.asset,
  });

  final String id;
  final String label;
  final String asset;
}

/// Efectos sutiles para momentos importantes.
enum SoundEffect {
  tap('audio/effects/tap.ogg'),
  star('audio/effects/star.ogg'),
  dayComplete('audio/effects/day_complete.ogg'),
  badge('audio/effects/badge.ogg'),
  root('audio/effects/root.ogg'),
  constellation('audio/effects/constellation.ogg'),
  journeyComplete('audio/effects/journey_complete.ogg'),
  bell('audio/effects/bell.ogg');

  const SoundEffect(this.asset);

  final String asset;
}

/// Sonidos de naturaleza generados para el proyecto (sin derechos de terceros).
const List<AmbientSound> ambientSounds = <AmbientSound>[
  AmbientSound(id: 'rain', label: 'Lluvia', asset: 'audio/nature/rain.ogg'),
  AmbientSound(id: 'sea', label: 'Mar', asset: 'audio/nature/sea.ogg'),
  AmbientSound(id: 'forest', label: 'Bosque', asset: 'audio/nature/forest.ogg'),
  AmbientSound(id: 'wind', label: 'Viento', asset: 'audio/nature/wind.ogg'),
  AmbientSound(id: 'fire', label: 'Fuego', asset: 'audio/nature/fire.ogg'),
  AmbientSound(id: 'water', label: 'Agua', asset: 'audio/nature/water.ogg'),
  AmbientSound(id: 'night', label: 'Noche', asset: 'audio/nature/night.ogg'),
];

/// Música ambiental generada para el proyecto.
const List<MusicTrack> musicTracks = <MusicTrack>[
  MusicTrack(
    id: 'calm_pad',
    label: 'Calma',
    asset: 'audio/music/calm_pad.ogg',
  ),
  MusicTrack(
    id: 'deep_sky',
    label: 'Cielo profundo',
    asset: 'audio/music/deep_sky.ogg',
  ),
];

AmbientSound ambientById(String id) {
  return ambientSounds.firstWhere(
    (s) => s.id == id,
    orElse: () => ambientSounds.first,
  );
}

MusicTrack musicById(String id) {
  return musicTracks.firstWhere(
    (t) => t.id == id,
    orElse: () => musicTracks.first,
  );
}
