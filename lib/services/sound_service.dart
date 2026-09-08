import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Кратък звук при завършване на навик.
///
/// Един споделен player, зареден и „загрят" веднъж при стартиране.
/// Първото възпроизвеждане иначе минава през декодиране + инициализация
/// на платформения плейър (~1 сек); тук това се случва предварително,
/// така че `playComplete()` звучи веднага.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  static final _asset = AssetSource('sounds/habit_complete.mp3');
  static const _volume = 0.30;

  final AudioPlayer _player = AudioPlayer();

  bool _ready = false;

  /// Извиква се веднъж от `main()` преди `runApp`.
  Future<void> preload() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setSource(_asset);
      await _player.setVolume(_volume);

      // Загряваме целия аудио конвейер с едно беззвучно възпроизвеждане,
      // за да няма забавяне при първото истинско докосване.
      await _player.setVolume(0);
      await _player.resume();
      await _player.stop();
      await _player.seek(Duration.zero);
      await _player.setVolume(_volume);

      _ready = true;
    } catch (e) {
      debugPrint('SoundService preload failed: $e');
    }
  }

  /// Пуска звука за завършен навик. Тих no-op при проблем — отметката
  /// работи и без звук.
  Future<void> playComplete() async {
    try {
      if (_ready) {
        await _player.seek(Duration.zero);
        await _player.resume();
      } else {
        // Резервен вариант, ако загряването е пропаднало.
        await _player.play(_asset, volume: _volume);
      }
    } catch (_) {}
  }

  Future<void> dispose() => _player.dispose();
}
