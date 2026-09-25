import 'package:flutter/material.dart';

import '../widgets/sky_background.dart';

import 'home_screen.dart';
import 'journal_screen.dart';
import 'journey_screen.dart';
import 'meditate_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

/// Pestañas principales de la navegación.
enum AppTab { home, today, journey, meditate, journal, settings }

/// Navegación principal: Inicio, Hoy, Mi Viaje, Medítate, Diario y Ajustes.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  /// Cambia de pestaña desde cualquier pantalla descendiente.
  static void goTo(BuildContext context, AppTab tab) {
    context.findAncestorStateOfType<HomeShellState>()?.select(tab);
  }

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  AppTab _tab = AppTab.home;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    TodayScreen(),
    JourneyScreen(),
    MeditateScreen(),
    JournalScreen(),
    SettingsScreen(),
  ];

  void select(AppTab tab) {
    if (tab != _tab) {
      setState(() => _tab = tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        child: IndexedStack(
          index: _tab.index,
          children: <Widget>[
            for (var i = 0; i < _pages.length; i++)
              TickerMode(enabled: i == _tab.index, child: _pages[i]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: (i) => select(AppTab.values[i]),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            key: ValueKey<String>('nav-home'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            key: ValueKey<String>('nav-today'),
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny_rounded),
            label: 'Hoy',
          ),
          NavigationDestination(
            key: ValueKey<String>('nav-journey'),
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Mi Viaje',
          ),
          NavigationDestination(
            key: ValueKey<String>('nav-meditate'),
            icon: Icon(Icons.self_improvement_outlined),
            selectedIcon: Icon(Icons.self_improvement),
            label: 'Medítate',
          ),
          NavigationDestination(
            key: ValueKey<String>('nav-journal'),
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Diario',
          ),
          NavigationDestination(
            key: ValueKey<String>('nav-settings'),
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
