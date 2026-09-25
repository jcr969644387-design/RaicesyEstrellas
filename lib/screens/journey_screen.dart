import 'package:flutter/material.dart';

import '../models/daily_progress.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/constellation_map.dart';
import '../widgets/root_detail_sheet.dart';
import 'journey_complete_screen.dart';
import 'navigation.dart';

/// Mi Viaje: 30 estrellas, constelaciones, rachas, insignias, raíces,
/// microretos, meditaciones y progreso del árbol.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  Future<void> _newCycle(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: 'Iniciar un nuevo ciclo',
      message: 'Volverás al Día 1. Tu diario, emociones, meditaciones e '
          'insignias se conservan y se guarda un resumen de este viaje.',
      confirmLabel: 'Iniciar',
    );
    if (!ok) {
      return;
    }
    if (context.mounted) {
      await AppScope.read(context).startNewCycle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final progress = app.progress;
    final now = app.now();
    final statuses = <int, DayStatus>{
      for (var d = 1; d <= progress.totalDays; d++) d: progress.status(d),
    };
    final roots = progress.rootProgress();
    final completedSet = progress.completedDays.toSet();
    final gold = theme.brightness == Brightness.dark
        ? AppColors.star
        : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: <Widget>[
            SectionTitle(
              'Mi Viaje',
              subtitle: progress.cycle > 1
                  ? 'Ciclo ${progress.cycle} · ${progress.completedCount} de ${progress.totalDays} estrellas'
                  : '${progress.completedCount} de ${progress.totalDays} estrellas encendidas',
            ),
            SectionCard(
              padding: const EdgeInsets.all(8),
              child: ConstellationMap(
                statuses: statuses,
                currentDay:
                    progress.journeyComplete ? null : progress.currentDay,
                reduceMotion: app.settings.reduceMotion,
                onStarTap: (day) => openDay(context, day),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca una estrella para abrir su día. Las apagadas siguen '
              'bloqueadas; las encendidas se pueden revisar.',
              style: theme.textTheme.bodySmall,
            ),
            if (progress.journeyComplete) ...<Widget>[
              const SizedBox(height: 16),
              SectionCard(
                highlight: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      app.content.finalMessage,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes revisar tu viaje, seguir usando el diario y '
                      'Medítate, o comenzar un nuevo ciclo.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const JourneyCompleteScreen(),
                        ),
                      ),
                      child: const Text('Ver resumen del viaje'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _newCycle(context),
                      child: const Text('Iniciar un nuevo ciclo'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: <Widget>[
                StatTile(
                  label: 'Días completados',
                  value: '${progress.completedCount}',
                  icon: Icons.check_circle_outline,
                ),
                StatTile(
                  label: 'Día actual',
                  value: progress.journeyComplete
                      ? 'Completo'
                      : '${progress.currentDay}',
                  icon: Icons.wb_sunny_outlined,
                ),
                StatTile(
                  label: 'Racha actual',
                  value: '${progress.effectiveStreak(now)}',
                  icon: Icons.local_fire_department_outlined,
                ),
                StatTile(
                  label: 'Racha máxima',
                  value: '${progress.longestStreak}',
                  icon: Icons.emoji_events_outlined,
                ),
                StatTile(
                  label: 'Nivel · ${progress.xp} XP',
                  value: '${progress.level}',
                  icon: Icons.trending_up_rounded,
                ),
                StatTile(
                  label: 'Meditaciones',
                  value: '${app.meditations.count}',
                  icon: Icons.self_improvement,
                ),
                StatTile(
                  label: 'Microretos completados',
                  value: '${progress.challengesCompleted}',
                  icon: Icons.task_alt,
                ),
                StatTile(
                  label: 'Constelaciones',
                  value: '${progress.completedConstellations}/4',
                  icon: Icons.auto_awesome_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LabeledProgress(
              value: progress.levelProgress,
              label: 'Progreso al nivel ${progress.level + 1}',
            ),
            const SizedBox(height: 20),
            SectionTitle(
              'Constelaciones',
              trailing: TextButton(
                onPressed: () => openTree(context),
                child: const Text('Ver árbol'),
              ),
            ),
            for (final c in progress.constellationProgress())
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LabeledProgress(
                  value: c.fraction,
                  label: '${c.info.name} ${c.isComplete ? '✦ completa' : ''}'
                      .trim(),
                  color: gold,
                ),
              ),
            const SizedBox(height: 10),
            SectionCard(
              onTap: () => openTree(context),
              child: Row(
                children: <Widget>[
                  Icon(Icons.park_outlined, color: theme.colorScheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Árbol del crecimiento: ${progress.treeStage.label}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle(
              'Las 7 raíces',
              subtitle: 'Toca una raíz para ver su significado.',
            ),
            for (var i = 0; i < roots.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SectionCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  onTap: () => showRootDetail(
                    context,
                    roots[i],
                    completedDays: completedSet,
                  ),
                  semanticLabel: 'Raíz ${roots[i].info.name}, '
                      '${roots[i].state.label}, ${roots[i].percent} por ciento',
                  child: Row(
                    children: <Widget>[
                      Icon(
                        iconForRootState(roots[i].state),
                        color: AppColors.root,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledProgress(
                          value: roots[i].fraction,
                          label:
                              '${roots[i].info.name} · ${roots[i].state.label}',
                          color: AppColors.root,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SectionTitle(
              'Microretos',
              subtitle: '${progress.challengesCompleted} completados',
              trailing: TextButton(
                onPressed: () => openChallenges(context),
                child: const Text('Ver todos'),
              ),
            ),
            const SizedBox(height: 8),
            const SectionTitle('Insignias'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final a in progress.achievements)
                  Tooltip(
                    message: a.description,
                    child: Chip(
                      avatar: Icon(
                        a.isUnlocked ? Icons.military_tech : Icons.lock_outline,
                        size: 18,
                        color: a.isUnlocked ? gold : null,
                      ),
                      label: Text(
                        a.isUnlocked ? a.title : '${a.title} (bloqueada)',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SectionCard(
              onTap: () => openEmotions(context),
              child: Row(
                children: <Widget>[
                  Icon(Icons.insights_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Evolución emocional')),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            if (progress.journey.previousCycles.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              const SectionTitle('Ciclos anteriores'),
              for (final c in progress.journey.previousCycles)
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('Ciclo ${c.cycle}: ${c.completedDays} días'),
                  subtitle: Text(
                    c.declaration == null
                        ? 'Racha máxima ${c.longestStreak}'
                        : c.declaration!,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
