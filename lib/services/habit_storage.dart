import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

class HabitStorage {
  static const _storageKey = 'habits_data_v2';

  static Future<List<Habit>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.isEmpty) {
        return [];
      }

      final List decoded = jsonDecode(raw) as List;

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => Habit.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> save(List<Habit> habits) async {
    try {
      final prefs = await SharedPreferences.getInstance();

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