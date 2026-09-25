import 'package:flutter/material.dart';

import '../data/journey_goals.dart';
import '../models/journal_entry.dart';
import '../utils/date_utils.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import 'journal_editor_screen.dart';
import 'navigation.dart';

/// Diario personal privado: escribir, editar, eliminar y filtrar.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String? _tag;

  Future<void> _openEditor([JournalEntry? entry]) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JournalEditorScreen(entry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final all = app.journal.entries;
    final tags =
        <String>{...journalTags, for (final e in all) ...e.tags}.toList();
    final entries =
        _tag == null ? all : all.where((e) => e.tags.contains(_tag)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey<String>('journal-new'),
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Escribir'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: <Widget>[
            SectionTitle(
              'Diario',
              subtitle: 'Privado. Solo se guarda en este dispositivo.',
              trailing: IconButton.filledTonal(
                tooltip: 'Evolución emocional',
                onPressed: () => openEmotions(context),
                icon: const Icon(Icons.insights_outlined),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todas'),
                      selected: _tag == null,
                      onSelected: (_) => setState(() => _tag = null),
                    ),
                  ),
                  for (final t in tags)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t),
                        selected: _tag == t,
                        onSelected: (_) => setState(
                          () => _tag = _tag == t ? null : t,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _tag == null
                          ? 'Tu diario está esperando la primera página.'
                          : 'No hay entradas con la etiqueta «$_tag».',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes empezar con una pregunta: ¿qué aprendí hoy?, '
                      '¿qué agradezco?, ¿qué quiero recordar?',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => _openEditor(),
                      child: const Text('Escribir ahora'),
                    ),
                  ],
                ),
              )
            else
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    onTap: () => _openEditor(e),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              e.kind == JournalKind.letter
                                  ? Icons.mail_outline
                                  : e.kind == JournalKind.guided
                                      ? Icons.question_answer_outlined
                                      : Icons.edit_note,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.title.isEmpty ? e.kind.label : e.title,
                                style: theme.textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              DateUtilsX.shortDate(e.createdAt),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (e.tags.isNotEmpty || e.day != null) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            <String>[
                              if (e.day != null) 'Día ${e.day}',
                              ...e.tags,
                            ].join(' · '),
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
