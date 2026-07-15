import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class GameAudioController {
  GameAudioController({
    this.backgroundVolume = 0.18,
    this.successVolume = 0.58,
  }) {
    _ignoreAudioErrors(_backgroundPlayer.setReleaseMode(ReleaseMode.loop));
    _ignoreAudioErrors(_successPlayer.setReleaseMode(ReleaseMode.stop));
  }

  static final AssetSource _backgroundSource = AssetSource(
    'audio/calm_loop.wav',
  );
  static final AssetSource _successSource = AssetSource(
    'audio/match_success.wav',
  );

  final double backgroundVolume;
  final double successVolume;
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  bool _backgroundPlaying = false;

  void setPlaying(bool playing) {
    if (playing) {
      _startBackground();
    } else {
      _stopBackground();
    }
  }

  void playSuccess() {
    _ignoreAudioErrors(
      _successPlayer.stop().then((_) {
        return _successPlayer.play(_successSource, volume: successVolume);
      }),
    );
  }

  void _startBackground() {
    if (_backgroundPlaying) {
      return;
    }
    _backgroundPlaying = true;
    _ignoreAudioErrors(
      _backgroundPlayer.play(_backgroundSource, volume: backgroundVolume),
    );
  }

  void _stopBackground() {
    if (!_backgroundPlaying) {
      return;
    }
    _backgroundPlaying = false;
    _ignoreAudioErrors(_backgroundPlayer.stop());
  }

  void _ignoreAudioErrors(Future<void> future) {
    unawaited(future.catchError((Object _) {}));
  }

  Future<void> dispose() async {
    await Future.wait([
      _backgroundPlayer.dispose().catchError((Object _) {}),
      _successPlayer.dispose().catchError((Object _) {}),
    ]);
  }
}
