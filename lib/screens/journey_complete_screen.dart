import 'package:flutter/material.dart';

import '../models/daily_progress.dart';
import '../models/root_progress.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/constellation_map.dart';
import '../widgets/growth_tree.dart';
import '../widgets/particle_burst.dart';
import '../widgets/root_detail_sheet.dart';
import '../widgets/sky_background.dart';

/// La experiencia más importante: el cierre del viaje de 30 días.
class JourneyCompleteScreen extends StatefulWidget {
  const JourneyCompleteScreen({super.key});

  @override
  State<JourneyCompleteScreen> createState() => _JourneyCompleteScreenState();
}

class _JourneyCompleteScreenState extends State<JourneyCompleteScreen> {
  final TextEditingController _declaration = TextEditingController();
  final TextEditingController _reply = TextEditingController();
  String? _letter;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final app = AppScope.read(context);
    _declaration.text = app.progress.finalDeclaration;
    _reply.text = app.progress.day30Reply;
    if (app.progress.letterRevealed) {
      _letter = app.progress.readDay1Letter();
    }
  }

  @override
  void dispose() {
    _declaration.dispose();
    _reply.dispose();
    super.dispose();
  }

  Future<void> _reveal() async {
    final letter = await AppScope.read(context).revealLetter();
    if (mounted) {
      setState(() => _letter = letter ?? '');
    }
  }

  Future<void> _saveReply() async {
    final app = AppScope.read(context);
    if (app.safety.needsSupport(_reply.text)) {
      await showSafetyDialog(context);
      if (!mounted) {
        return;
      }
    }
    final ok = await app.saveDay30Reply(_reply.text.trim());
    if (mounted) {
      showMessage(context, ok ? 'Respuesta guardada.' : 'No se pudo guardar.');
    }
  }

  Future<void> _saveDeclaration() async {
    final text = _declaration.text.trim();
    if (text.isEmpty) {
      showMessage(
          context, 'Escribe unas palabras sobre lo que quieres construir.');
      return;
    }
    final app = AppScope.read(context);
    if (app.safety.needsSupport(text)) {
      await showSafetyDialog(context);
      if (!mounted) {
        return;
      }
    }
    final ok = await app.saveDeclaration(text);
    if (mounted) {
      showMessage(
        context,
        ok
            ? 'Tu declaración quedó guardada en el diario.'
            : 'No se pudo guardar.',
      );
    }
  }

  Future<void> _newCycle() async {
    final confirmed = await confirmAction(
      context,
      title: 'Iniciar un nuevo ciclo',
      message: 'Empezarás otra vez desde el Día 1. Tu diario, tus '
          'emociones, tus meditaciones e insignias se conservan, y se guarda '
          'un resumen de este viaje.',
      confirmLabel: 'Iniciar nuevo ciclo',
    );
    if (!confirmed) {
      return;
    }
    if (!mounted) {
      return;
    }
    await AppScope.read(context).startNewCycle();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final progress = app.progress;
    final reduce = app.settings.reduceMotion;
    final roots = progress.rootProgress();
    final statuses = <int, DayStatus>{
      for (var d = 1; d <= progress.totalDays; d++) d: progress.status(d),
    };
    final completedSet = progress.completedDays.toSet();
    final gold = theme.brightness == Brightness.dark
        ? AppColors.star
        : theme.colorScheme.primary;

    final stats = <(String, String, IconData)>[
      (
        'Días completados',
        '${progress.completedCount}',
        Icons.check_circle_outline
      ),
      (
        'Racha actual',
        '${progress.effectiveStreak(app.now())}',
        Icons.local_fire_department_outlined
      ),
      (
        'Racha máxima',
        '${progress.longestStreak}',
        Icons.emoji_events_outlined
      ),
      (
        'Reflexiones registradas',
        '${app.journal.count}',
        Icons.menu_book_outlined
      ),
      ('Meditaciones', '${app.meditations.count}', Icons.self_improvement),
      (
        'Microretos completados',
        '${progress.challengesCompleted}',
        Icons.task_alt
      ),
      ('Estrellas', '${progress.stars}', Icons.star_outline_rounded),
      (
        'Insignias',
        '${progress.unlockedAchievementCount}',
        Icons.military_tech_outlined
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tu viaje')),
      extendBodyBehindAppBar: true,
      body: SkyBackground(
        child: Stack(
          children: <Widget>[
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
                children: <Widget>[
                  Icon(Icons.auto_awesome, size: 64, color: gold),
                  const SizedBox(height: 12),
                  Semantics(
                    header: true,
                    child: Text(
                      'COMPLETASTE TU VIAJE',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las 30 estrellas brillan y tus cuatro constelaciones '
                    'están completas.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ConstellationMap(
                    statuses: statuses,
                    reduceMotion: reduce,
                    revealConstellation: 3,
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Tu árbol: ${progress.treeStage.label}',
                          style: theme.textTheme.titleMedium,
                        ),
                        GrowthTree(
                          stage: progress.treeStage,
                          growth: progress.treeGrowth,
                          roots: roots,
                          height: 240,
                          onRootTap: (i) => showRootDetail(
                            context,
                            roots[i],
                            completedDays: completedSet,
                          ),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            for (final r in roots)
                              Chip(
                                avatar: Icon(
                                  r.state == RootState.illuminated
                                      ? Icons.auto_awesome
                                      : Icons.grass_outlined,
                                  size: 16,
                                ),
                                label: Text(r.info.name),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.1,
                    children: <Widget>[
                      for (final s in stats)
                        StatTile(label: s.$1, value: s.$2, icon: s.$3),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    highlight: _letter == null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Tu yo del Día 1 tiene algo que decirte.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        if (_letter == null)
                          FilledButton.icon(
                            onPressed: _reveal,
                            icon: const Icon(Icons.drafts_outlined),
                            label: const Text('Revelar la carta'),
                          )
                        else
                          Text(
                            _letter!.trim().isEmpty
                                ? 'El Día 1 no escribiste carta, pero llegaste '
                                    'hasta aquí.'
                                : _letter!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        if (_letter != null) ...<Widget>[
                          const SizedBox(height: 16),
                          Text(
                            'Ahora escribe una respuesta para tu yo del futuro.',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _reply,
                            minLines: 3,
                            maxLines: 8,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Querido yo...',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _saveReply,
                              child: const Text('Guardar respuesta'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          app.content.finalQuestion,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const ValueKey<String>('final-declaration'),
                          controller: _declaration,
                          minLines: 3,
                          maxLines: 8,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Quiero construir...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonal(
                          onPressed: _saveDeclaration,
                          child: const Text('Guardar mi declaración'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    app.content.finalMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Puedes seguir usando el Diario, Medítate y Pausa, '
                    'y consultar Mi Viaje cuando quieras.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Volver al inicio'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _newCycle,
                    child: const Text('Iniciar un nuevo ciclo'),
                  ),
                ],
              ),
            ),
            Positioned.fill(child: ParticleBurst(enabled: !reduce, count: 70)),
          ],
        ),
      ),
    );
  }
}
