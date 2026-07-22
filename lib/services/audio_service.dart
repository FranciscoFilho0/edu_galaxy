import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Faixas de música de fundo disponíveis no app.
enum BackgroundTrack { studentHome, games }

/// Controla a música de fundo do app (telas do aluno x telas de jogos).
///
/// É um singleton: existe um único player tocando em loop durante todo o
/// app, e trocamos a faixa (ou paramos) conforme o aluno navega entre a
/// área inicial e os jogos.
class AudioService {
  AudioService._internal();
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();

  static const String _studentHomeAsset = 'audio/fundo-inicial.mp3';
  static const String _gamesAsset = 'audio/fundo-jogos.mp3';

  BackgroundTrack? _currentTrack;
  bool _muted = false;

  bool get isMuted => _muted;

  /// Toca a música da área do aluno (telas com o menu inferior: Base,
  /// Jogos, Ranking, Diversão), em loop.
  Future<void> playStudentHomeMusic() =>
      _play(BackgroundTrack.studentHome, _studentHomeAsset);

  /// Toca a música das telas de jogo (jogos pedagógicos e casuais), em loop.
  Future<void> playGamesMusic() => _play(BackgroundTrack.games, _gamesAsset);

  Future<void> _play(BackgroundTrack track, String asset) async {
    debugPrint('AudioService: pedido para tocar "$asset" (faixa atual: $_currentTrack)');

    // Evita reiniciar a mesma faixa ao navegar entre telas do mesmo grupo.
    if (_currentTrack == track) {
      debugPrint('AudioService: "$asset" já é a faixa atual, ignorando.');
      return;
    }
    _currentTrack = track;

    if (_muted) {
      debugPrint('AudioService: está mutado, não vai tocar "$asset".');
      return;
    }

    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.5);
      await _player.play(AssetSource(asset));
      debugPrint('AudioService: play() de "$asset" concluído sem erro.');
    } catch (e) {
      // TEMPORÁRIO para diagnóstico: mostra no console por que a música
      // não tocou (arquivo não encontrado, formato inválido, etc.).
      // Depois de resolver, pode voltar a deixar isso silencioso.
      debugPrint('AudioService: falha ao tocar "$asset" -> $e');
    }
  }

  /// Para a música de fundo (ex.: ao sair da área do aluno/jogos).
  Future<void> stop() async {
    _currentTrack = null;
    await _player.stop();
  }

  /// Muta/desmuta a música de fundo sem perder qual faixa deveria tocar.
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    if (muted) {
      await _player.stop();
      return;
    }
    final track = _currentTrack;
    if (track == null) return;
    _currentTrack = null; // força o _play a tocar de novo
    await _play(track, track == BackgroundTrack.studentHome ? _studentHomeAsset : _gamesAsset);
  }
}