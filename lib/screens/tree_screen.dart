import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/growth_tree.dart';
import '../widgets/root_detail_sheet.dart';
import '../widgets/sky_background.dart';

/// Árbol del crecimiento interactivo con sus 7 raíces.
class TreeScreen extends StatefulWidget {
  const TreeScreen({super.key});

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  int? _selected;

  static const Map<TreeStage, int> _stageDay = <TreeStage, int>{
    TreeStage.seed: 1,
    TreeStage.sprout: 7,
    TreeStage.young: 14,
    TreeStage.growing: 21,
    TreeStage.full: 30,
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final progress = app.progress;
    final roots = progress.rootProgress();
    final completed = progress.completedDays.toSet();
    final current = progress.treeStage;

    void openRoot(int i) {
      setState(() => _selected = i);
      showRootDetail(context, roots[i], completedDays: completed);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Árbol del crecimiento')),
      extendBodyBehindAppBar: true,
      body: SkyBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: <Widget>[
              Text(
                current.label,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cada día completado alimenta tu árbol. Toca una raíz para '
                'conocerla.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              GrowthTree(
                stage: current,
                growth: progress.treeGrowth,
                roots: roots,
                height: 380,
                selectedRoot: _selected,
                onRootTap: openRoot,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (var i = 0; i < roots.length; i++)
                    ActionChip(
                      avatar: Icon(
                        iconForRootState(roots[i].state),
                        size: 18,
                        color: AppColors.root,
                      ),
                      label: Text('${roots[i].info.name} ${roots[i].percent}%'),
                      onPressed: () => openRoot(i),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const SectionTitle('Evolución'),
              for (final stage in TreeStage.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    stage.index <= current.index
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: stage.index <= current.index
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.outline,
                  ),
                  title: Text(stage.label),
                  subtitle: Text('Día ${_stageDay[stage]}'),
                  trailing: stage == current
                      ? const Chip(label: Text('Ahora'))
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
