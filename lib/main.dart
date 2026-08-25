import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'screens/root_shell.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(
    DevicePreview(
      // Only wraps the UI in a phone frame for local web debugging.
      // Disabled automatically in release builds.
      enabled: !const bool.fromEnvironment('dart.vm.product'),
      builder: (context) => const HabitTrackerApp(),
    ),
  );
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

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
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,

      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

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

      home: const RootShell(),
    );
  }
}