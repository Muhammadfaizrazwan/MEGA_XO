import 'package:audioplayers/audioplayers.dart';

class BackgroundMusic {
  final player = AudioPlayer();

  Future<void> playLoop() async {
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('audio/backsound.mp3'));
  }

  Future<void> stop() async {
    await player.stop();
  }

  static Future<void> play() async {}
}