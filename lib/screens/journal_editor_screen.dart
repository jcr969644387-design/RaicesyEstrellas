import 'package:flutter/material.dart';

import '../data/journey_goals.dart';
import '../models/journal_entry.dart';
import '../utils/validators.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/sky_background.dart';

/// Crear o editar una entrada del diario.
class JournalEditorScreen extends StatefulWidget {
  const JournalEditorScreen({super.key, this.entry});

  final JournalEntry? entry;

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _text;
  final TextEditingController _newTag = TextEditingController();
  late Set<String> _tags;
  int? _day;
  bool _saving = false;

  bool get _editing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.entry?.title ?? '');
    _text = TextEditingController(text: widget.entry?.text ?? '');
    _tags = <String>{...?widget.entry?.tags};
    _day = widget.entry?.day;
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    _newTag.dispose();
    super.dispose();
  }

  void _insertPrompt(String prompt) {
    final current = _text.text;
    final prefix = current.isEmpty || current.endsWith('\n') ? '' : '\n';
    _text.text = '$current$prefix$prompt\n';
    _text.selection = TextSelection.collapsed(offset: _text.text.length);
    setState(() {});
  }

  void _addTag() {
    final tag = Validators.cleanTag(_newTag.text);
    if (tag == null) {
      return;
    }
    setState(() {
      _tags.add(tag);
      _newTag.clear();
    });
  }

  Future<void> _save() async {
    if (_text.text.trim().isEmpty && _title.text.trim().isEmpty) {
      showMessage(context, 'Escribe algo antes de guardar.');
      return;
    }
    setState(() => _saving = true);
    final app = AppScope.read(context);
    final needsSupport =
        app.safety.anyNeedsSupport(<String>[_title.text, _text.text]);
    final entry = widget.entry;
    bool ok;
    if (entry == null) {
      ok = await app.addJournalEntry(
            text: _text.text,
            title: _title.text,
            tags: _tags.toList(),
            day: _day,
          ) !=
          null;
    } else {
      ok = await app.updateJournalEntry(
        entry.copyWith(
          title: _title.text,
          text: _text.text,
          tags: _tags.toList(),
          day: _day,
          clearDay: _day == null,
        ),
      );
    }
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (needsSupport) {
      await showSafetyDialog(context);
      if (!mounted) {
        return;
      }
    }
    if (ok) {
      showMessage(context, 'Entrada guardada.');
      Navigator.of(context).pop();
    } else {
      showMessage(context, 'No se pudo guardar la entrada.');
    }
  }

  Future<void> _delete() async {
    final entry = widget.entry;
    if (entry == null) {
      return;
    }
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar entrada',
      message: 'Esta entrada se borrará de forma permanente.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    if (!mounted) {
      return;
    }
    await AppScope.read(context).deleteJournalEntry(entry.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final completed = app.progress.completedDays;
    final current = app.progress.currentDay;
    final dayOptions = <int>{...completed, current}.toList()..sort();
    final allTags = <String>{...journalTags, ..._tags}.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar entrada' : 'Nueva entrada'),
        actions: <Widget>[
          if (_editing)
            IconButton(
              tooltip: 'Eliminar',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          IconButton(
            key: const ValueKey<String>('journal-save'),
            tooltip: 'Guardar',
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SkyBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('journal-title'),
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Título (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text('Preguntas sugeridas', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final p in journalPrompts)
                    ActionChip(
                      label: Text(p),
                      onPressed: () => _insertPrompt(p),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('journal-text'),
                controller: _text,
                minLines: 8,
                maxLines: 20,
                maxLength: Validators.maxTextLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Escribe libremente',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('Etiquetas', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final t in allTags)
                    FilterChip(
                      label: Text(t),
                      selected: _tags.contains(t),
                      onSelected: (v) => setState(
                        () => v ? _tags.add(t) : _tags.remove(t),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _newTag,
                      maxLength: Validators.maxTagLength,
                      decoration: const InputDecoration(
                        labelText: 'Nueva etiqueta',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Añadir etiqueta',
                    onPressed: _addTag,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Relacionar con un día', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('Ninguno'),
                    selected: _day == null,
                    onSelected: (_) => setState(() => _day = null),
                  ),
                  for (final d in dayOptions)
                    ChoiceChip(
                      label: Text('Día $d'),
                      selected: _day == d,
                      onSelected: (_) => setState(() => _day = d),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
              ),
              if (_editing) ...<Widget>[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar entrada'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
