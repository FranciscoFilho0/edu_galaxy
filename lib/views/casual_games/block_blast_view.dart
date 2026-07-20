import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/casual_records_service.dart';
import '../../models/casual_game_stats_model.dart';
import '../../core/theme/app_theme.dart';
import 'shared/casual_game_widgets.dart';

/// Uma peça disponível na bandeja: seu formato (lista de casas relativas
/// `[linha, coluna]`) e a cor com que vai aparecer no tabuleiro.
class _TrayPiece {
  final List<List<int>> shape;
  final Color color;
  _TrayPiece({required this.shape, required this.color});
}

/// Desenha um formato de peça numa grade compacta, usada tanto na
/// bandeja quanto na "sombra" que segue o dedo durante o arraste.
class _PieceGrid extends StatelessWidget {
  final List<List<int>> shape;
  final Color color;
  final double cellSize;
  const _PieceGrid({required this.shape, required this.color, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    final maxRow = shape.map((c) => c[0]).reduce(math.max) + 1;
    final maxCol = shape.map((c) => c[1]).reduce(math.max) + 1;
    return SizedBox(
      width: maxCol * cellSize,
      height: maxRow * cellSize,
      child: Stack(
        children: shape.map((c) {
          return Positioned(
            left: c[1] * cellSize,
            top: c[0] * cellSize,
            width: cellSize,
            height: cellSize,
            child: Container(
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Um "Block Blast" simplificado: tabuleiro 8x8, 3 peças por vez na
/// bandeja, arraste até o tabuleiro pra encaixar. Quando uma linha ou
/// coluna fica cheia, ela explode e vira pontos. O jogo acaba quando
/// nenhuma das peças da bandeja cabe em lugar nenhum.
class BlockBlastView extends StatefulWidget {
  const BlockBlastView({super.key});

  @override
  State<BlockBlastView> createState() => _BlockBlastViewState();
}

class _BlockBlastViewState extends State<BlockBlastView> {
  static const String _gameId = 'block_blast';
  static const int _rows = 8;
  static const int _cols = 8;

  // Banco de formatos possíveis, do jeito clássico de jogos de encaixe:
  // peças de 1 a 5 casas, retas, quadradas e em "L".
  static final List<List<List<int>>> _shapePool = [
    [[0, 0]],
    [[0, 0], [0, 1]],
    [[0, 0], [1, 0]],
    [[0, 0], [0, 1], [0, 2]],
    [[0, 0], [1, 0], [2, 0]],
    [[0, 0], [0, 1], [0, 2], [0, 3]],
    [[0, 0], [1, 0], [2, 0], [3, 0]],
    [[0, 0], [0, 1], [1, 0], [1, 1]],
    [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
    [[0, 0], [1, 0], [2, 0], [0, 1], [1, 1], [2, 1]],
    [[0, 0], [0, 1], [1, 0]],
    [[0, 0], [0, 1], [1, 1]],
    [[0, 1], [1, 0], [1, 1]],
    [[0, 0], [1, 0], [1, 1]],
    [[0, 0], [0, 1], [0, 2], [1, 0]],
    [[0, 0], [0, 1], [0, 2], [1, 2]],
    [[0, 0], [1, 0], [2, 0], [2, 1]],
    [[0, 1], [1, 1], [2, 0], [2, 1]],
    [[0, 1], [1, 0], [1, 1], [1, 2]],
  ];

  static const List<Color> _colors = [
    AppTheme.galaxyCyan,
    AppTheme.galaxyPurple,
    AppTheme.galaxyPink,
    AppTheme.galaxyGreen,
    AppTheme.galaxyStar,
    Color(0xFF3B82F6),
    Color(0xFFF97316),
  ];

  final _recordsService = CasualRecordsService();
  final _random = math.Random();
  final GlobalKey _boardKey = GlobalKey();

  late List<List<Color?>> _board;
  late List<_TrayPiece?> _tray;
  int _score = 0;
  bool _gameOver = false;
  CasualGameStats? _stats;

  List<List<int>>? _previewCells;
  bool _previewValid = false;

  @override
  void initState() {
    super.initState();
    _board = List.generate(_rows, (_) => List<Color?>.filled(_cols, null));
    _tray = List.generate(3, (_) => _randomPiece());
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await _recordsService.loadStats(_gameId);
    if (mounted) setState(() => _stats = s);
  }

  _TrayPiece _randomPiece() {
    final shape = _shapePool[_random.nextInt(_shapePool.length)];
    final color = _colors[_random.nextInt(_colors.length)];
    return _TrayPiece(shape: shape, color: color);
  }

  bool _canPlace(List<List<int>> shape, int anchorRow, int anchorCol) {
    for (final c in shape) {
      final r = anchorRow + c[0];
      final col = anchorCol + c[1];
      if (r < 0 || r >= _rows || col < 0 || col >= _cols) return false;
      if (_board[r][col] != null) return false;
    }
    return true;
  }

  void _onDragUpdate(int trayIndex, DragUpdateDetails details) {
    final piece = _tray[trayIndex];
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (piece == null || box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    final cellSize = box.size.width / _cols;
    final anchorCol = (local.dx / cellSize).floor();
    final anchorRow = (local.dy / cellSize).floor();
    final cells = piece.shape.map((c) => [anchorRow + c[0], anchorCol + c[1]]).toList();
    setState(() {
      _previewCells = cells;
      _previewValid = _canPlace(piece.shape, anchorRow, anchorCol);
    });
  }

  void _onDragEnd(int trayIndex) {
    final piece = _tray[trayIndex];
    if (piece != null && _previewValid && _previewCells != null) {
      _placePiece(trayIndex, piece, _previewCells!);
    }
    setState(() {
      _previewCells = null;
      _previewValid = false;
    });
  }

  void _placePiece(int trayIndex, _TrayPiece piece, List<List<int>> cells) {
    setState(() {
      for (final c in cells) {
        _board[c[0]][c[1]] = piece.color;
      }
      _tray[trayIndex] = null;
      _score += cells.length;
    });
    _clearFullLines();
    if (_tray.every((p) => p == null)) {
      setState(() => _tray = List.generate(3, (_) => _randomPiece()));
    }
    _checkGameOver();
  }

  void _clearFullLines() {
    final fullRows = <int>[];
    final fullCols = <int>[];
    for (int r = 0; r < _rows; r++) {
      if (_board[r].every((cell) => cell != null)) fullRows.add(r);
    }
    for (int c = 0; c < _cols; c++) {
      if (List.generate(_rows, (r) => _board[r][c]).every((cell) => cell != null)) fullCols.add(c);
    }
    if (fullRows.isEmpty && fullCols.isEmpty) return;
    setState(() {
      for (final r in fullRows) {
        for (int c = 0; c < _cols; c++) {
          _board[r][c] = null;
        }
      }
      for (final c in fullCols) {
        for (int r = 0; r < _rows; r++) {
          _board[r][c] = null;
        }
      }
      final combo = fullRows.length + fullCols.length;
      _score += combo * combo * 10;
    });
  }

  void _checkGameOver() {
    final anyPossible = _tray.any((piece) {
      if (piece == null) return false;
      for (int r = 0; r < _rows; r++) {
        for (int c = 0; c < _cols; c++) {
          if (_canPlace(piece.shape, r, c)) return true;
        }
      }
      return false;
    });
    if (!anyPossible && _tray.any((p) => p != null)) {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    setState(() => _gameOver = true);
    final updated = await _recordsService.recordHighScore(_gameId, _score);
    if (!mounted) return;
    setState(() => _stats = updated);
    showCasualMatchOverDialog(
      context,
      title: 'Fim de jogo!',
      subtitle: 'Pontuação: $_score · Recorde: ${updated.bestScore}',
      onPlayAgain: _restart,
    );
  }

  void _restart() {
    setState(() {
      _board = List.generate(_rows, (_) => List<Color?>.filled(_cols, null));
      _tray = List.generate(3, (_) => _randomPiece());
      _score = 0;
      _gameOver = false;
      _previewCells = null;
      _previewValid = false;
    });
  }

  Color? _cellDisplayColor(int r, int c) {
    final boardColor = _board[r][c];
    if (boardColor != null) return boardColor;
    if (_previewCells != null && _previewCells!.any((p) => p[0] == r && p[1] == c)) {
      return (_previewValid ? AppTheme.galaxyGreen : AppTheme.galaxyPink).withOpacity(0.45);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      appBar: AppBar(title: const Text('Explosão de Blocos')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statBox('Pontos', '$_score'),
                  _statBox('Recorde', '${_stats?.bestScore ?? 0}'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardSize = math.min(constraints.maxWidth, constraints.maxHeight * 0.62);
                    final cellSize = boardSize / _cols;
                    return Column(
                      children: [
                        Center(
                          child: SizedBox(
                            key: _boardKey,
                            width: boardSize,
                            height: boardSize,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.galaxyMid,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _cols,
                                  mainAxisSpacing: 1,
                                  crossAxisSpacing: 1,
                                  childAspectRatio: 1,
                                ),
                                itemCount: _rows * _cols,
                                itemBuilder: (context, i) {
                                  final r = i ~/ _cols;
                                  final c = i % _cols;
                                  final color = _cellDisplayColor(r, c);
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: color ?? Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _trayRow(cellSize),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trayRow(double cellSize) {
    return SizedBox(
      height: cellSize * 3 + 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) {
          final piece = _tray[i];
          if (piece == null) return const SizedBox.shrink();
          return Draggable<int>(
            data: i,
            onDragUpdate: (details) => _onDragUpdate(i, details),
            onDragEnd: (_) => _onDragEnd(i),
            feedback: Opacity(
              opacity: 0.85,
              child: _PieceGrid(shape: piece.shape, color: piece.color, cellSize: cellSize),
            ),
            childWhenDragging: Opacity(
              opacity: 0.25,
              child: _PieceGrid(shape: piece.shape, color: piece.color, cellSize: cellSize),
            ),
            child: _PieceGrid(shape: piece.shape, color: piece.color, cellSize: cellSize),
          );
        }),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppTheme.galaxyStar, fontSize: 11)),
      ],
    );
  }
}
