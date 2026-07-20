import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/casual_records_service.dart';
import '../../models/casual_game_stats_model.dart';
import '../../core/theme/app_theme.dart';
import 'shared/casual_game_widgets.dart';

/// Tabuleiro de Damas 8x8. Convenção de valores em cada casa:
///   0  = vazia
///   1  = peça do Jogador 1 (embaixo)     2  = dama do Jogador 1
///  -1  = peça do Jogador 2 / computador (em cima)   -2 = dama dele
///
/// Simplificações propositais em relação à regra oficial (pra manter o
/// código do tamanho de um recurso "de passar o tempo", não um motor de
/// xadrez/damas completo):
///   - A captura NÃO é obrigatória (o jogador pode optar por não capturar).
///   - Não existe captura múltipla em sequência: cada jogada captura no
///     máximo uma peça, mesmo que outra captura estivesse disponível
///     depois.
///   - A dama anda uma casa por vez em qualquer diagonal (sem "voar"
///     várias casas), igual ao padrão do damas americano.
class CheckersView extends StatefulWidget {
  const CheckersView({super.key});

  @override
  State<CheckersView> createState() => _CheckersViewState();
}

class _CheckersMove {
  final int from;
  final int to;
  final int? captured;
  const _CheckersMove({required this.from, required this.to, this.captured});
}

class _CheckersViewState extends State<CheckersView> {
  static const String _gameId = 'damas';
  final _recordsService = CasualRecordsService();
  final _random = math.Random();

  CasualGameMode _mode = CasualGameMode.vsComputer;
  CasualGameStats? _stats;

  late List<int> _board;
  int _currentSide = 1; // 1 = Jogador 1 (embaixo) começa sempre
  int? _selectedIndex;
  List<_CheckersMove> _availableMoves = [];
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _setupBoard();
  }

  Future<void> _loadStats() async {
    final s = await _recordsService.loadStats(_gameId);
    if (mounted) setState(() => _stats = s);
  }

  void _setupBoard() {
    final board = List<int>.filled(64, 0);
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 0) continue; // só as casas escuras são jogáveis
        if (row <= 2) board[row * 8 + col] = -1;
        if (row >= 5) board[row * 8 + col] = 1;
      }
    }
    setState(() {
      _board = board;
      _currentSide = 1;
      _selectedIndex = null;
      _availableMoves = [];
      _gameOver = false;
    });
  }

  int _sign(int piece) => piece == 0 ? 0 : (piece > 0 ? 1 : -1);
  bool _isKing(int piece) => piece.abs() == 2;

  List<List<int>> _directionsFor(int piece) {
    const upLeft = [-1, -1], upRight = [-1, 1], downLeft = [1, -1], downRight = [1, 1];
    if (_isKing(piece)) return [upLeft, upRight, downLeft, downRight];
    // Peças comuns do Jogador 1 (embaixo) sobem o tabuleiro; as do
    // Jogador 2/computador (em cima) descem.
    return piece > 0 ? [upLeft, upRight] : [downLeft, downRight];
  }

  List<_CheckersMove> _movesForPiece(List<int> board, int index) {
    final piece = board[index];
    if (piece == 0) return [];
    final row = index ~/ 8, col = index % 8;
    final moves = <_CheckersMove>[];

    for (final dir in _directionsFor(piece)) {
      final nr = row + dir[0], nc = col + dir[1];
      if (nr < 0 || nr > 7 || nc < 0 || nc > 7) continue;
      final nIdx = nr * 8 + nc;

      if (board[nIdx] == 0) {
        moves.add(_CheckersMove(from: index, to: nIdx));
        continue;
      }
      if (_sign(board[nIdx]) != _sign(piece)) {
        final jr = row + dir[0] * 2, jc = col + dir[1] * 2;
        if (jr < 0 || jr > 7 || jc < 0 || jc > 7) continue;
        final jIdx = jr * 8 + jc;
        if (board[jIdx] == 0) {
          moves.add(_CheckersMove(from: index, to: jIdx, captured: nIdx));
        }
      }
    }
    return moves;
  }

  List<_CheckersMove> _allMovesFor(List<int> board, int side) {
    final all = <_CheckersMove>[];
    for (int i = 0; i < 64; i++) {
      if (_sign(board[i]) == side) all.addAll(_movesForPiece(board, i));
    }
    return all;
  }

  List<int> _applyMove(List<int> board, _CheckersMove move) {
    final next = [...board];
    final piece = next[move.from];
    next[move.from] = 0;
    if (move.captured != null) next[move.captured!] = 0;

    final destRow = move.to ~/ 8;
    final promoted = (piece == 1 && destRow == 0) || (piece == -1 && destRow == 7);
    next[move.to] = promoted ? piece * 2 : piece;
    return next;
  }

  void _handleTap(int index) {
    if (_gameOver) return;
    if (_mode == CasualGameMode.vsComputer && _currentSide == -1) return;

    final piece = _board[index];

    // Toque num destino válido: executa a jogada.
    final move = _availableMoves.where((m) => m.to == index && m.from == _selectedIndex);
    if (move.isNotEmpty) {
      _playMove(move.first);
      return;
    }

    // Toque numa peça do próprio lado: seleciona (ou desmarca, se já
    // estava selecionada).
    if (_sign(piece) == _currentSide) {
      setState(() {
        if (_selectedIndex == index) {
          _selectedIndex = null;
          _availableMoves = [];
        } else {
          _selectedIndex = index;
          _availableMoves = _movesForPiece(_board, index);
        }
      });
    }
  }

  void _playMove(_CheckersMove move) {
    setState(() {
      _board = _applyMove(_board, move);
      _selectedIndex = null;
      _availableMoves = [];
    });
    _advanceTurn();
  }

  void _advanceTurn() {
    final nextSide = -_currentSide;
    final nextMoves = _allMovesFor(_board, nextSide);

    if (nextMoves.isEmpty) {
      // Quem ia jogar agora não tem jogada nenhuma (sem peças ou travado)
      // — o outro lado venceu.
      _finishMatch(winnerSide: _currentSide);
      return;
    }

    setState(() => _currentSide = nextSide);

    if (_mode == CasualGameMode.vsComputer && nextSide == -1) {
      Future.delayed(const Duration(milliseconds: 500), _computerMove);
    }
  }

  void _computerMove() {
    if (_gameOver) return;
    final moves = _allMovesFor(_board, -1);
    if (moves.isEmpty) return;

    // IA simples: prioriza capturas; se não houver nenhuma, joga aleatório.
    final captures = moves.where((m) => m.captured != null).toList();
    final pool = captures.isNotEmpty ? captures : moves;
    final chosen = pool[_random.nextInt(pool.length)];
    _playMove(chosen);
  }

  Future<void> _finishMatch({required int winnerSide}) async {
    setState(() => _gameOver = true);

    if (_mode == CasualGameMode.vsComputer) {
      final outcome = winnerSide == 1 ? MatchOutcome.win : MatchOutcome.loss;
      final updated = await _recordsService.recordMatchOutcome(_gameId, outcome);
      if (mounted) setState(() => _stats = updated);

      final title = winnerSide == 1 ? 'Você venceu! 🎉' : 'O computador venceu';
      final subtitle = winnerSide == 1
          ? 'Sequência atual: ${updated.currentStreak} · Recorde: ${updated.bestStreak}'
          : null;
      if (mounted) {
        showCasualMatchOverDialog(context, title: title, subtitle: subtitle, onPlayAgain: _setupBoard);
      }
    } else {
      final title = winnerSide == 1 ? 'Jogador 1 venceu!' : 'Jogador 2 venceu!';
      if (mounted) {
        showCasualMatchOverDialog(context, title: title, onPlayAgain: _setupBoard);
      }
    }
  }

  void _changeMode(CasualGameMode mode) {
    setState(() => _mode = mode);
    _setupBoard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      appBar: AppBar(title: const Text('Damas')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CasualModeSelector(mode: _mode, onChanged: _changeMode),
              const SizedBox(height: 16),
              if (_mode == CasualGameMode.vsComputer && _stats != null)
                Text(
                  '${_stats!.wins}V ${_stats!.losses}D · sequência recorde: ${_stats!.bestStreak}',
                  style: const TextStyle(color: AppTheme.galaxyStar, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 8),
              Text(
                _mode == CasualGameMode.vsComputer
                    ? (_currentSide == 1 ? 'Sua vez' : 'Vez do computador...')
                    : 'Vez do Jogador ${_currentSide == 1 ? '1' : '2'}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                  itemCount: 64,
                  itemBuilder: (context, i) => _BoardCell(
                    piece: _board[i],
                    isDark: ((i ~/ 8) + (i % 8)) % 2 != 0,
                    isSelected: _selectedIndex == i,
                    isDestination: _availableMoves.any((m) => m.to == i),
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

class _BoardCell extends StatelessWidget {
  final int piece;
  final bool isDark;
  final bool isSelected;
  final bool isDestination;
  final VoidCallback onTap;

  const _BoardCell({
    required this.piece,
    required this.isDark,
    required this.isSelected,
    required this.isDestination,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = isDark ? const Color(0xFF2A2F55) : const Color(0xFF14172E);
    if (isSelected) bg = AppTheme.galaxyPurple.withOpacity(0.6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: isDestination ? Border.all(color: AppTheme.galaxyStar, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: piece == 0
            ? null
            : Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: piece > 0 ? AppTheme.galaxyCyan : AppTheme.galaxyPink,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                alignment: Alignment.center,
                child: piece.abs() == 2
                    ? const Icon(Icons.star, size: 14, color: Colors.white)
                    : null,
              ),
      ),
    );
  }
}
