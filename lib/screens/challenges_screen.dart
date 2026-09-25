import 'package:flutter/material.dart';

import '../models/micro_challenge.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/sky_background.dart';

/// Microretos de los días disponibles. Se pueden completar u omitir;
/// omitirlos nunca penaliza.
class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  Future<void> _set(
    BuildContext context,
    int day,
    ChallengeStatus status,
  ) async {
    final achievement =
        await AppScope.read(context).setChallengeStatus(day, status);
    if (!context.mounted) {
      return;
    }
    if (achievement != null) {
      showMessage(context, 'Nueva insignia: ${achievement.title}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final progress = app.progress;
    final days = <int>[
      for (var d = 1; d <= progress.unlockedDay; d++) d,
    ].reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Microretos')),
      extendBodyBehindAppBar: true,
      body: SkyBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: <Widget>[
              Text(
                '${progress.challengesCompleted} completados. Hazlos a tu '
                'ritmo; omitir uno no resta nada.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (final day in days)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Builder(
                    builder: (context) {
                      final content = app.day(day);
                      final status = progress.challengeFor(day)?.status ??
                          ChallengeStatus.pending;
                      return SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(
                                  status == ChallengeStatus.completed
                                      ? Icons.task_alt
                                      : status == ChallengeStatus.skipped
                                          ? Icons.skip_next_rounded
                                          : Icons.radio_button_unchecked,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Día $day · ${content.challenge.title}',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                                Text(
                                  status.label,
                                  style: theme.textTheme.labelMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(app.challengeTextFor(content)),
                            if (status !=
                                ChallengeStatus.completed) ...<Widget>[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: <Widget>[
                                  FilledButton.tonal(
                                    onPressed: () => _set(
                                      context,
                                      day,
                                      ChallengeStatus.completed,
                                    ),
                                    child: const Text('Completado'),
                                  ),
                                  if (status != ChallengeStatus.skipped)
                                    TextButton(
                                      onPressed: () => _set(
                                        context,
                                        day,
                                        ChallengeStatus.skipped,
                                      ),
                                      child: const Text('Omitir'),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
