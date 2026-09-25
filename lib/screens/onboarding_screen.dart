import 'package:flutter/material.dart';

import '../data/journey_goals.dart';
import '../models/life_stage.dart';
import '../widgets/app_scope.dart';
import '../widgets/sky_background.dart';

/// Onboarding breve de 5 pantallas. Solo se muestra la primera vez
/// (o después de borrar todos los datos).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  int _index = 0;
  LifeStage? _stage;
  String? _goal;
  bool _saving = false;

  static const int _pageCount = 5;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _canContinue => _index != 2 || _stage != null;

  Future<void> _go(int index) async {
    setState(() => _index = index);
    final reduce = AppScope.read(context).settings.reduceMotion;
    if (reduce) {
      _pages.jumpToPage(index);
    } else {
      await _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    final stage = _stage;
    if (stage == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    await AppScope.read(context).completeOnboarding(stage: stage, goal: _goal);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    _welcomePage(theme),
                    _journeyPage(theme),
                    _stagePage(theme),
                    _goalPage(theme),
                    _finalPage(theme),
                  ],
                ),
              ),
              _dots(theme),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Row(
                  children: <Widget>[
                    if (_index > 0)
                      TextButton(
                        onPressed: () => _go(_index - 1),
                        child: const Text('Atrás'),
                      ),
                    const Spacer(),
                    if (_index < _pageCount - 1)
                      FilledButton(
                        key: const ValueKey<String>('onboarding-next'),
                        onPressed: _canContinue ? () => _go(_index + 1) : null,
                        child: Text(_index == 3 && _goal == null
                            ? 'Continuar sin elegir'
                            : 'Siguiente'),
                      )
                    else
                      FilledButton.icon(
                        key: const ValueKey<String>('onboarding-start'),
                        onPressed: _saving ? null : _finish,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Comenzar mi viaje'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dots(ThemeData theme) {
    return Semantics(
      label: 'Paso ${_index + 1} de $_pageCount',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var i = 0; i < _pageCount; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _index
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _page({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _welcomePage(ThemeData theme) {
    return _page(
      children: <Widget>[
        const SizedBox(height: 40),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 132,
              height: 132,
              semanticLabel: 'Árbol con raíces bajo un cielo de estrellas',
            ),
          ),
        ),
        const SizedBox(height: 32),
        Semantics(
          header: true,
          child: Text(
            'Raíces y Estrellas',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Un viaje personal de 30 días para descubrir más de la persona '
          'que ya eres.',
          style: theme.textTheme.titleLarge?.copyWith(height: 1.4),
        ),
      ],
    );
  }

  Widget _journeyPage(ThemeData theme) {
    Widget item(IconData icon, String title, String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(text, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _page(
      children: <Widget>[
        Text('Cómo funciona', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 28),
        item(
          Icons.calendar_month_outlined,
          '30 días',
          'Un recorrido en cuatro constelaciones, a tu ritmo.',
        ),
        item(
          Icons.self_improvement,
          'Cada día',
          'Una reflexión, una pequeña acción y tu progreso visual.',
        ),
        item(
          Icons.park_outlined,
          'Tu cielo y tu árbol',
          'Verás crecer tu árbol, encender estrellas y formar '
              'constelaciones.',
        ),
        item(
          Icons.lock_outline,
          'Privado',
          'Todo se guarda solo en este dispositivo. Sin cuentas.',
        ),
      ],
    );
  }

  Widget _stagePage(ThemeData theme) {
    return _page(
      children: <Widget>[
        Text(
          '¿En qué etapa de tu vida estás?',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Adaptaremos ejemplos y microretos. Puedes cambiarlo en Ajustes.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        for (final stage in LifeStage.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionCard(
              key: ValueKey<String>('stage-${stage.key}'),
              title: stage.label,
              subtitle: stage.focus,
              selected: _stage == stage,
              onTap: () => setState(() => _stage = stage),
            ),
          ),
      ],
    );
  }

  Widget _goalPage(ThemeData theme) {
    return _page(
      children: <Widget>[
        Text(
          '¿Qué te gustaría encontrar en este viaje?',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Es opcional. Toca de nuevo para quitar la selección.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        for (final goal in journeyGoals)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionCard(
              title: goal,
              selected: _goal == goal,
              onTap: () => setState(() => _goal = _goal == goal ? null : goal),
            ),
          ),
      ],
    );
  }

  Widget _finalPage(ThemeData theme) {
    return _page(
      children: <Widget>[
        const SizedBox(height: 60),
        Center(
          child: Icon(
            Icons.park_rounded,
            size: 72,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'No se trata de convertirte en otra persona. Se trata de descubrir '
          'más de la persona que ya eres.',
          style: theme.textTheme.headlineSmall?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 20),
        Text(
          'Esta app acompaña tu bienestar, pero no sustituye la ayuda de '
          'profesionales de salud.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.16)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
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
