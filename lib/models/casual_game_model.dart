import 'package:flutter/material.dart';

/// Metadados de um "jogo livre" — os joguinhos de passar o tempo (Jogo da
/// Velha, Damas, Memória...) que NÃO entram no fluxo pedagógico: não têm
/// matéria, não são ativados/desativados pelo professor e não geram
/// GameResultModel nenhum. Por isso esse modelo é separado do GameModel.
class CasualGameModel {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final Color color;

  const CasualGameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.color,
  });

  static const List<CasualGameModel> allGames = [
    CasualGameModel(
      id: 'jogo_da_velha',
      title: 'Jogo da Velha',
      description: 'Você contra o computador ou dois jogadores no mesmo aparelho.',
      iconEmoji: '❌',
      color: Color(0xFF06B6D4),
    ),
    CasualGameModel(
      id: 'damas',
      title: 'Damas',
      description: 'O clássico jogo de tabuleiro, contra o computador ou em dupla.',
      iconEmoji: '⚫',
      color: Color(0xFF7C3AED),
    ),
    CasualGameModel(
      id: 'memoria',
      title: 'Jogo da Memória',
      description: 'Encontre os pares o mais rápido possível, sozinho ou em dupla.',
      iconEmoji: '🧠',
      color: Color(0xFFEC4899),
    ),
    CasualGameModel(
      id: 'tetris',
      title: 'Tetris',
      description: 'Encaixe as peças e limpe linhas antes que a torre chegue ao topo.',
      iconEmoji: '🧱',
      color: Color(0xFF10B981),
    ),
    CasualGameModel(
      id: 'block_blast',
      title: 'Explosão de Blocos',
      description: 'Arraste as peças até o tabuleiro e limpe linhas e colunas inteiras.',
      iconEmoji: '💥',
      color: Color(0xFFFBBF24),
    ),
  ];
}
