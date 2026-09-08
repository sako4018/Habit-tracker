import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import 'storage_exception.dart';

class HabitStorage {
  static const _storageKey = 'habits_data_v2';
  static const _corruptBackupKey = 'habits_data_v2_corrupt_backup';

  /// Зарежда навиците от диска.
  ///
  /// Връща празен списък САМО когато няма запазени данни. Ако данните
  /// съществуват, но са повредени, хвърля [StorageException] и запазва
  /// копие на суровия текст под [_corruptBackupKey] — така приложението
  /// може да спре записите и данните да не бъдат изтрити.
  static Future<List<Habit>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final List decoded = jsonDecode(raw) as List;

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => Habit.fromJson(e))
          .toList();
    } catch (e) {
      await prefs.setString(_corruptBackupKey, raw);

      throw StorageException(
        'Навиците не можаха да бъдат прочетени: $e',
        backupKey: _corruptBackupKey,
      );
    }
  }

  /// Запазва навиците.
  ///
  /// По подразбиране отказва да презапише съществуващи данни с празен
  /// списък — това предпазва от изтриване при бъг. За умишлено изчистване
  /// подай [allowEmpty] = true (или ползвай [clearAll]).
  static Future<bool> save(
    List<Habit> habits, {
    bool allowEmpty = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (habits.isEmpty && !allowEmpty) {
        final existing = prefs.getString(_storageKey);

        if (existing != null && existing.isNotEmpty && existing != '[]') {
          return false;
        }
      }

      final raw = jsonEncode(
        habits.map((h) => h.toJson()).toList(),
      );

      return await prefs.setString(_storageKey, raw);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      return false;
    }
  }
}
