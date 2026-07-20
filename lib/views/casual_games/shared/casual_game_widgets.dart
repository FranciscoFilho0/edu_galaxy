import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Os jogos livres contra o computador ou em dupla usam sempre os dois
/// mesmos modos, então esse enum e o seletor abaixo são compartilhados
/// entre Jogo da Velha e Damas.
enum CasualGameMode { vsComputer, twoPlayers }

class CasualModeSelector extends StatelessWidget {
  final CasualGameMode mode;
  final ValueChanged<CasualGameMode> onChanged;
  const CasualModeSelector({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.galaxyMid,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _option(context, 'Vs. computador', CasualGameMode.vsComputer),
          _option(context, '2 jogadores', CasualGameMode.twoPlayers),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, String label, CasualGameMode value) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.galaxyPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo de fim de partida, usado tanto pelo Jogo da Velha quanto por
/// Damas. `subtitle` é opcional — o Jogo da Memória usa seu próprio
/// diálogo, pois mostra jogadas/tempo em vez de vitória/derrota.
Future<void> showCasualMatchOverDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  required VoidCallback onPlayAgain,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.galaxyMid,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: subtitle == null
          ? null
          : Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Voltar', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            onPlayAgain();
          },
          child: const Text('Jogar de novo'),
        ),
      ],
    ),
  );
}
