import 'package:flutter/material.dart';

import '../models/daily_progress.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/constellation_map.dart';
import '../widgets/growth_tree.dart';
import '../widgets/particle_burst.dart';
import '../widgets/sky_background.dart';
import 'navigation.dart';

/// Recompensa al completar un día. En los días 7, 14 y 21 se convierte en
/// un hito: se conectan las estrellas de la constelación y el árbol evoluciona.
class DayCompleteScreen extends StatelessWidget {
  const DayCompleteScreen({super.key, required this.result});

  final DayCompletionResult result;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final progress = app.progress;
    final reduce = app.settings.reduceMotion;
    final milestone = result.completedConstellation;
    final day = app.day(result.day);
    final statuses = <int, DayStatus>{
      for (var d = 1; d <= progress.totalDays; d++) d: progress.status(d),
    };
    final revealIndex = milestone == null
        ? null
        : app.content.constellations.indexOf(milestone);
    final gold = theme.brightness == Brightness.dark
        ? AppColors.star
        : theme.colorScheme.primary;

    return Scaffold(
      body: SkyBackground(
        child: Stack(
          children: <Widget>[
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                children: <Widget>[
                  Icon(
                    milestone == null ? Icons.star_rounded : Icons.auto_awesome,
                    size: 56,
                    color: gold,
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    header: true,
                    child: Text(
                      milestone?.milestoneTitle ??
                          'Día ${result.day} completado',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    milestone == null
                        ? 'Encendiste la ${day.reward.label}.'
                        : 'Las estrellas ${milestone.firstDay} a '
                            '${milestone.lastDay} ahora forman una constelación.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 18),
                  ConstellationMap(
                    statuses: statuses,
                    currentDay: progress.currentDay,
                    reduceMotion: reduce,
                    revealConstellation: revealIndex,
                  ),
                  const SizedBox(height: 18),
                  if (milestone != null) ...<Widget>[
                    SectionCard(
                      highlight: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Reflexión especial',
                              style: theme.textTheme.labelLarge),
                          const SizedBox(height: 6),
                          Text(
                            milestone.milestoneReflection,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SectionCard(
                      onTap: () => openTree(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Tu árbol evolucionó: ${progress.treeStage.label}',
                            style: theme.textTheme.titleMedium,
                          ),
                          GrowthTree(
                            stage: progress.treeStage,
                            growth: progress.treeGrowth,
                            roots: progress.rootProgress(),
                            height: 190,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StatTile(
                          label: 'XP ganada',
                          value: '+${result.xpGained}',
                          icon: Icons.bolt_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: 'Nivel',
                          value: '${progress.level}',
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StatTile(
                          label: 'Estrellas',
                          value: '${progress.stars}/${progress.totalDays}',
                          icon: Icons.star_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: 'Racha',
                          value: '${progress.effectiveStreak(app.now())}',
                          icon: Icons.local_fire_department_outlined,
                        ),
                      ),
                    ],
                  ),
                  if (result.newlyIlluminatedRoots.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    for (final r in result.newlyIlluminatedRoots)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SectionCard(
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.grass, color: AppColors.root),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Raíz iluminada: ${r.name}. ${r.reflection}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  if (result.newAchievements.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    Text('Nuevas insignias',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final a in result.newAchievements)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SectionCard(
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.military_tech_outlined, color: gold),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('${a.title}: ${a.description}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  if (result.returnedAfterAbsence) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      app.content.absenceMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    app.guide.completionMessage(
                      result.day,
                      progress.totalDays,
                      progress.effectiveStreak(app.now()),
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    key: const ValueKey<String>('day-complete-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continuar'),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: ParticleBurst(enabled: milestone != null && !reduce),
            ),
          ],
        ),
      ),
    );
  }
}
