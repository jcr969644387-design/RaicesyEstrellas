import 'package:flutter/material.dart';

import '../models/emotion_check_in.dart';
import '../services/emotion_service.dart';
import '../utils/date_utils.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/emotion_picker.dart';
import '../widgets/sky_background.dart';

/// Evolución emocional: tendencia semanal, distribución, promedio y
/// registros anteriores con opción de eliminar. Sin diagnósticos.
class EmotionsScreen extends StatelessWidget {
  const EmotionsScreen({super.key});

  Future<void> _newCheckIn(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CheckInSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final service = app.emotions;
    final records = service.records;
    final trend = service.weeklyTrend(app.now());
    final distribution = service.distribution();
    final maxCount = distribution.isEmpty ? 1 : distribution.first.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Evolución emocional')),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey<String>('emotions-new'),
        onPressed: () => _newCheckIn(context),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: SkyBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: <Widget>[
              Text(
                'Un registro personal de cómo te has sentido. No es una '
                'evaluación ni un diagnóstico.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatTile(
                      label: 'Registros',
                      value: '${records.length}',
                      icon: Icons.list_alt,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: 'Intensidad promedio',
                      value: records.isEmpty
                          ? '—'
                          : service.averageIntensity.toStringAsFixed(1),
                      icon: Icons.speed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SectionTitle(
                'Últimos 7 días',
                subtitle: 'Intensidad promedio por día',
              ),
              SectionCard(
                child: SizedBox(
                  height: 160,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      for (final p in trend)
                        Expanded(
                          child: Semantics(
                            label: _dayLabel(p),
                            excludeSemantics: true,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  p.hasData
                                      ? p.averageIntensity.toStringAsFixed(1)
                                      : '–',
                                  style: theme.textTheme.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 18,
                                  height: 6 + 90 * (p.averageIntensity / 10),
                                  decoration: BoxDecoration(
                                    color: p.hasData
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateUtilsX.weekdayShort(p.date),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Distribución de emociones'),
              if (distribution.isEmpty)
                const Text('Aún no hay registros.')
              else
                for (final entry in distribution)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: <Widget>[
                        Icon(iconForEmotion(entry.key), size: 20),
                        const SizedBox(width: 8),
                        SizedBox(width: 100, child: Text(entry.key.label)),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: entry.value / maxCount,
                              minHeight: 10,
                              backgroundColor: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${entry.value}'),
                      ],
                    ),
                  ),
              const SizedBox(height: 20),
              const SectionTitle('Registros anteriores'),
              if (records.isEmpty)
                const Text('Cuando registres emociones aparecerán aquí.')
              else
                for (final r in records)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(iconForEmotion(r.emotion)),
                      title: Text('${r.emotion.label} · ${r.intensity}/10'),
                      subtitle: Text(
                        <String>[
                          DateUtilsX.dateTime(r.date),
                          if (r.journeyDay != null) 'Día ${r.journeyDay}',
                          if (r.note.isNotEmpty) r.note,
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        tooltip: 'Eliminar registro',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await confirmAction(
                            context,
                            title: 'Eliminar registro',
                            message:
                                'Este registro se borrará del dispositivo.',
                            confirmLabel: 'Eliminar',
                            destructive: true,
                          );
                          if (!ok) {
                            return;
                          }
                          if (context.mounted) {
                            await AppScope.read(context).deleteCheckIn(r.id);
                          }
                        },
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

String _dayLabel(DailyEmotionPoint p) {
  final value =
      p.hasData ? p.averageIntensity.toStringAsFixed(1) : 'sin registros';
  return '${DateUtilsX.weekdayShort(p.date)}: $value';
}

class _CheckInSheet extends StatefulWidget {
  const _CheckInSheet();

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  Emotion? _emotion;
  int _intensity = 5;
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final emotion = _emotion;
    if (emotion == null) {
      return;
    }
    final app = AppScope.read(context);
    await app.recordCheckIn(
      emotion: emotion,
      intensity: _intensity,
      note: _note.text,
    );
    if (!mounted) {
      return;
    }
    final message = app.guide.checkInResponse(emotion, _intensity);
    final needsSupport = app.safety.needsSupport(_note.text);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (needsSupport) {
      await showSafetyDialog(context);
    }
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('¿Cómo te sientes hoy?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            EmotionPicker(
              selected: _emotion,
              onSelected: (e) => setState(() => _emotion = e),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Qué tan intensa es esta emoción?',
              style: theme.textTheme.titleSmall,
            ),
            IntensitySlider(
              value: _intensity,
              onChanged: (v) => setState(() => _intensity = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Nota opcional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey<String>('checkin-save'),
              onPressed: _emotion == null ? null : _save,
              child: const Text('Guardar registro'),
            ),
          ],
        ),
      ),
    );
  }
}
