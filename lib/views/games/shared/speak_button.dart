import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/tts_service.dart';

/// Botão de alto-falante reutilizável para qualquer jogo de palavras.
///
/// Ao ser tocado, pede ao [TtsService] para falar [textToSpeak] e mostra
/// uma pequena animação de "pulso" enquanto a fala está em andamento.
class SpeakButton extends StatefulWidget {
  /// Texto que será falado ao tocar no botão.
  final String textToSpeak;

  /// Tamanho do ícone. Padrão adequado para ficar ao lado de um cartão de dica.
  final double size;

  const SpeakButton({
    super.key,
    required this.textToSpeak,
    this.size = 22,
  });

  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton> {
  bool _speaking = false;

  Future<void> _handleTap() async {
    if (_speaking) return;
    setState(() => _speaking = true);
    await TtsService.instance.speak(widget.textToSpeak);
    // A duração da fala não é reportada de forma síncrona pelo plugin em
    // todas as plataformas, então usamos um pequeno cooldown visual para
    // impedir toques repetidos que sobrepõem a voz.
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _speaking ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: widget.size + 20,
          height: widget.size + 20,
          decoration: BoxDecoration(
            color: AppTheme.galaxyCyan.withOpacity(_speaking ? 0.35 : 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.galaxyCyan.withOpacity(0.5)),
          ),
          child: Icon(
            _speaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
            color: AppTheme.galaxyCyan,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
