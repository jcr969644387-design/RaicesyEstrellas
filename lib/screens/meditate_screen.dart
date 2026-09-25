import 'package:flutter/material.dart';

import '../data/sound_catalog.dart';
import '../models/meditation_session.dart';
import '../utils/date_utils.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import 'meditation_player_screen.dart';
import 'navigation.dart';

IconData iconForMeditation(MeditationType type) {
  switch (type) {
    case MeditationType.breathing:
      return Icons.air;
    case MeditationType.relaxation:
      return Icons.spa_outlined;
    case MeditationType.focus:
      return Icons.center_focus_strong_outlined;
    case MeditationType.gratitude:
      return Icons.volunteer_activism_outlined;
    case MeditationType.confidence:
      return Icons.shield_outlined;
    case MeditationType.selfAcceptance:
      return Icons.favorite_outline;
    case MeditationType.sleep:
      return Icons.nights_stay_outlined;
    case MeditationType.morning:
      return Icons.wb_twilight_outlined;
  }
}

/// Medítate: sesiones de 1, 3, 5 o 10 minutos con texto, temporizador,
/// animación y sonido opcional.
class MeditateScreen extends StatefulWidget {
  const MeditateScreen({super.key});

  @override
  State<MeditateScreen> createState() => _MeditateScreenState();
}

class _MeditateScreenState extends State<MeditateScreen> {
  MeditationType _type = MeditationType.breathing;
  int _minutes = 3;
  Accompaniment _accompaniment = Accompaniment.none;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final settings = app.settings;
    final options = <Accompaniment>[
      Accompaniment.none,
      if (settings.musicEnabled) Accompaniment.music,
      if (settings.ambientEnabled) Accompaniment.ambient,
    ];
    final accompaniment =
        options.contains(_accompaniment) ? _accompaniment : Accompaniment.none;
    final recent = app.meditations.sessions.take(5).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: <Widget>[
            SectionTitle(
              'Medítate',
              subtitle: 'Elige un tipo y una duración. Todo funciona sin voz.',
              trailing: IconButton.filledTonal(
                tooltip: 'Abrir Pausa',
                onPressed: () => openPause(context),
                icon: const Icon(Icons.spa_outlined),
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: <Widget>[
                for (final t in MeditationType.values)
                  SectionCard(
                    key: ValueKey<String>('meditation-${t.key}'),
                    highlight: _type == t,
                    padding: const EdgeInsets.all(12),
                    onTap: () => setState(() => _type = t),
                    semanticLabel:
                        '${t.label}${_type == t ? ', seleccionado' : ''}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(iconForMeditation(t),
                            color: theme.colorScheme.primary),
                        const Spacer(),
                        Text(
                          t.label,
                          style: theme.textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_type.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            Text('Duración', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: <ButtonSegment<int>>[
                for (final m in meditationDurations)
                  ButtonSegment<int>(value: m, label: Text('$m min')),
              ],
              selected: <int>{_minutes},
              onSelectionChanged: (s) => setState(() => _minutes = s.first),
            ),
            const SizedBox(height: 20),
            Text('Acompañamiento', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final a in options)
                  ChoiceChip(
                    label: Text(
                      a == Accompaniment.ambient
                          ? 'Ambiente: ${ambientById(settings.ambientSound).label}'
                          : a.label,
                    ),
                    selected: accompaniment == a,
                    onSelected: (_) => setState(() => _accompaniment = a),
                  ),
              ],
            ),
            if (options.length < 3)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Activa música o sonidos ambientales en Ajustes para usarlos '
                  'aquí.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey<String>('meditate-start'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MeditationPlayerScreen(
                    type: _type,
                    minutes: _minutes,
                    accompaniment: accompaniment,
                  ),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Comenzar · $_minutes min'),
            ),
            const SizedBox(height: 24),
            SectionTitle(
              'Tus meditaciones',
              subtitle: '${app.meditations.count} completadas · '
                  '${app.meditations.totalMinutes} min en total',
            ),
            if (recent.isEmpty)
              Text(
                'Aún no has completado ninguna. Un minuto es un buen comienzo.',
                style: theme.textTheme.bodyMedium,
              )
            else
              for (final s in recent)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(iconForMeditation(s.type)),
                  title: Text('${s.type.label} · ${s.minutes} min'),
                  subtitle: Text(DateUtilsX.dateTime(s.completedAt)),
                ),
          ],
        ),
      ),
    );
  }
}
