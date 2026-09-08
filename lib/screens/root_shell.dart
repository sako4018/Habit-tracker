import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// Долната навигация с трите основни екрана. Данните живеят в AppState,
/// затова тук няма нищо освен избрания таб.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tabIndex = 0;

  /// Показваме предупреждението за повредени данни само веднъж.
  bool _shownStorageWarning = false;

  static const _screens = [
    HomeScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final storageLocked = context.watch<AppState>().storageLocked;

    if (storageLocked && !_shownStorageWarning) {
      _shownStorageWarning = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Запазените данни са повредени. Записът е спрян, '
              'за да не се изтрият. Рестартирай приложението.',
            ),
            duration: Duration(seconds: 8),
          ),
        );
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) {
          setState(() {
            _tabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.checklist_rtl,
            ),
            label: 'Днес',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.bar_chart,
            ),
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
            ),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
