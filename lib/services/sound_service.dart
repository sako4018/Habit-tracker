import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'instant_sound_stub.dart'
    if (dart.library.js_interop) 'instant_sound_web.dart';

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

  static const _assetPath = 'assets/sounds/habit_complete.mp3';

  static final _asset = AssetSource('sounds/habit_complete.mp3');
  static const _volume = 0.30;

  /// Толкова бързи последователни отмятания могат да звучат наведнъж.
  static const _poolSize = 3;

  final List<AudioPlayer> _pool = [];

  int _next = 0;
  bool _ready = false;
  bool _warmedUp = false;

  /// В браузър звукът върви през WebAudio, а не през audioplayers.
  bool _instant = false;

  /// Извиква се веднъж при стартиране. Не се чака в `main()` — ако
  /// платформеното аудио се бави, приложението не бива да чака с него.
  Future<void> preload() async {
    // В браузър audioplayers пуска звука през <audio> елемент, което е
    // твърде бавно за кратък UI звук. Там ползваме WebAudio директно.
    if (InstantSound.isSupported) {
      try {
        final data = await rootBundle.load(_assetPath);

        _instant = await InstantSound.load(
          data.buffer.asUint8List(),
          _volume,
        );

        if (_instant) {
          _ready = true;
          return;
        }
      } catch (e) {
        debugPrint('InstantSound load failed: $e');
      }
    }

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

  /// Загрява плейърите — трябва да се извика ВЪТРЕ в докосване на
  /// потребителя.
  ///
  /// Браузърите държат AudioContext-а спрян, докато потребителят не
  /// пипне страницата, и го пускат чак при първото истинско пускане на
  /// звук. Този първи път е бавен. Тук го плащаме на първото докосване
  /// някъде в приложението, а не на първото отмятане.
  Future<void> warmUp() async {
    if (_warmedUp || !_ready) {
      return;
    }

    _warmedUp = true;

    if (_instant) {
      InstantSound.unlock();
      return;
    }

    try {
      for (final player in _pool) {
        await player.setVolume(0);
        await player.resume();
        await player.stop();
        await player.setVolume(_volume);
      }
    } catch (_) {}
  }

  /// Пуска звука за отметнат навик. Не се чака — при проблем е тих
  /// no-op, отметката работи и без звук.
  Future<void> playComplete() async {
    try {
      if (_instant && InstantSound.play()) {
        return;
      }

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
