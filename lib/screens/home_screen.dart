import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/growth_tree.dart';
import 'home_shell.dart';
import 'navigation.dart';

/// Inicio: saludo, progreso, acceso al día disponible, racha sin presión,
/// estrella actual, Pausa, Medítate, resumen del árbol y mensaje del guía.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final progress = app.progress;
    final now = app.now();
    final current = progress.currentDay;
    final day = app.day(current);
    final constellation = app.content.constellationForDay(current);
    final root = app.content.rootById(day.rootId);
    final completed = progress.completedCount;
    final total = progress.totalDays;
    final streak = progress.effectiveStreak(now);
    final returning = progress.isReturningAfterAbsence(now);
    final complete = progress.journeyComplete;
    final starred = theme.brightness == Brightness.dark
        ? AppColors.star
        : theme.colorScheme.primary;

    final String ctaLabel;
    if (complete) {
      ctaLabel = 'Revisar mi viaje';
    } else if (progress.isStarted(current)) {
      ctaLabel = 'Continuar Día $current';
    } else {
      ctaLabel = 'Comenzar Día $current';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: <Widget>[
            Text(
              app.guide.greeting(now.hour),
              style: theme.textTheme.titleMedium,
            ),
            Semantics(
              header: true,
              child: Text(
                'Raíces y Estrellas',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (returning) ...<Widget>[
              SectionCard(
                highlight: true,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.favorite_outline, color: starred),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        app.content.absenceMessage,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SectionCard(
              highlight: !complete,
              semanticLabel: complete
                  ? 'Viaje completado'
                  : 'Estrella actual: Día $current, ${day.title}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.star_rounded, color: starred, size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          complete
                              ? 'Completaste tu viaje'
                              : 'Tu estrella de hoy · Día $current',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!complete) ...<Widget>[
                    Text(day.title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${constellation.name} · Raíz ${root.name} · '
                      '${day.minutes} min',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                  ] else ...<Widget>[
                    Text(
                      app.content.finalMessage,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 14),
                  ],
                  LabeledProgress(
                    value: total == 0 ? 0.0 : completed / total,
                    label: '$completed de $total estrellas encendidas',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey<String>('home-open-day'),
                      onPressed: () => complete
                          ? HomeShell.goTo(context, AppTab.journey)
                          : openDay(context, current),
                      icon: Icon(
                        complete ? Icons.auto_awesome : Icons.arrow_forward,
                      ),
                      label: Text(ctaLabel),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.eco_outlined, color: theme.colorScheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Tu guía', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          app.guideMessage(),
                          key: const ValueKey<String>('guide-message'),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: StatTile(
                    label: 'Racha actual',
                    value: '$streak ${streak == 1 ? 'día' : 'días'}',
                    icon: Icons.local_fire_department_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    label: 'Racha máxima',
                    value: '${progress.longestStreak}',
                    icon: Icons.emoji_events_outlined,
                  ),
                ),
              ],
            ),
            if (streak == 0 && completed > 0 && !complete)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'Tu progreso y tus estrellas siguen aquí. '
                  'La racha es solo una referencia.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _QuickAction(
                    key: const ValueKey<String>('home-pause'),
                    icon: Icons.spa_outlined,
                    title: 'Pausa',
                    subtitle: 'Un refugio para respirar',
                    onTap: () => openPause(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    key: const ValueKey<String>('home-meditate'),
                    icon: Icons.self_improvement,
                    title: 'Medítate',
                    subtitle: '1, 3, 5 o 10 minutos',
                    onTap: () => HomeShell.goTo(context, AppTab.meditate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              onTap: () => openTree(context),
              semanticLabel:
                  'Árbol del crecimiento: ${progress.treeStage.label}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Tu árbol · ${progress.treeStage.label}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  GrowthTree(
                    stage: progress.treeStage,
                    growth: progress.treeGrowth,
                    roots: progress.rootProgress(),
                    height: 170,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
