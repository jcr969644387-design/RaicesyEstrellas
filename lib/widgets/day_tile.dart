import 'package:flutter/material.dart';

import '../models/daily_progress.dart';
import '../theme/app_theme.dart';

/// Icono asociado a cada estado (el estado nunca depende solo del color).
IconData iconForStatus(DayStatus status) {
  switch (status) {
    case DayStatus.locked:
      return Icons.lock_outline;
    case DayStatus.available:
      return Icons.star_border_rounded;
    case DayStatus.inProgress:
      return Icons.timelapse_rounded;
    case DayStatus.completed:
      return Icons.star_rounded;
  }
}

/// Fila de un día del viaje con estado bloqueado, disponible, en progreso
/// o completado.
class DayTile extends StatelessWidget {
  const DayTile({
    super.key,
    required this.day,
    required this.title,
    required this.status,
    required this.onTap,
    this.subtitle,
  });

  final int day;
  final String title;
  final DayStatus status;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locked = status == DayStatus.locked;
    final completed = status == DayStatus.completed;
    final accent =
        completed ? AppColors.star : (locked ? scheme.outline : scheme.primary);
    final shownTitle = locked ? 'Día $day' : title;
    return Semantics(
      button: true,
      label: 'Día $day, $shownTitle, ${status.label}',
      excludeSemantics: true,
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey<String>('day-tile-$day'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed
                          ? AppColors.star.withValues(alpha: 0.2)
                          : Colors.transparent,
                      border: Border.all(color: accent, width: 1.5),
                    ),
                    child: Text(
                      '$day',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: completed ? AppColors.star : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          shownTitle,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle == null
                              ? status.label
                              : '${status.label} · $subtitle',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(iconForStatus(status), color: accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
