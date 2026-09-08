import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import 'storage_exception.dart';

class TaskStorage {
  static const String _key = 'tasks';
  static const String _corruptBackupKey = 'tasks_corrupt_backup';

  /// Зарежда задачите от диска. Връща празен списък само когато няма
  /// запазени данни; при повреден JSON хвърля [StorageException] и
  /// запазва копие на суровия текст за възстановяване.
  static Future<List<Task>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(data);

      return decoded
          .map(
            (item) => Task.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (e) {
      await prefs.setString(_corruptBackupKey, data);

      throw StorageException(
        'Задачите не можаха да бъдат прочетени: $e',
        backupKey: _corruptBackupKey,
      );
    }
  }

  /// Запазва задачите. По подразбиране отказва да презапише съществуващи
  /// данни с празен списък; за умишлено изчистване ползвай [clear].
  static Future<void> save(
    List<Task> tasks, {
    bool allowEmpty = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (tasks.isEmpty && !allowEmpty) {
      final existing = prefs.getString(_key);

      if (existing != null && existing.isNotEmpty && existing != '[]') {
        return;
      }
    }

    final data = tasks
        .map((task) => task.toJson())
        .toList();

    await prefs.setString(
      _key,
      jsonEncode(data),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }
}
