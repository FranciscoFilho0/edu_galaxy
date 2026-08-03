import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Faixas de música de fundo disponíveis no app.
enum BackgroundTrack { studentHome, games }

/// Serviço central de áudio do EduGalaxy.
///
/// Possui:
/// - Player exclusivo para música de fundo.
/// - Player exclusivo para efeitos sonoros.
///
/// Os dois funcionam simultaneamente.
class AudioService {
  AudioService._internal();

  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;


  // ===========================================================
  // PLAYERS
  // ===========================================================

  final AudioPlayer _backgroundPlayer = AudioPlayer();

  final AudioPlayer _sfxPlayer = AudioPlayer();


  // ===========================================================
  // ASSETS
  // ===========================================================

  static const String _studentHomeAsset =
      'audio/fundo-inicial.mp3';

  static const String _gamesAsset =
      'audio/fundo-jogos.mp3';


  static const String _successAsset =
      'audio/success.mp3';

  static const String _errorAsset =
      'audio/error.mp3';

  static const String _congratulationsAsset =
      'audio/congratulations.mp3';


  // ===========================================================
  // CONTROLE
  // ===========================================================

  BackgroundTrack? _currentTrack;

  bool _muted = false;

  double _volume = 0.5;


  bool get isMuted => _muted;

  double get volume => _volume;



  // ===========================================================
  // CONFIGURAÇÃO INICIAL
  // ===========================================================

  Future<void> initialize() async {

    await _backgroundPlayer.setReleaseMode(
      ReleaseMode.loop,
    );


    await _backgroundPlayer.setVolume(
      _volume,
    );


    // Permite tocar efeitos junto com a música
    await _sfxPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ),
    );


    debugPrint(
      "AudioService inicializado",
    );
  }



  // ===========================================================
  // MÚSICA DE FUNDO
  // ===========================================================


  Future<void> playStudentHomeMusic() {

    return _play(
      BackgroundTrack.studentHome,
      _studentHomeAsset,
    );

  }



  Future<void> playGamesMusic() {

    return _play(
      BackgroundTrack.games,
      _gamesAsset,
    );

  }



  Future<void> _play(
    BackgroundTrack track,
    String asset,
  ) async {


    if (_currentTrack == track) {
      return;
    }


    _currentTrack = track;


    if (_muted) {
      return;
    }



    try {

      await _backgroundPlayer.stop();


      await _backgroundPlayer.setReleaseMode(
        ReleaseMode.loop,
      );


      await _backgroundPlayer.setVolume(
        _volume,
      );


      await _backgroundPlayer.play(
        AssetSource(asset),
      );


      debugPrint(
        "Música iniciada: $asset",
      );


    } catch(e){

      debugPrint(
        "Erro música: $e",
      );

    }

  }



  // ===========================================================
  // EFEITOS SONOROS
  // ===========================================================


  Future<void> _playEffect(
    String asset,
  ) async {

    try {


      await _sfxPlayer.stop();


      await _sfxPlayer.play(
        AssetSource(asset),
      );


    } catch(e){

      debugPrint(
        "Erro efeito $asset : $e",
      );

    }

  }



  Future<void> playSuccess() {

    return _playEffect(
      _successAsset,
    );

  }



  Future<void> playError() {

    return _playEffect(
      _errorAsset,
    );

  }



  Future<void> playCongratulations() {

    return _playEffect(
      _congratulationsAsset,
    );

  }



  // ===========================================================
  // VOLUME / MUDO
  // ===========================================================


  Future<void> setVolume(
    double value,
  ) async {

    _volume =
        value.clamp(0.0, 1.0);


    if(!_muted){

      await _backgroundPlayer.setVolume(
        _volume,
      );

    }

  }




  Future<void> setMuted(
    bool muted,
  ) async {


    _muted = muted;


    if(muted){

      await _backgroundPlayer.pause();

      return;

    }



    if(_currentTrack != null){

      await _backgroundPlayer.resume();

    }

  }




  Future<void> stop() async {

    _currentTrack = null;

    await _backgroundPlayer.stop();

  }




  // ===========================================================
  // FINALIZAÇÃO
  // ===========================================================


  Future<void> dispose() async {

    await _backgroundPlayer.dispose();

    await _sfxPlayer.dispose();

  }

}