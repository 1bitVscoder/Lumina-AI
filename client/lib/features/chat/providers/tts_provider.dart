import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.48); // Slightly slower is cleaner/more natural
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.15); // Slightly higher pitch adds warm, lighthearted humor and emotiveness
      
      // Try to select a natural, network-based high-quality voice
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        for (var voice in voices) {
          if (voice is Map) {
            final name = voice['name']?.toString().toLowerCase() ?? '';
            final locale = voice['locale']?.toString().toLowerCase() ?? '';
            if (locale.contains('en-us') && (name.contains('network') || name.contains('natural') || name.contains('premium'))) {
              await _flutterTts.setVoice({"name": voice['name'], "locale": voice['locale']});
              debugPrint("Selected natural TTS voice: ${voice['name']}");
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error initializing FlutterTts: $e");
    }
  }

  Future<void> speak(String text) async {
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("Error in FlutterTts speak: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("Error in FlutterTts stop: $e");
    }
  }
  
  void setCompletionHandler(VoidCallback callback) {
    _flutterTts.setCompletionHandler(() {
      callback();
    });
  }

  void setErrorHandler(Function(String) callback) {
    _flutterTts.setErrorHandler((message) {
      callback(message);
    });
  }
}

final ttsProvider = Provider<TtsService>((ref) {
  return TtsService();
});
