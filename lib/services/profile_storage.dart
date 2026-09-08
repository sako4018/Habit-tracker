import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Управлява данните на потребителския профил:
/// име и профилна снимка (запазена като base64 текст).
///
/// nameNotifier и photoNotifier позволяват на всеки екран
/// (Home, Settings и т.н.) да реагира МОМЕНТАЛНО на промяна
/// на профила, без нужда от ръчно презареждане на приложението.
class ProfileStorage {
  ProfileStorage._();

  static const String _nameKey = 'user_name';
  static const String _photoKey = 'user_photo_base64';

  static final ValueNotifier<String> nameNotifier =
      ValueNotifier<String>('');

  static final ValueNotifier<Uint8List?> photoNotifier =
      ValueNotifier<Uint8List?>(null);

  /// Зарежда запазените данни от диска в notifier-ите.
  /// Извиква се веднъж при стартиране на приложението.
  static Future<void> loadIntoNotifiers() async {
    nameNotifier.value = await getName();

    final photoBase64 = await getPhotoBase64();

    photoNotifier.value =
        photoBase64 != null ? base64Decode(photoBase64) : null;
  }

  /// Връща текущото име на потребителя.
  static Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? '';
  }

  /// Запазва ново име и веднага обновява nameNotifier.
  static Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);

    nameNotifier.value = name;
  }

  /// Връща снимката като base64 текст (или null, ако няма запазена).
  static Future<String?> getPhotoBase64() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_photoKey);
  }

  /// Запазва снимка, подадена като байтове, и веднага обновява photoNotifier.
  static Future<void> setPhotoBytes(List<int> bytes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = base64Encode(bytes);
    await prefs.setString(_photoKey, encoded);

    photoNotifier.value = Uint8List.fromList(bytes);
  }

  /// Изтрива запазената снимка.
  static Future<void> clearPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoKey);

    photoNotifier.value = null;
  }
}