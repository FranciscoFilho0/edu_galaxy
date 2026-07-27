import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';

/// Preferências do app que persistem entre sessões: volume da música de
/// fundo, volume da voz (TTS) e o modo noturno do professor.
///
/// Carrega tudo do dispositivo (`SharedPreferences`) assim que o app abre e
/// já aplica no `AudioService`/`TtsService`/`AppTheme` — as telas só leem os
/// getters e chamam os setters, sem se preocupar com persistência.
class SettingsController extends ChangeNotifier {
  static const _keyMusicVolume = 'settings.musicVolume';
  static const _keyTtsVolume = 'settings.ttsVolume';
  static const _keyProfessorDarkMode = 'settings.professorDarkMode';

  double _musicVolume = 0.5;
  double _ttsVolume = 1.0;
  bool _professorDarkMode = false;
  bool _isLoaded = false;

  double get musicVolume => _musicVolume;
  double get ttsVolume => _ttsVolume;
  bool get professorDarkMode => _professorDarkMode;
  bool get isLoaded => _isLoaded;

  SettingsController() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _musicVolume = prefs.getDouble(_keyMusicVolume) ?? 0.5;
    _ttsVolume = prefs.getDouble(_keyTtsVolume) ?? 1.0;
    _professorDarkMode = prefs.getBool(_keyProfessorDarkMode) ?? false;

    await AudioService().setVolume(_musicVolume);
    await TtsService.instance.setVolume(_ttsVolume);
    AppTheme.applyProfessorDarkMode(_professorDarkMode);

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
    await AudioService().setVolume(_musicVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMusicVolume, _musicVolume);
  }

  Future<void> setTtsVolume(double volume) async {
    _ttsVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
    await TtsService.instance.setVolume(_ttsVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTtsVolume, _ttsVolume);
  }

  Future<void> setProfessorDarkMode(bool dark) async {
    _professorDarkMode = dark;
    AppTheme.applyProfessorDarkMode(dark);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProfessorDarkMode, dark);
  }
}
