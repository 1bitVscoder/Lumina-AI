import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/soundscape_service.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool autoplayTts;
  final String aiName;
  final String soundscape;

  SettingsState({
    required this.themeMode,
    required this.autoplayTts,
    required this.aiName,
    required this.soundscape,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? autoplayTts,
    String? aiName,
    String? soundscape,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      autoplayTts: autoplayTts ?? this.autoplayTts,
      aiName: aiName ?? this.aiName,
      soundscape: soundscape ?? this.soundscape,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final _storage = const FlutterSecureStorage();

  SettingsNotifier() : super(SettingsState(
    themeMode: ThemeMode.system,
    autoplayTts: false,
    aiName: 'Lumina',
    soundscape: 'none',
  )) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final themeStr = await _storage.read(key: 'theme_mode');
      final ttsStr = await _storage.read(key: 'autoplay_tts');
      final nameStr = await _storage.read(key: 'ai_name');
      final soundscapeStr = await _storage.read(key: 'soundscape');

      ThemeMode themeMode = ThemeMode.system;
      if (themeStr == 'light') themeMode = ThemeMode.light;
      if (themeStr == 'dark') themeMode = ThemeMode.dark;

      final autoplayTts = ttsStr == 'true';
      final aiName = nameStr ?? 'Lumina';
      final soundscape = soundscapeStr ?? 'none';

      state = SettingsState(
        themeMode: themeMode,
        autoplayTts: autoplayTts,
        aiName: aiName,
        soundscape: soundscape,
      );

      // Initialize SoundscapeService and auto-play track if any is selected
      await SoundscapeService.instance.init();
      if (soundscape != 'none') {
        await SoundscapeService.instance.playTrack(soundscape);
      }
    } catch (e) {
      debugPrint("Error loading local settings: $e");
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      String themeStr = 'system';
      if (mode == ThemeMode.light) themeStr = 'light';
      if (mode == ThemeMode.dark) themeStr = 'dark';

      await _storage.write(key: 'theme_mode', value: themeStr);
      state = state.copyWith(themeMode: mode);
    } catch (e) {
      debugPrint("Error saving theme mode settings: $e");
    }
  }

  Future<void> setAutoplayTts(bool value) async {
    try {
      await _storage.write(key: 'autoplay_tts', value: value.toString());
      state = state.copyWith(autoplayTts: value);
    } catch (e) {
      debugPrint("Error saving autoplay settings: $e");
    }
  }

  Future<void> setAiName(String name) async {
    try {
      await _storage.write(key: 'ai_name', value: name);
      state = state.copyWith(aiName: name);
    } catch (e) {
      debugPrint("Error saving locally-cached AI name: $e");
    }
  }

  Future<void> setSoundscape(String trackKey) async {
    try {
      await _storage.write(key: 'soundscape', value: trackKey);
      state = state.copyWith(soundscape: trackKey);
      await SoundscapeService.instance.playTrack(trackKey);
    } catch (e) {
      debugPrint("Error saving soundscape setting: $e");
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      await SoundscapeService.instance.stop();
      state = SettingsState(
        themeMode: ThemeMode.system,
        autoplayTts: false,
        aiName: 'Lumina',
        soundscape: 'none',
      );
    } catch (e) {
      debugPrint("Error clearing secure storage settings: $e");
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
