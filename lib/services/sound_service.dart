import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Кратък звук при завършване на навик.
///
/// Един споделен player, зареден веднъж при стартиране на приложението.
/// Първото докосване иначе има ~1 сек забавяне, докато asset-ът се
/// декодира — тук той вече е в паметта и `playComplete()` звучи веднага.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();

  bool _ready = false;

  /// Извиква се веднъж от `main()` преди `runApp`.
  Future<void> preload() async {
    try {
      // lowLatency режимът държи звука в паметта и го пуска моментално.
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setVolume(0.30);
      await _player.setSource(
        AssetSource('sounds/habit_complete.mp3'),
      );

      _ready = true;
    } catch (e) {
      debugPrint('SoundService preload failed: $e');
    }
  }

  /// Пуска звука за завършен навик. Тих no-op, ако зареждането е
  /// пропаднало или звукът не може да се възпроизведе.
  Future<void> playComplete() async {
    if (!_ready) {
      return;
    }

    try {
      // В lowLatency режим resume() пуска звука отначало всеки път.
      await _player.resume();
    } catch (_) {
      // Отметката работи и без звук.
    }
  }

  Future<void> dispose() => _player.dispose();
}
