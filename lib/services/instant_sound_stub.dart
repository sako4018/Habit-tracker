import 'dart:typed_data';

/// Незабавен звук през WebAudio — има смисъл само в браузър.
///
/// На телефон и десктоп `audioplayers` вече ползва платформения бърз
/// път (SoundPool и подобни), затова тук всичко е no-op и извикващият
/// пада обратно към него.
class InstantSound {
  static bool get isSupported => false;

  static Future<bool> load(Uint8List bytes, double volume) async => false;

  static void unlock() {}

  static bool play() => false;
}
