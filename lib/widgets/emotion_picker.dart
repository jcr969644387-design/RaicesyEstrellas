import 'package:flutter/material.dart';

import '../models/emotion_check_in.dart';

IconData iconForEmotion(Emotion emotion) {
  switch (emotion) {
    case Emotion.happy:
      return Icons.sentiment_very_satisfied_outlined;
    case Emotion.calm:
      return Icons.spa_outlined;
    case Emotion.motivated:
      return Icons.bolt_outlined;
    case Emotion.tired:
      return Icons.bedtime_outlined;
    case Emotion.anxious:
      return Icons.waves_outlined;
    case Emotion.sad:
      return Icons.water_drop_outlined;
    case Emotion.confused:
      return Icons.help_outline;
    case Emotion.angry:
      return Icons.local_fire_department_outlined;
    case Emotion.hopeful:
      return Icons.wb_twilight_outlined;
    case Emotion.other:
      return Icons.more_horiz;
  }
}

/// Selector de emoción con icono y texto (no depende solo del color).
class EmotionPicker extends StatelessWidget {
  const EmotionPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Emotion? selected;
  final ValueChanged<Emotion> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final e in Emotion.values)
          ChoiceChip(
            key: ValueKey<String>('emotion-${e.name}'),
            avatar: Icon(iconForEmotion(e), size: 18),
            label: Text(e.label),
            selected: selected == e,
            showCheckmark: false,
            onSelected: (_) => onSelected(e),
          ),
      ],
    );
  }
}

/// Escala de 0 a 10 para la intensidad de una emoción.
class IntensitySlider extends StatelessWidget {
  const IntensitySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.minLabel = 'Suave',
    this.maxLabel = 'Muy intensa',
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String minLabel;
  final String maxLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '$value / 10',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: '$value',
          semanticFormatterCallback: (v) => '${v.round()} de 10',
          onChanged: (v) => onChanged(v.round()),
        ),
        Row(
          children: <Widget>[
            Expanded(child: Text(minLabel, style: theme.textTheme.bodySmall)),
            Text(maxLabel, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
