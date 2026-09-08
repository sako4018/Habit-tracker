/// Хвърля се когато запазените данни съществуват, но не могат да бъдат
/// прочетени (повреден JSON, несъвместим формат и т.н.).
///
/// Важно е това да НЕ се бърка с "няма запазени данни" — при повреда
/// приложението не бива да презаписва диска с празен списък, защото
/// така би изтрило възстановими данни завинаги.
class StorageException implements Exception {
  final String message;

  /// Ключът в SharedPreferences, под който е запазено копие на
  /// повредените сурови данни (за ръчно възстановяване).
  final String? backupKey;

  StorageException(this.message, {this.backupKey});

  @override
  String toString() => 'StorageException: $message';
}
