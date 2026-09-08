import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Кратък звук при отмятане на навик.
///
/// Целта е звукът да тръгва в същия кадър, в който пръстът докосва
/// бутона. Три неща го постигат:
///
/// 1. `PlayerMode.lowLatency` — платформата държи звука декодиран в
///    паметта (SoundPool на Android, WebAudio буфер в браузър) вместо
///    да вдига медиен плейър при всяко пускане.
/// 2. Малък пул от плейъри — второ бързо докосване не чака първото да
///    свърши, а взима следващия свободен.
/// 3. Нищо в горещия път освен `resume()`. Няма `seek`, няма
///    зареждане на asset — те са свършени предварително.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  static final _asset = AssetSource('sounds/habit_complete.mp3');
  static const _volume = 0.30;

  /// Толкова бързи последователни отмятания могат да звучат наведнъж.
  static const _poolSize = 3;

  final List<AudioPlayer> _pool = [];

  int _next = 0;
  bool _ready = false;

  /// Извиква се веднъж при стартиране. Не се чака в `main()` — ако
  /// платформеното аудио се бави, приложението не бива да чака с него.
  Future<void> preload() async {
    try {
      for (var i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();

        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(_volume);
        await player.setSource(_asset);

        _pool.add(player);
      }

      _ready = true;
    } catch (e) {
      // Нарочно НЕ пускаме беззвучно "загряване" тук: браузърите
      // отказват звук преди първото докосване на потребителя, и този
      // отказ преди чупеше зареждането, така че всяко следващо пускане
      // минаваше по бавния път.
      debugPrint('SoundService preload failed: $e');
    }
  }

  /// Пуска звука за отметнат навик. Не се чака — при проблем е тих
  /// no-op, отметката работи и без звук.
  Future<void> playComplete() async {
    try {
      if (!_ready || _pool.isEmpty) {
        return;
      }

      final player = _pool[_next];
      _next = (_next + 1) % _pool.length;

      // В lowLatency режим resume() пуска звука отначало всеки път,
      // затова тук няма seek — той е още едно отиване до платформата.
      await player.resume();
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final player in _pool) {
      await player.dispose();
    }

    _pool.clear();
    _ready = false;
  }
}
