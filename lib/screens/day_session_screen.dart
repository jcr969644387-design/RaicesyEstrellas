import 'package:flutter/material.dart';

import '../models/daily_progress.dart';
import '../models/day_content.dart';
import '../models/emotion_check_in.dart';
import '../models/meditation_session.dart';
import '../models/micro_challenge.dart';
import '../widgets/ambient_sound_panel.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/emotion_picker.dart';
import '../widgets/interaction_view.dart';
import '../widgets/sky_background.dart';
import 'day_complete_screen.dart';
import 'journey_complete_screen.dart';
import 'navigation.dart';

/// Sesión diaria: bienvenida, check-in emocional, reflexión y enseñanza,
/// interacción, microreto, meditación y ambiente sugeridos, cierre y
/// recompensa. Los días completados se abren en modo revisión.
class DaySessionScreen extends StatefulWidget {
  const DaySessionScreen({super.key, required this.day});

  final int day;

  @override
  State<DaySessionScreen> createState() => _DaySessionScreenState();
}

class _DaySessionScreenState extends State<DaySessionScreen> {
  static const List<String> _stepNames = <String>[
    'Bienvenida',
    'Check-in',
    'Reflexión',
    'Interacción',
    'Microreto',
    'Meditación',
    'Cierre',
  ];

  late final DayContent _day;
  late final InteractionDraft _draft;
  late final bool _review;
  final TextEditingController _note = TextEditingController();

  int _step = 0;
  Emotion? _emotion;
  int _intensity = 5;
  bool _checkInSaved = false;
  String? _checkInResponse;
  String? _revealedLetter;
  bool _completing = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final app = AppScope.read(context);
    _day = app.day(widget.day);
    _review = app.progress.isCompleted(widget.day);
    _draft = InteractionDraft(
      _day.interaction,
      app.progress.progressFor(widget.day),
      letter: app.progress.editableDay1Letter,
    );
    final existing = app.emotions.forJourneyDay(widget.day);
    if (existing != null) {
      _emotion = existing.emotion;
      _intensity = existing.intensity;
      _checkInSaved = true;
    }
    if (_day.interaction.type == InteractionType.letterReply) {
      if (app.progress.letterRevealed) {
        _revealedLetter = app.progress.readDay1Letter();
      }
      _draft.text.text = app.progress.day30Reply;
    }
    if (!_review) {
      app.startDay(widget.day);
    }
  }

  @override
  void dispose() {
    _draft.dispose();
    _note.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  void _goTo(int step) => setState(() => _step = step);

  Future<void> _saveCheckIn() async {
    final emotion = _emotion;
    if (emotion == null) {
      return;
    }
    final app = AppScope.read(context);
    if (!_checkInSaved) {
      await app.recordCheckIn(
        emotion: emotion,
        intensity: _intensity,
        note: _note.text,
        journeyDay: widget.day,
      );
      if (!mounted) {
        return;
      }
      if (app.safety.needsSupport(_note.text)) {
        await showSafetyDialog(context);
        if (!mounted) {
          return;
        }
      }
    }
    setState(() {
      _checkInSaved = true;
      _checkInResponse = app.guide.checkInResponse(emotion, _intensity);
      _step = 2;
    });
  }

  Future<void> _saveInteraction() async {
    if (!_draft.isValid) {
      showMessage(context, _draft.validationHint);
      return;
    }
    final app = AppScope.read(context);
    if (app.safety.anyNeedsSupport(_draft.freeTexts)) {
      await showSafetyDialog(context);
      if (!mounted) {
        return;
      }
    }
    final base = app.progress.progressFor(widget.day);
    await app.saveDayResponse(_draft.toProgress(base));
    if (_day.interaction.type == InteractionType.futureLetter) {
      await app.saveDay1Letter(_draft.text.text.trim());
    } else if (_day.interaction.type == InteractionType.letterReply) {
      await app.saveDay30Reply(_draft.text.text.trim());
    }
    if (!mounted) {
      return;
    }
    _goTo(4);
  }

  Future<void> _revealLetter() async {
    final letter = await AppScope.read(context).revealLetter();
    if (!mounted) {
      return;
    }
    setState(() => _revealedLetter = letter ?? '');
  }

  Future<void> _setChallenge(ChallengeStatus status) async {
    final app = AppScope.read(context);
    final achievement = await app.setChallengeStatus(widget.day, status);
    if (!mounted) {
      return;
    }
    if (achievement != null) {
      showMessage(context, 'Nueva insignia: ${achievement.title}');
    } else if (status == ChallengeStatus.skipped) {
      showMessage(context, 'Está bien. Omitir no resta nada a tu viaje.');
    }
  }

  Future<void> _complete() async {
    if (_completing) {
      return;
    }
    setState(() => _completing = true);
    final app = AppScope.read(context);
    final result = await app.completeDay(widget.day);
    if (!mounted) {
      return;
    }
    if (!result.accepted) {
      setState(() => _completing = false);
      showMessage(context, 'No se pudo completar: ${result.reason}.');
      return;
    }
    final route = MaterialPageRoute<void>(
      builder: (_) => result.journeyCompleted
          ? const JourneyCompleteScreen()
          : DayCompleteScreen(result: result),
    );
    await Navigator.of(context).pushReplacement(route);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final constellation = app.content.constellationById(_day.constellationId);
    return Scaffold(
      appBar: AppBar(
        title: Text('Día ${widget.day}'),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('session-pause'),
            tooltip: 'Abrir Pausa',
            onPressed: () => openPause(context),
            icon: const Icon(Icons.spa_outlined),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SkyBackground(
        child: SafeArea(
          child: _review
              ? _reviewBody(theme, constellation.name)
              : Column(
                  children: <Widget>[
                    _stepper(theme),
                    Expanded(
                      child: SingleChildScrollView(
                        key: ValueKey<int>(_step),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        child: _stepBody(theme, constellation.name),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _stepper(ThemeData theme) {
    return Semantics(
      label: 'Paso ${_step + 1} de ${_stepNames.length}: ${_stepNames[_step]}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${_step + 1}/${_stepNames.length} · ${_stepNames[_step]}',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_step + 1) / _stepNames.length,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody(ThemeData theme, String constellationName) {
    switch (_step) {
      case 0:
        return _welcome(theme, constellationName);
      case 1:
        return _checkIn(theme);
      case 2:
        return _reflection(theme);
      case 3:
        return _interaction(theme);
      case 4:
        return _challenge(theme);
      case 5:
        return _meditation(theme);
      default:
        return _closing(theme);
    }
  }

  Widget _navRow({
    required VoidCallback? onNext,
    String nextLabel = 'Siguiente',
    Key? nextKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: <Widget>[
          if (_step > 0)
            TextButton(
              onPressed: () => _goTo(_step - 1),
              child: const Text('Atrás'),
            ),
          const Spacer(),
          Flexible(
            child: FilledButton(
              key: nextKey,
              onPressed: onNext,
              child: Text(nextLabel, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcome(ThemeData theme, String constellationName) {
    final app = AppScope.of(context);
    final root = app.content.rootById(_day.rootId);
    final returning = app.progress.isReturningAfterAbsence(app.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(constellationName, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text(
            _day.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            Chip(
              avatar: const Icon(Icons.schedule, size: 18),
              label: Text('${_day.minutes} min'),
            ),
            Chip(
              avatar: const Icon(Icons.grass_outlined, size: 18),
              label: Text('Raíz: ${root.name}'),
            ),
            Chip(
              avatar: const Icon(Icons.label_outline, size: 18),
              label: Text(_day.theme),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (returning) ...<Widget>[
          SectionCard(
            highlight: true,
            child: Text(
              app.content.absenceMessage,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          _day.intro,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('Objetivo: ${_day.objective}')),
            ],
          ),
        ),
        _navRow(
          nextKey: const ValueKey<String>('session-next'),
          onNext: () => _goTo(1),
          nextLabel: 'Empezar',
        ),
      ],
    );
  }

  Widget _checkIn(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('¿Cómo te sientes hoy?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 14),
        EmotionPicker(
          selected: _emotion,
          onSelected: _checkInSaved
              ? (_) => showMessage(
                    context,
                    'Ya registraste tu emoción de este día.',
                  )
              : (e) => setState(() => _emotion = e),
        ),
        if (_emotion != null) ...<Widget>[
          const SizedBox(height: 22),
          Text(
            '¿Qué tan intensa es esta emoción?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          IntensitySlider(
            value: _intensity,
            onChanged: (v) {
              if (!_checkInSaved) {
                setState(() => _intensity = v);
              }
            },
          ),
          if (!_checkInSaved) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nota opcional',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
        _navRow(
          nextKey: const ValueKey<String>('session-save-checkin'),
          onNext: _emotion == null ? null : _saveCheckIn,
          nextLabel: _checkInSaved ? 'Siguiente' : 'Guardar y seguir',
        ),
      ],
    );
  }

  Widget _reflection(ThemeData theme) {
    final app = AppScope.of(context);
    final example = app.exampleFor(_day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_checkInResponse != null) ...<Widget>[
          SectionCard(
            child: Row(
              children: <Widget>[
                Icon(Icons.eco_outlined, color: theme.colorScheme.secondary),
                const SizedBox(width: 10),
                Expanded(child: Text(_checkInResponse!)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Enseñanza', style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(
          _day.teaching,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
        ),
        if (example.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            example,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
        const SizedBox(height: 18),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.menu_book_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _day.philosophySource,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _day.philosophyIdea,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Pregunta del día', style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(_day.question, style: theme.textTheme.titleLarge),
        _navRow(
          nextKey: const ValueKey<String>('session-next'),
          onNext: () => _goTo(3),
        ),
      ],
    );
  }

  Widget _recallCard(ThemeData theme) {
    final recall = _day.recallDay;
    if (recall == null) {
      return const SizedBox.shrink();
    }
    final app = AppScope.of(context);
    final summary = app.progress.progressFor(recall).summary;
    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Lo que respondiste en el Día $recall',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(summary, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _interaction(ThemeData theme) {
    final app = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _recallCard(theme),
        InteractionView(
          draft: _draft,
          onChanged: () => setState(() {}),
          reduceMotion: app.settings.reduceMotion,
          revealedLetter: _revealedLetter,
          onRevealLetter: _revealLetter,
        ),
        if (!_draft.isValid)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child:
                Text(_draft.validationHint, style: theme.textTheme.bodySmall),
          ),
        _navRow(
          nextKey: const ValueKey<String>('session-save-interaction'),
          onNext: _saveInteraction,
          nextLabel: 'Guardar y seguir',
        ),
      ],
    );
  }

  Widget _challenge(ThemeData theme) {
    final app = AppScope.of(context);
    final status = app.progress.challengeFor(widget.day)?.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Microreto', style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(_day.challenge.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text(
          app.challengeTextFor(_day),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 16),
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Estado: ${status.label}',
              style: theme.textTheme.titleSmall,
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              key: const ValueKey<String>('challenge-done'),
              onPressed: () => _setChallenge(ChallengeStatus.completed),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Completado'),
            ),
            OutlinedButton.icon(
              onPressed: () => _setChallenge(ChallengeStatus.pending),
              icon: const Icon(Icons.schedule),
              label: const Text('Lo haré más tarde'),
            ),
            TextButton.icon(
              onPressed: () => _setChallenge(ChallengeStatus.skipped),
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Omitir'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Puedes marcarlo después en Mi Viaje › Microretos. '
          'Omitirlo nunca te quita progreso.',
          style: theme.textTheme.bodySmall,
        ),
        _navRow(
          nextKey: const ValueKey<String>('session-next'),
          onNext: () => _goTo(5),
        ),
      ],
    );
  }

  Widget _meditation(ThemeData theme) {
    final suggestion = _day.meditation;
    final type = MeditationType.fromKey(suggestion.type);
    final minutes = meditationDurations.contains(suggestion.minutes)
        ? suggestion.minutes
        : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Meditación sugerida', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(suggestion.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('${type.label} · $minutes min · ${type.description}'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => openMeditation(
                  context,
                  type: type,
                  minutes: minutes,
                  fromDay: widget.day,
                ),
                icon: const Icon(Icons.self_improvement),
                label: const Text('Iniciar meditación'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Ambiente sugerido', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SectionCard(
          child: AmbientSoundPanel(initialSound: _day.ambient, compact: true),
        ),
        const SizedBox(height: 8),
        Text(
          'Ambos son opcionales. Puedes continuar cuando quieras.',
          style: theme.textTheme.bodySmall,
        ),
        _navRow(
          nextKey: const ValueKey<String>('session-next'),
          onNext: () => _goTo(6),
        ),
      ],
    );
  }

  Widget _closing(ThemeData theme) {
    final app = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 12),
        Icon(Icons.auto_awesome, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          _day.closing,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Row(
            children: <Widget>[
              Icon(Icons.star_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recompensa: ${_day.reward.label} · +${_day.reward.xp} XP',
                ),
              ),
            ],
          ),
        ),
        if (!_draft.isValid) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            'Antes de completar el día, guarda tu interacción.',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const ValueKey<String>('session-complete'),
          onPressed: _completing || !_draft.isValid ? null : _complete,
          icon: const Icon(Icons.star_rounded),
          label: Text('Completar Día ${widget.day}'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _goTo(5),
          child: const Text('Atrás'),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu progreso de ${app.progress.completedCount} días se guarda en '
          'este dispositivo.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Modo revisión (días completados)
  // ---------------------------------------------------------------------------

  Widget _reviewBody(ThemeData theme, String constellationName) {
    final app = AppScope.of(context);
    final checkIn = app.emotions.forJourneyDay(widget.day);
    final challenge = app.progress.challengeFor(widget.day);
    final isLetterDay = _day.interaction.type == InteractionType.futureLetter;
    final isReplyDay = _day.interaction.type == InteractionType.letterReply;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.star_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '${DayStatus.completed.label} · $constellationName',
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_day.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(_day.intro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Enseñanza', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(_day.teaching),
              const SizedBox(height: 12),
              Text(_day.philosophySource, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                _day.philosophyIdea,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (checkIn != null) ...<Widget>[
          SectionCard(
            child: Row(
              children: <Widget>[
                Icon(iconForEmotion(checkIn.emotion)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ese día te sentías: ${checkIn.emotion.label} '
                    '(${checkIn.intensity}/10)',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(_day.question, style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        if (isLetterDay && app.progress.canRevealLetter)
          SectionCard(
            child: Text(
              (app.progress.readDay1Letter() ?? '').trim().isEmpty
                  ? 'No escribiste una carta el Día 1.'
                  : app.progress.readDay1Letter()!,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else if (isLetterDay)
          InteractionView(
            draft: _draft,
            onChanged: () {},
            readOnly: true,
            letterSealed: true,
          )
        else if (isReplyDay)
          SectionCard(
            child: Text(
              app.progress.day30Reply.isEmpty
                  ? 'Tu respuesta quedó guardada en el diario.'
                  : app.progress.day30Reply,
            ),
          )
        else
          InteractionView(
            draft: _draft,
            onChanged: () {},
            readOnly: true,
            reduceMotion: true,
          ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Microreto: ${_day.challenge.title}',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(app.challengeTextFor(_day)),
              const SizedBox(height: 8),
              Text(
                'Estado: ${(challenge?.status ?? ChallengeStatus.pending).label}',
              ),
              if (challenge?.status != ChallengeStatus.completed) ...<Widget>[
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _setChallenge(ChallengeStatus.completed),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Marcar como completado'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Text(
            _day.closing,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}
