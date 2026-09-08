import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'services/notification_service.dart';
import 'services/profile_storage.dart';
import 'services/sound_service.dart';
import 'state/app_state.dart';
import 'theme/accent_color_controller.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Стартираме системата за известия преди приложението.
  await NotificationService.instance.initialize();

  // Зареждаме профилните данни (име и снимка).
  await ProfileStorage.loadIntoNotifiers();

  // Зареждаме запазения accent цвят.
  await AccentColorController.instance.load();

  // Зареждаме звука предварително, но БЕЗ await — стартът на
  // приложението не бива да чака (и да зависва) заради аудиото.
  SoundService.instance.preload();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const HabitTrackerApp(),
    ),
  );
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();

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
    // AppState пази навиците и задачите за цялото приложение.
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState()..load(),
      // ValueListenableBuilder кара цялото приложение да се пребоядисва
      // веднага щом accent цветът се смени от Settings.
      child: ValueListenableBuilder<Color>(
        valueListenable: AccentColorController.instance.notifier,
        builder: (context, accent, _) {
        final colorScheme = ColorScheme.dark(
          primary: accent,
          secondary: accent,
          surface: AppColors.surface,
          onPrimary: Colors.black,
          onSurface: Colors.white,
          error: Colors.redAccent,
        );

        return MaterialApp(
          title: 'Streakly',

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
                FloatingActionButtonThemeData(
              backgroundColor: accent,
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
                BottomNavigationBarThemeData(
              backgroundColor: AppColors.surface,
              selectedItemColor: accent,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
            ),
          ),

          themeMode: ThemeMode.dark,

          home: _loading
              ? Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: accent,
                    ),
                  ),
                )
              : _isLoggedIn
                  ? const RootShell()
                  : LoginScreen(
                      onLogin: _login,
                    ),
          );
        },
      ),
    );
  }
}