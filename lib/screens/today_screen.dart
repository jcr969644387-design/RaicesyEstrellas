import 'package:flutter/material.dart';

import '../models/daily_progress.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/day_tile.dart';
import 'navigation.dart';

/// Hoy: acceso al día disponible, a Pausa y a la lista de los 30 días con
/// sus estados (bloqueado, disponible, en progreso, completado).
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final progress = app.progress;
    final current = progress.currentDay;
    final day = app.day(current);
    final status = progress.status(current);
    final complete = progress.journeyComplete;
    final constellation = app.content.constellationForDay(current);
    final root = app.content.rootById(day.rootId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  SectionTitle(
                    'Hoy',
                    subtitle: complete
                        ? 'Completaste los 30 días. Puedes revisar cualquier día.'
                        : 'Día $current de ${progress.totalDays}',
                    trailing: IconButton.filledTonal(
                      key: const ValueKey<String>('today-pause'),
                      tooltip: 'Abrir Pausa',
                      onPressed: () => openPause(context),
                      icon: const Icon(Icons.spa_outlined),
                    ),
                  ),
                  SectionCard(
                    highlight: status != DayStatus.completed,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${constellation.name} · ${status.label}',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Día $current · ${day.title}',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(day.objective, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            Chip(
                              avatar: const Icon(Icons.schedule, size: 18),
                              label: Text('${day.minutes} min'),
                            ),
                            Chip(
                              avatar:
                                  const Icon(Icons.grass_outlined, size: 18),
                              label: Text('Raíz: ${root.name}'),
                            ),
                            Chip(
                              avatar: const Icon(Icons.label_outline, size: 18),
                              label: Text(day.theme),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const ValueKey<String>('today-open-day'),
                            onPressed: () => openDay(context, current),
                            icon: Icon(
                              status == DayStatus.completed
                                  ? Icons.visibility_outlined
                                  : Icons.arrow_forward,
                            ),
                            label: Text(
                              status == DayStatus.completed
                                  ? 'Revisar Día $current'
                                  : status == DayStatus.inProgress
                                      ? 'Continuar Día $current'
                                      : 'Comenzar Día $current',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
            for (final c in app.content.constellations) ...<Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SectionTitle(
                    c.name,
                    subtitle: 'Días ${c.firstDay}–${c.lastDay} · ${c.subtitle}',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final number = c.firstDay + i;
                      final d = app.day(number);
                      return DayTile(
                        day: number,
                        title: d.title,
                        subtitle: '${d.minutes} min',
                        status: progress.status(number),
                        onTap: () => openDay(context, number),
                      );
                    },
                    childCount: c.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
