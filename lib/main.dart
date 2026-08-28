import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'theme/app_colors.dart';

void main() {
  DevicePreview.enable();

  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() =>
      _HabitTrackerAppState();
}

class _HabitTrackerAppState
    extends State<HabitTrackerApp> {
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs =
        await SharedPreferences.getInstance();

    final isLoggedIn =
        prefs.getBool('is_logged_in') ?? false;

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoggedIn = isLoggedIn;
      _loading = false;
    });
  }

  void _login() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onPrimary: Colors.black,
      onSurface: Colors.white,
      error: Colors.redAccent,
    );

    return MaterialApp(
      title: 'Streakly',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,

        scaffoldBackgroundColor:
            AppColors.background,

        cardColor: AppColors.surface,

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
        ),

        textTheme: ThemeData.dark()
            .textTheme
            .apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),

        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.surface,
        ),

        bottomNavigationBarTheme:
            const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),

      themeMode: ThemeMode.dark,

      home: _loading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                ),
              ),
            )
          : _isLoggedIn
              ? const RootShell()
              : LoginScreen(
                  onLogin: _login,
                ),
    );
  }
}
