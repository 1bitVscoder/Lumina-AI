import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SoundscapeService {
  SoundscapeService._privateConstructor();
  static final SoundscapeService instance = SoundscapeService._privateConstructor();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String _currentTrack = 'none';

  final Map<String, String> _tracks = {
    'rain': 'https://assets.mixkit.co/active_storage/sfx/2433/2433-84.wav',
    'fireplace': 'https://assets.mixkit.co/active_storage/sfx/2432/2432-84.wav',
    'lofi': 'https://assets.mixkit.co/music/preview/mixkit-lofi-band-924.mp3',
  };

  Future<void> init() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.45); // comfortable ambient level
    } catch (e) {
      debugPrint("SoundscapeService init exception: $e");
    }
  }

  Future<void> playTrack(String trackKey) async {
    if (_currentTrack == trackKey) return;
    _currentTrack = trackKey;

    try {
      // Always stop active playback first
      await _audioPlayer.stop();

      if (trackKey == 'none') {
        return;
      }

      final url = _tracks[trackKey];
      if (url != null) {
        await _audioPlayer.play(UrlSource(url));
        debugPrint("Soundscape playing track: $trackKey");
      }
    } catch (e) {
      debugPrint("Error playing soundscape track '$trackKey': $e");
    }
  }

  Future<void> stop() async {
    _currentTrack = 'none';
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint("Error stopping soundscape: $e");
    }
  }
}
