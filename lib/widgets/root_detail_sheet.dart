import 'package:flutter/material.dart';

import '../models/root_progress.dart';
import '../theme/app_theme.dart';
import 'common.dart';

IconData iconForRootState(RootState state) {
  switch (state) {
    case RootState.locked:
      return Icons.lock_outline;
    case RootState.growing:
      return Icons.grass_outlined;
    case RootState.illuminated:
      return Icons.auto_awesome;
  }
}

/// Muestra nombre, significado, progreso, reflexión y actividades de una raíz.
Future<void> showRootDetail(
  BuildContext context,
  RootProgress root, {
  required Set<int> completedDays,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.66,
        maxChildSize: 0.92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(iconForRootState(root.state), color: AppColors.root),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Raíz: ${root.info.name}',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(root.info.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            LabeledProgress(
              value: root.fraction,
              label: 'Estado: ${root.state.label}',
              color: AppColors.root,
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Reflexión', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    root.reflectionUnlocked
                        ? root.info.reflection
                        : 'Se revelará cuando ilumines esta raíz completando '
                            'todos sus días.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: root.reflectionUnlocked
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Días asociados', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            for (final day in root.days)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  completedDays.contains(day)
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: completedDays.contains(day) ? AppColors.star : null,
                ),
                title: Text('Día $day · ${root.dayTitles[day] ?? ''}'),
                subtitle: Text(
                  completedDays.contains(day) ? 'Completado' : 'Pendiente',
                ),
              ),
            const SizedBox(height: 12),
            Text('Microretos asociados', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '${root.challengesCompleted} de ${root.days.length} completados',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final t in root.challengeTitles) Chip(label: Text(t)),
              ],
            ),
          ],
        ),
      );
    },
  );
}
