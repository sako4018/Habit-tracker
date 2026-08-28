import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskStorage {
  static const String _key = 'tasks';

  static Future<List<Task>> load() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_key);

    if (data == null || data.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(data);

    return decoded
        .map(
          (item) => Task.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static Future<void> save(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();

    final data = tasks
        .map((task) => task.toMap())
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
