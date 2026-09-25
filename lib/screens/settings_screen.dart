import 'package:flutter/material.dart';

import '../data/sound_catalog.dart';
import '../models/app_settings.dart';
import '../models/life_stage.dart';
import '../models/reminder_settings.dart';
import '../services/app_controller.dart';
import '../services/notification_service.dart';
import '../widgets/ambient_sound_panel.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';

/// Ajustes funcionales y persistentes: apariencia, sonido, vibración,
/// recordatorios y privacidad.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _update(BuildContext context, AppSettings next) =>
      AppScope.read(context).updateSettings(next);

  String _reminderMessage(ReminderResult result) {
    switch (result) {
      case ReminderResult.scheduled:
        return 'Recordatorio diario programado.';
      case ReminderResult.disabled:
        return 'Recordatorio desactivado.';
      case ReminderResult.permissionDenied:
        return 'Sin permiso para notificaciones. Puedes concederlo más tarde '
            'desde aquí o desde los ajustes del teléfono.';
      case ReminderResult.invalidTime:
        return 'La hora elegida no es válida.';
      case ReminderResult.error:
        return 'No se pudo programar el recordatorio en este dispositivo.';
    }
  }

  Future<void> _toggleReminder(BuildContext context, bool enable) async {
    final app = AppScope.read(context);
    final result =
        enable ? await app.enableReminder() : await app.disableReminder();
    if (context.mounted) {
      showMessage(context, _reminderMessage(result));
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final app = AppScope.read(context);
    final r = app.reminder;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: r.hour, minute: r.minute),
      helpText: 'Hora del recordatorio',
    );
    if (picked == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final result = await app.updateReminderTime(picked.hour, picked.minute);
    if (context.mounted) {
      showMessage(
        context,
        result == ReminderResult.disabled
            ? 'Hora guardada. Activa el recordatorio para recibirlo.'
            : _reminderMessage(result),
      );
    }
  }

  Future<void> _dataAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function(AppController app) action,
    required String done,
  }) async {
    final ok = await confirmAction(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: true,
    );
    if (!ok) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final app = AppScope.read(context);
    await action(app);
    if (context.mounted) {
      showMessage(context, done);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final s = app.settings;
    final reminder = app.reminder;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: <Widget>[
            const SectionTitle('Ajustes'),

            // ---------------------------------------------------------------
            const SectionTitle('Etapa de vida'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final stage in LifeStage.values)
                  ChoiceChip(
                    label: Text(stage.label),
                    selected: app.profile.stage == stage,
                    onSelected: (_) => app.updateStage(stage),
                  ),
              ],
            ),
            if (app.profile.goal != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tu objetivo: ${app.profile.goal}',
                  style: theme.textTheme.bodySmall,
                ),
              ),

            // ---------------------------------------------------------------
            const SizedBox(height: 16),
            const SectionTitle('Apariencia'),
            SegmentedButton<ThemePreference>(
              key: const ValueKey<String>('theme-selector'),
              segments: const <ButtonSegment<ThemePreference>>[
                ButtonSegment<ThemePreference>(
                  value: ThemePreference.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Claro'),
                ),
                ButtonSegment<ThemePreference>(
                  value: ThemePreference.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Oscuro'),
                ),
                ButtonSegment<ThemePreference>(
                  value: ThemePreference.system,
                  icon: Icon(Icons.phone_android),
                  label: Text('Sistema'),
                ),
              ],
              selected: <ThemePreference>{s.theme},
              onSelectionChanged: (v) =>
                  _update(context, s.copyWith(theme: v.first)),
            ),
            const SizedBox(height: 16),
            Text(
              'Tamaño de texto: ${(s.textScale * 100).round()}%',
              style: theme.textTheme.titleSmall,
            ),
            Slider(
              key: const ValueKey<String>('text-scale'),
              value: s.textScale,
              min: AppSettings.minTextScale,
              max: AppSettings.maxTextScale,
              divisions: 11,
              label: '${(s.textScale * 100).round()}%',
              onChanged: (v) => _update(context, s.copyWith(textScale: v)),
            ),
            SwitchListTile(
              key: const ValueKey<String>('switch-reduce-motion'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Reducir animaciones'),
              subtitle: const Text('Desactiva movimientos y partículas.'),
              value: s.reduceMotion,
              onChanged: (v) => _update(context, s.copyWith(reduceMotion: v)),
            ),

            // ---------------------------------------------------------------
            const SizedBox(height: 16),
            const SectionTitle(
              'Sonido',
              subtitle: 'Audio local, sin Internet y a volumen bajo.',
            ),
            SwitchListTile(
              key: const ValueKey<String>('switch-music'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.music_note_outlined),
              title: const Text('Música'),
              value: s.musicEnabled,
              onChanged: (v) => _update(context, s.copyWith(musicEnabled: v)),
            ),
            if (s.musicEnabled) ...<Widget>[
              _VolumeSlider(
                label: 'Volumen de música',
                value: s.musicVolume,
                onChanged: (v) => _update(context, s.copyWith(musicVolume: v)),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  for (final t in musicTracks)
                    ChoiceChip(
                      label: Text(t.label),
                      selected: s.musicTrack == t.id,
                      onSelected: (_) =>
                          _update(context, s.copyWith(musicTrack: t.id)),
                    ),
                  ListenableBuilder(
                    listenable: app.audio,
                    builder: (context, _) => TextButton.icon(
                      onPressed: app.audio.isMusicPlaying
                          ? app.audio.stopMusic
                          : () => app.audio.playMusic(),
                      icon: Icon(
                        app.audio.isMusicPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        app.audio.isMusicPlaying ? 'Detener' : 'Probar',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SwitchListTile(
              key: const ValueKey<String>('switch-ambient'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.forest_outlined),
              title: const Text('Sonidos ambientales'),
              subtitle: const Text(
                'Lluvia, mar, bosque, viento, fuego, agua y noche.',
              ),
              value: s.ambientEnabled,
              onChanged: (v) => _update(context, s.copyWith(ambientEnabled: v)),
            ),
            if (s.ambientEnabled) ...<Widget>[
              _VolumeSlider(
                label: 'Volumen ambiental',
                value: s.ambientVolume,
                onChanged: (v) =>
                    _update(context, s.copyWith(ambientVolume: v)),
              ),
              const AmbientSoundPanel(compact: true),
            ],
            SwitchListTile(
              key: const ValueKey<String>('switch-effects'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Efectos'),
              subtitle: const Text('Estrellas, insignias, raíces y hitos.'),
              value: s.effectsEnabled,
              onChanged: (v) => _update(context, s.copyWith(effectsEnabled: v)),
            ),
            if (s.effectsEnabled) ...<Widget>[
              _VolumeSlider(
                label: 'Volumen de efectos',
                value: s.effectsVolume,
                onChanged: (v) =>
                    _update(context, s.copyWith(effectsVolume: v)),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => app.playEffect(SoundEffect.star),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Probar efecto'),
                ),
              ),
            ],
            SwitchListTile(
              key: const ValueKey<String>('switch-vibration'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.vibration),
              title: const Text('Vibración'),
              subtitle:
                  const Text('Vibración discreta en momentos especiales.'),
              value: s.vibrationEnabled,
              onChanged: (v) {
                _update(context, s.copyWith(vibrationEnabled: v)).then((_) {
                  if (v) {
                    app.vibrate(HapticLevel.medium);
                  }
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'La voz guiada no se incluye en esta versión: las sesiones '
                'se guían con texto, temporizador y animación.',
                style: theme.textTheme.bodySmall,
              ),
            ),

            // ---------------------------------------------------------------
            const SizedBox(height: 16),
            const SectionTitle(
              'Recordatorios',
              subtitle: 'Notificación local diaria, sin servidor ni Internet.',
            ),
            SwitchListTile(
              key: const ValueKey<String>('switch-reminder'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.alarm_outlined),
              title: const Text('Recordatorio diario'),
              value: reminder.enabled,
              onChanged: (v) => _toggleReminder(context, v),
            ),
            ListTile(
              key: const ValueKey<String>('reminder-time'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Hora del recordatorio'),
              subtitle: Text(reminder.formattedTime),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _pickTime(context),
            ),
            Text(
              'Permiso de notificaciones: ${reminder.permission.label}',
              style: theme.textTheme.bodySmall,
            ),
            if (reminder.permission ==
                NotificationPermission.denied) ...<Widget>[
              const SizedBox(height: 8),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Para recibir el recordatorio, la app necesita permiso '
                      'para mostrar notificaciones. La app sigue funcionando '
                      'igual sin él.',
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () async {
                        final result = await app.retryReminderPermission();
                        if (context.mounted) {
                          showMessage(context, _reminderMessage(result));
                        }
                      },
                      child: const Text('Reintentar permiso'),
                    ),
                  ],
                ),
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await app.sendTestReminder();
                  if (context.mounted) {
                    showMessage(
                      context,
                      ok
                          ? 'Notificación de prueba enviada.'
                          : 'No se pudo mostrar. Revisa el permiso de '
                              'notificaciones.',
                    );
                  }
                },
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('Enviar notificación de prueba'),
              ),
            ),

            // ---------------------------------------------------------------
            const SizedBox(height: 16),
            const SectionTitle(
              'Privacidad y datos',
              subtitle: 'Todo se guarda solo en este dispositivo.',
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Eliminar diario'),
              subtitle: Text('${app.journal.count} entradas'),
              onTap: () => _dataAction(
                context,
                title: 'Eliminar diario',
                message: 'Se borrarán todas las entradas del diario, incluidas '
                    'las cartas guardadas.',
                confirmLabel: 'Eliminar',
                action: (a) => a.deleteJournal(),
                done: 'Diario eliminado.',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Eliminar registros emocionales'),
              subtitle: Text('${app.emotions.records.length} registros'),
              onTap: () => _dataAction(
                context,
                title: 'Eliminar registros emocionales',
                message: 'Se borrarán todos los check-ins emocionales.',
                confirmLabel: 'Eliminar',
                action: (a) => a.deleteEmotions(),
                done: 'Registros emocionales eliminados.',
              ),
            ),
            ListTile(
              key: const ValueKey<String>('reset-journey'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restart_alt),
              title: const Text('Reiniciar viaje'),
              subtitle: const Text(
                'Vuelve al Día 1. Diario, emociones e insignias se conservan.',
              ),
              onTap: () => _dataAction(
                context,
                title: 'Reiniciar viaje',
                message: 'Tu progreso de días, estrellas, cartas y microretos '
                    'volverá al inicio.',
                confirmLabel: 'Reiniciar',
                action: (a) => a.resetJourney(),
                done: 'Viaje reiniciado.',
              ),
            ),
            ListTile(
              key: const ValueKey<String>('delete-all'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_forever_outlined,
                  color: theme.colorScheme.error),
              title: Text(
                'Borrar todos los datos locales',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              subtitle:
                  const Text('Perfil, progreso, diario, emociones y ajustes.'),
              onTap: () => _dataAction(
                context,
                title: 'Borrar todos los datos',
                message: 'Se eliminará todo lo guardado en este dispositivo y '
                    'la app volverá a la bienvenida. No se puede deshacer.',
                confirmLabel: 'Borrar todo',
                action: (a) => a.deleteAllData(),
                done: 'Datos eliminados.',
              ),
            ),

            // ---------------------------------------------------------------
            const SizedBox(height: 16),
            const SectionTitle('Bienestar'),
            SectionCard(
              child: Text(
                'Raíces y Estrellas es una herramienta de reflexión y '
                'crecimiento personal. No diagnostica, no ofrece consejo '
                'clínico y no sustituye a profesionales de salud mental. Si '
                'atraviesas una emergencia, busca apoyo inmediato de una '
                'persona de confianza, un profesional o los servicios de '
                'emergencia de tu país.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Raíces y Estrellas · v1.0.0',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SizedBox(width: 16),
        const Icon(Icons.volume_down_outlined, size: 20),
        Expanded(
          child: Slider(
            value: value,
            divisions: 20,
            label: '${(value * 100).round()}%',
            semanticFormatterCallback: (v) => '$label ${(v * 100).round()}%',
            onChanged: onChanged,
          ),
        ),
        const Icon(Icons.volume_up_outlined, size: 20),
      ],
    );
  }
}
