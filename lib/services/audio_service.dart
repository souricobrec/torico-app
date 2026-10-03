import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  AudioService({Future<void> Function()? play, void Function()? dispose})
    : _testPlay = play,
      _testDispose = dispose;

  AudioPlayer? _player;
  final Future<void> Function()? _testPlay;
  final void Function()? _testDispose;
  static const preferenceKey = 'sales_sound_enabled';
  bool enabled = false;
  bool _unlocked = false;
  bool _activating = false;

  Future<void> loadPreference() async {
    enabled =
        (await SharedPreferences.getInstance()).getBool(preferenceKey) ?? false;
  }

  Future<void> _play() async {
    if (_testPlay != null) return _testPlay();
    final player = _player ??= AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.stop();
    await player.setVolume(1);
    await player.play(AssetSource('sounds/cash.mp3'));
  }

  /// Call only from the explicit sound button. Browsers can require a new
  /// gesture after reopening the app even when the preference is saved.
  Future<bool> activate() async {
    if (_activating) return false;
    _activating = true;
    try {
      await _play();
      _unlocked = true;
      enabled = true;
      await (await SharedPreferences.getInstance()).setBool(
        preferenceKey,
        true,
      );
      return true;
    } catch (_) {
      _unlocked = false;
      return false;
    } finally {
      _activating = false;
    }
  }

  bool get ready => enabled && _unlocked;

  Future<void> playCashSound() async {
    if (!ready) return;
    try {
      await _play();
    } catch (_) {
      _unlocked = false;
    }
  }

  void dispose() {
    _player?.dispose();
    _testDispose?.call();
  }
}
