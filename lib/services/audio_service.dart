import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playCashSound() async {
    await _player.play(AssetSource('sounds/cash.mp3'));
  }

  void dispose() {
    _player.dispose();
  }
}
