import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundEffectService {
  SoundEffectService._();

  static final SoundEffectService instance =
      SoundEffectService._();

  final AudioPlayer _effectPlayer = AudioPlayer();

  static const String _success =
      'audio/success.mp3';

  static const String _error =
      'audio/error.mp3';

  static const String _congratulations =
      'audio/congratulations.mp3';


  Future<void> playSuccess() async {
    await _play(_success);
  }


  Future<void> playError() async {
    await _play(_error);
  }


  Future<void> playCongratulations() async {
    await _play(_congratulations);
  }


  Future<void> _play(String file) async {
    try {

      await _effectPlayer.stop();

      await _effectPlayer.setVolume(1);

      await _effectPlayer.play(
        AssetSource(file),
      );

    } catch(e){

      debugPrint(
        'Erro efeito sonoro: $e'
      );

    }
  }
}