import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  bool _cashSoundUnlocked = false;
  bool _isUnlocking = false;

  /// Prepara o áudio após uma interação real do usuário.
  ///
  /// Navegadores e iOS/Safari costumam bloquear sons automáticos até que o
  /// usuário toque na tela. Por isso essa função deve ser chamada em eventos
  /// como toque/clique no painel.
  Future<void> unlockCashSound() async {
    if (_cashSoundUnlocked || _isUnlocking) return;

    _isUnlocking = true;

    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0);
      await _player.play(AssetSource('sounds/cash.mp3'));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await _player.stop();
      await _player.setVolume(1);

      _cashSoundUnlocked = true;
    } catch (_) {
      _cashSoundUnlocked = false;

      try {
        await _player.setVolume(1);
      } catch (_) {}
    } finally {
      _isUnlocking = false;
    }
  }

  Future<void> playCashSound() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.stop();
      await _player.setVolume(1);
      await _player.play(AssetSource('sounds/cash.mp3'));
    } catch (_) {
      // Em Web/iOS o navegador pode bloquear áudio sem interação prévia.
      // Não deixamos isso quebrar a tela nem o recebimento da venda.
    }
  }

  void dispose() {
    _player.dispose();
  }
}
