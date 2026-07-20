import 'package:flutter/material.dart';
import '../../services/casual_records_service.dart';
import '../../models/casual_game_stats_model.dart';
import '../../core/theme/app_theme.dart';
import 'shared/casual_game_widgets.dart';

/// Jogo da Velha clássico 3x3. No modo "Vs. computador" a IA joga com
/// minimax — ou seja, ela nunca perde (só ganha ou empata), então o
/// recorde interessante de guardar é a sequência de vitórias do aluno.
/// No modo "2 jogadores" os dois dividem o aparelho e o placar da rodada
/// não é salvo (não daria pra saber, num app single-login por sala, qual
/// dos dois é "o aluno dono do recorde").
class TicTacToeView extends StatefulWidget {
  const TicTacToeView({super.key});

  @override
  State<TicTacToeView> createState() => _TicTacToeViewState();
}

class _TicTacToeViewState extends State<TicTacToeView> {
  static const String _gameId = 'jogo_da_velha';
  final _recordsService = CasualRecordsService();

  CasualGameMode _mode = CasualGameMode.vsComputer;
  CasualGameStats? _stats;

  // O tabuleiro é uma lista de 9 posições: 'X', 'O' ou '' (vazia).
  List<String> _board = List.filled(9, '');
  bool _playerTurn = true; // Nesse jogo, X sempre começa.
  bool _gameOver = false;
  int _twoPlayerXWins = 0;
  int _twoPlayerOWins = 0;
  int _twoPlayerDraws = 0;

  static const List<List<int>> _lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // linhas
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // colunas
    [0, 4, 8], [2, 4, 6], // diagonais
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await _recordsService.loadStats(_gameId);
    if (mounted) setState(() => _stats = s);
  }

  void _resetBoard() {
    setState(() {
      _board = List.filled(9, '');
      _playerTurn = true;
      _gameOver = false;
    });
  }

  String? _winnerOf(List<String> board) {
    for (final line in _lines) {
      final a = board[line[0]], b = board[line[1]], c = board[line[2]];
      if (a.isNotEmpty && a == b && b == c) return a;
    }
    return null;
  }

  bool _isDraw(List<String> board) => !board.contains('') && _winnerOf(board) == null;

  void _handleTap(int index) {
    if (_gameOver || _board[index].isNotEmpty) return;
    if (_mode == CasualGameMode.vsComputer && !_playerTurn) return;

    final mark = _playerTurn ? 'X' : 'O';
    setState(() => _board[index] = mark);
    _checkEndOfTurn();
  }

  void _checkEndOfTurn() {
    final winner = _winnerOf(_board);
    if (winner != null) {
      _finishMatch(winner: winner);
      return;
    }
    if (_isDraw(_board)) {
      _finishMatch(winner: null);
      return;
    }

    setState(() => _playerTurn = !_playerTurn);

    if (_mode == CasualGameMode.vsComputer && !_playerTurn) {
      // Pequeno atraso só pra não parecer instantâneo demais.
      Future.delayed(const Duration(milliseconds: 400), _computerMove);
    }
  }

  void _computerMove() {
    if (_gameOver) return;
    final move = _bestMoveForComputer(_board);
    if (move == null) return;
    setState(() => _board[move] = 'O');
    _checkEndOfTurn();
  }

  /// Minimax simples: como o tabuleiro tem só 9 casas, dá pra explorar
  /// todas as possibilidades sem problema de performance. O computador
  /// sempre joga 'O' e tenta maximizar sua própria pontuação.
  int? _bestMoveForComputer(List<String> board) {
    int? bestMove;
    int bestScore = -1000;
    for (int i = 0; i < 9; i++) {
      if (board[i].isNotEmpty) continue;
      final next = [...board];
      next[i] = 'O';
      final score = _minimax(next, depth: 0, isMaximizing: false);
      if (score > bestScore) {
        bestScore = score;
        bestMove = i;
      }
    }
    return bestMove;
  }

  int _minimax(List<String> board, {required int depth, required bool isMaximizing}) {
    final winner = _winnerOf(board);
    if (winner == 'O') return 10 - depth;
    if (winner == 'X') return depth - 10;
    if (_isDraw(board)) return 0;

    if (isMaximizing) {
      int best = -1000;
      for (int i = 0; i < 9; i++) {
        if (board[i].isNotEmpty) continue;
        final next = [...board];
        next[i] = 'O';
        best = best > _minimax(next, depth: depth + 1, isMaximizing: false)
            ? best
            : _minimax(next, depth: depth + 1, isMaximizing: false);
      }
      return best;
    } else {
      int best = 1000;
      for (int i = 0; i < 9; i++) {
        if (board[i].isNotEmpty) continue;
        final next = [...board];
        next[i] = 'X';
        best = best < _minimax(next, depth: depth + 1, isMaximizing: true)
            ? best
            : _minimax(next, depth: depth + 1, isMaximizing: true);
      }
      return best;
    }
  }

  Future<void> _finishMatch({String? winner}) async {
    setState(() => _gameOver = true);

    if (_mode == CasualGameMode.vsComputer) {
      final outcome = winner == 'X'
          ? MatchOutcome.win
          : winner == 'O'
              ? MatchOutcome.loss
              : MatchOutcome.draw;
      final updated = await _recordsService.recordMatchOutcome(_gameId, outcome);
      if (mounted) setState(() => _stats = updated);

      final title = winner == 'X' ? 'Você venceu! 🎉' : winner == 'O' ? 'O computador venceu' : 'Empate!';
      final subtitle = winner == 'X'
          ? 'Sequência atual: ${updated.currentStreak} · Recorde: ${updated.bestStreak}'
          : null;
      if (mounted) {
        showCasualMatchOverDialog(context, title: title, subtitle: subtitle, onPlayAgain: _resetBoard);
      }
    } else {
      setState(() {
        if (winner == 'X') _twoPlayerXWins++;
        if (winner == 'O') _twoPlayerOWins++;
        if (winner == null) _twoPlayerDraws++;
      });
      final title = winner == null ? 'Empate!' : 'Jogador $winner venceu!';
      if (mounted) {
        showCasualMatchOverDialog(context, title: title, onPlayAgain: _resetBoard);
      }
    }
  }

  void _changeMode(CasualGameMode mode) {
    setState(() {
      _mode = mode;
      _twoPlayerXWins = 0;
      _twoPlayerOWins = 0;
      _twoPlayerDraws = 0;
    });
    _resetBoard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      appBar: AppBar(title: const Text('Jogo da Velha')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CasualModeSelector(mode: _mode, onChanged: _changeMode),
              const SizedBox(height: 16),
              if (_mode == CasualGameMode.vsComputer && _stats != null)
                Text(
                  '${_stats!.wins}V ${_stats!.losses}D ${_stats!.draws}E · sequência recorde: ${_stats!.bestStreak}',
                  style: const TextStyle(color: AppTheme.galaxyStar, fontSize: 13, fontWeight: FontWeight.w600),
                )
              else if (_mode == CasualGameMode.twoPlayers)
                Text(
                  'Nessa sessão: X $_twoPlayerXWins · O $_twoPlayerOWins · Empates $_twoPlayerDraws',
                  style: const TextStyle(color: AppTheme.galaxyStar, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 8),
              Text(
                _mode == CasualGameMode.vsComputer
                    ? (_playerTurn ? 'Sua vez (X)' : 'Vez do computador...')
                    : 'Vez do jogador ${_playerTurn ? 'X' : 'O'}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, i) => _Cell(
                    value: _board[i],
                    onTap: () => _handleTap(i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const _Cell({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = value == 'X' ? AppTheme.galaxyCyan : AppTheme.galaxyPink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.galaxyMid,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
