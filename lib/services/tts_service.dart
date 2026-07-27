import 'package:flutter_tts/flutter_tts.dart';

/// Serviço central de Text-to-Speech do app.
///
/// Encapsula o [FlutterTts] com uma configuração única (português do Brasil,
/// velocidade reduzida para facilitar a compreensão por crianças) para que
/// todos os jogos falem da mesma forma, sem duplicar configuração.
class TtsService {
  TtsService._internal();
  static final TtsService instance = TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;
  double _volume = 1.0;

  double get volume => _volume;

  /// Define o volume da voz (0.0 a 1.0) e aplica imediatamente. Quem
  /// persiste essa escolha entre sessões é o `SettingsController`.
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_initialized) {
      await _tts.setVolume(_volume);
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.setLanguage('pt-BR');
    // Um pouco mais lento que o padrão (1.0) para facilitar a compreensão
    // por crianças que ainda estão aprendendo a ler.
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(_volume);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) => _isSpeaking = false);

    _initialized = true;
  }

  /// Fala o [text] em voz alta. Se já estiver falando algo, interrompe antes
  /// de começar a nova fala (evita sobreposição de vozes).
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInitialized();
    if (_isSpeaking) {
      await _tts.stop();
    }
    await _tts.speak(text);
  }

  /// Para qualquer fala em andamento. Útil ao trocar de rodada ou sair da tela.
  Future<void> stop() async {
    if (!_initialized) return;
    await _tts.stop();
    _isSpeaking = false;
  }
}
