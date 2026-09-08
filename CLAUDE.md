# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                       # install dependencies

flutter run -d chrome                 # run in the browser (see "phone frame" below)
flutter run -d chrome --web-port 5599 # fixed port

flutter test                          # run all tests
flutter test test/state/app_state_test.dart              # one file
flutter test --plain-name "clearAllData изчиства"        # one test by name

flutter analyze                       # static analysis / lints (must be clean before commit)

flutter build web --no-tree-shake-icons   # web build
flutter build apk                         # Android
```

### Running as a phone in the browser

The app wraps itself in `DevicePreview` (enabled whenever `!kReleaseMode`), so
`flutter run -d chrome` already renders inside a selectable phone frame with a
device picker — no Chrome DevTools device-mode needed. The frame only appears in
debug/profile builds; release builds render full-screen.

### Windows desktop build

`flutter run -d windows` currently fails: the transitive
`flutter_local_notifications_windows` plugin needs the Visual Studio
**"C++ ATL for latest v143 build tools"** individual component (`atlbase.h`).
Install it from the Visual Studio Installer, or just use `-d chrome` / Android.

## Architecture

Flutter (Material 3), Dart 3. The UI language is Bulgarian.

### State: one `AppState`, provided above `MaterialApp`

`lib/state/app_state.dart` is the single source of truth for habits and tasks.
It is a `ChangeNotifier` registered with a single `ChangeNotifierProvider` in
`HabitTrackerApp.build` (`lib/main.dart`), wrapping `MaterialApp` so pushed
routes (calendar, year view) can reach it too.

- Screens **read** with `context.watch<AppState>()` and **mutate** with
  `context.read<AppState>().someMethod(...)`. Nothing is passed screen-to-screen
  as data props — `RootShell` is just the bottom navigation.
- Every mutation calls `notifyListeners()` and then persists to disk.
- Mutation methods take primitives, not widgets/BuildContext — dialogs live in
  the screens (`HomeScreen._showAddHabitDialog` builds the `Habit`'s data and
  calls `appState.addHabit(name:, emoji:)`).
- `test/home_screen_repaint_test.dart` exists specifically to catch
  watch/read/repaint regressions that unit tests miss.

### Storage: corruption is not the same as "empty"

`lib/services/habit_storage.dart` / `task_storage.dart` back a JSON blob in
`SharedPreferences`. Two deliberate safety rules:

1. `load()` returns `[]` **only** when there is no saved data. If saved data
   exists but can't be parsed, it copies the raw string to a `*_corrupt_backup`
   key and throws `StorageException` (`lib/services/storage_exception.dart`).
2. `save([])` refuses to overwrite existing non-empty data unless
   `allowEmpty: true`. Intentional wipes go through `clearAll()` / `clear()`.

`AppState.load()` catches `StorageException` and sets `storageLocked = true`;
while locked, `_persistHabits()` / `_persistTasks()` are no-ops so recoverable
data is never clobbered. `RootShell` watches `storageLocked` and shows a
one-time SnackBar. `AppState.clearAllData()` calls the direct `clearAll()` /
`clear()` methods, never the guarded `save()`.

### Singleton services, preloaded in `main()`

`main()` awaits each of these before `runApp` (except sound — see below):

- `NotificationService.instance` — `flutter_local_notifications` + `timezone`;
  `initialize()` is idempotent, and scheduling a reminder cancels the previous
  one first so there are never two.
- `ProfileStorage` — static, exposes `nameNotifier` / `photoNotifier`
  (`ValueNotifier`s) that screens listen to directly; photo stored as base64.
- `AccentColorController.instance` — `ValueNotifier<Color>`; `HabitTrackerApp`
  wraps `MaterialApp` in a `ValueListenableBuilder` on it, so changing the
  accent in Settings recolours the whole app live. `AppColors.accent` is a
  getter off this controller (so it is **not** `const` — widgets that use it
  can't be `const`).
- `SoundService.instance` — one shared `audioplayers` player, preloaded and
  "warmed" with a silent play so the completion sound has no first-tap delay.
  `preload()` is **not** awaited in `main()` — audio init must never block or
  hang app startup.

### Models carry the domain logic

`Habit` (`lib/models/habit.dart`) owns `currentStreak`, `bestStreak`,
`last7Days`, `toggle(date)`, and JSON. Streak logic is date-key based
(`yyyy-MM-dd` strings via `Habit.keyFor`). `Task` is a dated one-off with
`isForDate` / `toggle`. These are plain classes — keep new domain rules here,
covered by `test/models/`.

## Conventions

- `flutter analyze` must report no issues before every commit.
- The repo has a template line-ending setup; `LF will be replaced by CRLF`
  warnings on commit are expected and harmless.
