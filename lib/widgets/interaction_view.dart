import 'dart:async';

import 'package:flutter/material.dart';

import '../data/meditation_scripts.dart';
import '../models/daily_progress.dart';
import '../models/day_content.dart';
import '../utils/validators.dart';
import 'breathing_circle.dart';
import 'common.dart';

/// Opciones de la revisión de hábitos.
const List<String> habitMarks = <String>[
  'Me ayuda',
  'Quiero ajustarlo',
  'No aplica'
];

/// Borrador editable de la interacción de un día.
class InteractionDraft {
  InteractionDraft(this.interaction, DailyProgress saved, {String letter = ''})
      : choice = saved.choice,
        choices = <String>{...saved.choices},
        scale = saved.scale,
        marks = <String, String>{...saved.marks},
        done = saved.interactionDone,
        text = TextEditingController(
          text: interaction.type == InteractionType.futureLetter
              ? letter
              : (saved.text ?? ''),
        ),
        fields = <TextEditingController>[
          for (var i = 0; i < interaction.fields.length; i++)
            TextEditingController(
              text: i < saved.fields.length ? saved.fields[i] : '',
            ),
        ];

  final DayInteraction interaction;
  String? choice;
  Set<String> choices;
  int? scale;
  Map<String, String> marks;
  bool done;
  final TextEditingController text;
  final List<TextEditingController> fields;

  InteractionType get type => interaction.type;

  int get filledFields => fields.where((c) => c.text.trim().isNotEmpty).length;

  bool get isValid {
    switch (type) {
      case InteractionType.singleChoice:
      case InteractionType.control:
        return choice != null;
      case InteractionType.multiChoice:
        return choices.isNotEmpty && choices.length <= interaction.max;
      case InteractionType.freeText:
      case InteractionType.futureMessage:
      case InteractionType.letterReply:
      case InteractionType.futureLetter:
        return Validators.hasMinLength(text.text, interaction.minLength);
      case InteractionType.scale:
        return scale != null;
      case InteractionType.fields:
        return filledFields >= interaction.minFilled;
      case InteractionType.breathing:
      case InteractionType.visualization:
        return done;
      case InteractionType.habitReview:
        return marks.isNotEmpty;
    }
  }

  String get validationHint {
    switch (type) {
      case InteractionType.singleChoice:
      case InteractionType.control:
        return 'Elige una opción para continuar.';
      case InteractionType.multiChoice:
        return 'Elige al menos una opción (máximo ${interaction.max}).';
      case InteractionType.freeText:
      case InteractionType.futureMessage:
      case InteractionType.letterReply:
      case InteractionType.futureLetter:
        return 'Escribe unas palabras para continuar.';
      case InteractionType.scale:
        return 'Mueve la escala para elegir un valor.';
      case InteractionType.fields:
        return 'Completa al menos ${interaction.minFilled} campo(s).';
      case InteractionType.breathing:
        return 'Completa las respiraciones para continuar.';
      case InteractionType.visualization:
        return 'Inicia la visualización para continuar.';
      case InteractionType.habitReview:
        return 'Marca al menos un hábito.';
    }
  }

  /// Textos libres que se revisan con el servicio de respuesta segura.
  List<String> get freeTexts => <String>[
        text.text,
        for (final f in fields) f.text,
      ];

  /// Convierte el borrador en progreso guardable. Las cartas no se guardan
  /// aquí para que permanezcan selladas.
  DailyProgress toProgress(DailyProgress base) {
    final isLetter = type == InteractionType.futureLetter ||
        type == InteractionType.letterReply;
    return DailyProgress(
      day: base.day,
      startedAt: base.startedAt,
      completedAt: base.completedAt,
      choice: choice,
      choices: choices.toList(),
      text: isLetter ? null : Validators.clean(text.text),
      fields: <String>[for (final f in fields) Validators.clean(f.text)],
      scale: scale,
      marks: marks,
      interactionDone: done || isLetter,
    );
  }

  void dispose() {
    text.dispose();
    for (final f in fields) {
      f.dispose();
    }
  }
}

/// Interfaz de la interacción del día según su tipo.
class InteractionView extends StatefulWidget {
  const InteractionView({
    super.key,
    required this.draft,
    required this.onChanged,
    this.readOnly = false,
    this.reduceMotion = false,
    this.revealedLetter,
    this.onRevealLetter,
    this.letterSealed = false,
  });

  final InteractionDraft draft;
  final VoidCallback onChanged;
  final bool readOnly;
  final bool reduceMotion;

  /// Carta del Día 1 revelada (solo en el Día 30).
  final String? revealedLetter;
  final VoidCallback? onRevealLetter;

  /// En revisión del Día 1: la carta está sellada hasta el Día 30.
  final bool letterSealed;

  @override
  State<InteractionView> createState() => _InteractionViewState();
}

class _InteractionViewState extends State<InteractionView> {
  Timer? _timer;
  int _elapsed = 0;
  bool _breathing = false;
  int _cycles = 0;

  InteractionDraft get _d => widget.draft;

  DayInteraction get _i => widget.draft.interaction;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(_i.prompt, style: theme.textTheme.titleMedium),
        if (_i.hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_i.hint, style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: 14),
        _body(theme),
      ],
    );
  }

  Widget _body(ThemeData theme) {
    switch (_i.type) {
      case InteractionType.singleChoice:
      case InteractionType.control:
        return _choiceList(theme);
      case InteractionType.multiChoice:
        return _multi(theme);
      case InteractionType.freeText:
      case InteractionType.futureMessage:
        return _textField(_d.text, _i.placeholder, lines: 5);
      case InteractionType.futureLetter:
        return _letter(theme);
      case InteractionType.letterReply:
        return _letterReply(theme);
      case InteractionType.scale:
        return _scale(theme);
      case InteractionType.fields:
        return _fields();
      case InteractionType.breathing:
        return _breathingExercise(theme);
      case InteractionType.visualization:
        return _visualization(theme);
      case InteractionType.habitReview:
        return _habits(theme);
    }
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    int lines = 3,
    String? label,
  }) {
    return TextField(
      controller: controller,
      readOnly: widget.readOnly,
      minLines: lines,
      maxLines: lines + 6,
      maxLength: Validators.maxTextLength,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
      onChanged: (_) => _changed(),
    );
  }

  Widget _choiceList(ThemeData theme) {
    final selected = _i.choices.where((c) => c.label == _d.choice).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_i.type == InteractionType.control) ...<Widget>[
          _textField(_d.text, _i.placeholder, lines: 2),
          const SizedBox(height: 12),
        ],
        for (final option in _i.choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SelectableTile(
              label: option.label,
              selected: _d.choice == option.label,
              onTap: widget.readOnly
                  ? null
                  : () {
                      _d.choice = option.label;
                      _changed();
                    },
            ),
          ),
        if (selected.isNotEmpty && selected.first.feedback.isNotEmpty)
          SectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(selected.first.feedback)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _multi(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${_d.choices.length} de ${_i.max} elegidas',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final item in _i.items)
              FilterChip(
                label: Text(item),
                selected: _d.choices.contains(item),
                onSelected: widget.readOnly
                    ? null
                    : (value) {
                        if (value) {
                          if (_d.choices.length >= _i.max) {
                            showMessage(
                              context,
                              'Puedes elegir hasta ${_i.max}.',
                            );
                            return;
                          }
                          _d.choices.add(item);
                        } else {
                          _d.choices.remove(item);
                        }
                        _changed();
                      },
              ),
          ],
        ),
      ],
    );
  }

  Widget _scale(ThemeData theme) {
    final value = _d.scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          value == null ? 'Sin elegir' : '$value / 10',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        Slider(
          value: (value ?? 5).toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: '${value ?? 5}',
          semanticFormatterCallback: (v) => '${v.round()} de 10',
          onChanged: widget.readOnly
              ? null
              : (v) {
                  _d.scale = v.round();
                  _changed();
                },
        ),
        Row(
          children: <Widget>[
            Expanded(
                child: Text(_i.minLabel, style: theme.textTheme.bodySmall)),
            Text(_i.maxLabel, style: theme.textTheme.bodySmall),
          ],
        ),
        if (value != null) ...<Widget>[
          const SizedBox(height: 12),
          SectionCard(child: Text(_i.feedbackForScale(value))),
        ],
      ],
    );
  }

  Widget _fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < _i.fields.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _textField(
              _d.fields[i],
              _i.fields[i].placeholder,
              lines: 2,
              label: _i.fields[i].label,
            ),
          ),
      ],
    );
  }

  Widget _letter(ThemeData theme) {
    if (widget.letterSealed) {
      return SectionCard(
        child: Row(
          children: <Widget>[
            Icon(Icons.mark_email_read_outlined,
                color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tu carta está sellada. Se abrirá cuando llegues al Día 30.',
              ),
            ),
          ],
        ),
      );
    }
    return _textField(_d.text, _i.placeholder, lines: 8);
  }

  Widget _letterReply(ThemeData theme) {
    final letter = widget.revealedLetter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionCard(
          highlight: letter == null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.mail_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tu yo del Día 1 tiene algo que decirte.',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (letter == null)
                FilledButton.icon(
                  key: const ValueKey<String>('reveal-letter'),
                  onPressed: widget.onRevealLetter,
                  icon: const Icon(Icons.drafts_outlined),
                  label: const Text('Abrir la carta'),
                )
              else
                Text(
                  letter.trim().isEmpty
                      ? 'El Día 1 decidiste no escribir una carta. '
                          'Aun así, llegaste hasta aquí.'
                      : letter,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
            ],
          ),
        ),
        if (letter != null) ...<Widget>[
          const SizedBox(height: 16),
          Text(_i.prompt, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _textField(_d.text, _i.placeholder, lines: 6),
        ],
      ],
    );
  }

  Widget _breathingExercise(ThemeData theme) {
    final target = _i.cycles;
    final done = _d.done || _cycles >= target;
    return Column(
      children: <Widget>[
        if (_i.mantra.isNotEmpty)
          Text(
            '«${_i.mantra}»',
            style: theme.textTheme.titleMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 12),
        BreathingCircle(
          running: _breathing && !done,
          pattern: calmBreathing,
          reduceMotion: widget.reduceMotion,
          size: 200,
          onCycleComplete: () {
            _cycles++;
            if (_cycles >= target) {
              _d.done = true;
              _breathing = false;
            }
            _changed();
          },
        ),
        const SizedBox(height: 12),
        Text(
          done
              ? 'Respiraciones completadas'
              : 'Respiración ${_cycles + (_breathing ? 1 : 0)} de $target',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        if (!done && !widget.readOnly)
          FilledButton.tonalIcon(
            onPressed: () {
              setState(() => _breathing = !_breathing);
            },
            icon: Icon(
              _breathing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(_breathing ? 'Pausar' : 'Comenzar'),
          ),
      ],
    );
  }

  void _toggleVisualization() {
    if (_timer != null) {
      _timer?.cancel();
      setState(() => _timer = null);
      return;
    }
    setState(() {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _elapsed++);
        if (_elapsed >= _i.seconds) {
          t.cancel();
          _timer = null;
          _d.done = true;
          _changed();
        }
      });
    });
  }

  Widget _visualization(ThemeData theme) {
    final steps = _i.steps;
    final total = _i.seconds;
    final perStep = steps.isEmpty ? total : (total / steps.length).ceil();
    final index = steps.isEmpty
        ? 0
        : (_elapsed ~/ perStep).clamp(0, steps.length - 1).toInt();
    final remaining = (total - _elapsed).clamp(0, total).toInt();
    final running = _timer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionCard(
          child: Column(
            children: <Widget>[
              Text(
                _d.done
                    ? 'Visualización completada'
                    : '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              if (steps.isNotEmpty)
                AnimatedSwitcher(
                  duration: widget.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 600),
                  child: Text(
                    _d.done ? steps.last : steps[index],
                    key: ValueKey<int>(_d.done ? steps.length : index),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
                  ),
                ),
              const SizedBox(height: 12),
              if (!_d.done && !widget.readOnly)
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: _toggleVisualization,
                      icon: Icon(
                        running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        running
                            ? 'Pausar'
                            : (_elapsed > 0 ? 'Reanudar' : 'Comenzar'),
                      ),
                    ),
                    if (_elapsed > 0)
                      TextButton(
                        onPressed: () {
                          _timer?.cancel();
                          _timer = null;
                          _d.done = true;
                          _changed();
                        },
                        child: const Text('Ya terminé'),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _textField(_d.text, _i.placeholder, lines: 3),
      ],
    );
  }

  Widget _habits(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final habit in _i.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(habit, style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final mark in habitMarks)
                      ChoiceChip(
                        label: Text(mark),
                        selected: _d.marks[habit] == mark,
                        onSelected: widget.readOnly
                            ? null
                            : (_) {
                                _d.marks[habit] = mark;
                                _changed();
                              },
                      ),
                  ],
                ),
              ],
            ),
          ),
        _textField(_d.text, _i.placeholder, lines: 2),
      ],
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.16)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(label)),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
