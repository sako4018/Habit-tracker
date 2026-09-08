import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Незабавен звук в браузър.
///
/// `audioplayers` на web пуска звука през `<audio>` елемент, вкаран в
/// WebAudio граф. За кратък UI звук това е бавно: всяко пускане минава
/// през `currentTime = 0` (истинско превъртане на медиен елемент) и
/// после `play()`, който е обещание, а не моментално действие.
///
/// Тук звукът се декодира ВЕДНЪЖ в AudioBuffer и всяко пускане е нов
/// AudioBufferSourceNode — това е най-бързото, което браузърът дава.
class InstantSound {
  InstantSound._();

  static web.AudioContext? _ctx;
  static web.AudioBuffer? _buffer;
  static web.GainNode? _gain;

  static bool get isSupported => true;

  /// Декодира звука веднъж. Може да се извика преди докосване —
  /// декодирането не изисква жест, само пускането изисква.
  static Future<bool> load(Uint8List bytes, double volume) async {
    try {
      final ctx = _ctx ??= web.AudioContext();

      final gain = _gain ??= ctx.createGain();
      gain.gain.value = volume;
      gain.connect(ctx.destination);

      // decodeAudioData иска ArrayBuffer, който няма да бъде ползван
      // после — затова копие, а не изглед към паметта на Dart.
      final data = Uint8List.fromList(bytes);

      _buffer = await ctx.decodeAudioData(data.buffer.toJS).toDart;

      return _buffer != null;
    } catch (_) {
      return false;
    }
  }

  /// Пуска AudioContext-а. Браузърът го държи спрян до първи жест на
  /// потребителя, затова това трябва да се вика вътре в докосване.
  static void unlock() {
    final ctx = _ctx;

    if (ctx != null && ctx.state == 'suspended') {
      ctx.resume();
    }
  }

  /// Пуска звука. Връща false, ако още не е зареден — тогава
  /// извикващият пада обратно към `audioplayers`.
  static bool play() {
    final ctx = _ctx;
    final buffer = _buffer;
    final gain = _gain;

    if (ctx == null || buffer == null || gain == null) {
      return false;
    }

    try {
      if (ctx.state == 'suspended') {
        ctx.resume();
      }

      final source = ctx.createBufferSource();
      source.buffer = buffer;
      source.connect(gain);
      source.start();

      return true;
    } catch (_) {
      return false;
    }
  }
}
