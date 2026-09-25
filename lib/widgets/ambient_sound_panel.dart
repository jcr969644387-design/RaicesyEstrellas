import 'package:flutter/material.dart';

import '../data/sound_catalog.dart';
import 'app_scope.dart';

/// Panel funcional para elegir y reproducir un sonido ambiental local.
/// Si los sonidos ambientales están desactivados, lo indica y permite
/// activarlos (nunca muestra controles que no hagan nada).
class AmbientSoundPanel extends StatelessWidget {
  const AmbientSoundPanel({super.key, this.initialSound, this.compact = false});

  final String? initialSound;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final settings = app.settings;
    if (!settings.ambientEnabled) {
      return Row(
        children: <Widget>[
          const Icon(Icons.volume_off_outlined),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Los sonidos ambientales están desactivados.'),
          ),
          TextButton(
            onPressed: () => app.updateSettings(
              settings.copyWith(ambientEnabled: true),
            ),
            child: const Text('Activar'),
          ),
        ],
      );
    }
    return ListenableBuilder(
      listenable: app.audio,
      builder: (context, _) {
        final audio = app.audio;
        final playingId = audio.currentAmbientId;
        final selected = playingId ?? initialSound ?? settings.ambientSound;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!compact)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Sonido ambiental',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final s in ambientSounds)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: selected == s.id,
                    onSelected: (_) async {
                      await app.updateSettings(
                        app.settings.copyWith(ambientSound: s.id),
                      );
                      if (audio.isAmbientPlaying || audio.isAmbientPaused) {
                        await audio.playAmbient(s.id);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                if (!audio.isAmbientPlaying)
                  FilledButton.tonalIcon(
                    onPressed: () => audio.isAmbientPaused
                        ? audio.resumeAmbient()
                        : audio.playAmbient(selected),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      audio.isAmbientPaused ? 'Reanudar' : 'Reproducir',
                    ),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: audio.pauseAmbient,
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text('Pausar'),
                  ),
                const SizedBox(width: 8),
                if (audio.isAmbientPlaying || audio.isAmbientPaused)
                  OutlinedButton.icon(
                    onPressed: audio.stopAmbient,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Detener'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
