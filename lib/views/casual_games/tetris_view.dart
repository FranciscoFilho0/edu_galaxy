import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/casual_records_service.dart';
import '../../models/casual_game_stats_model.dart';
import '../../core/theme/app_theme.dart';
import 'shared/casual_game_widgets.dart';

/// Uma peça "viva", caindo no tabuleiro. `cells` são coordenadas
/// relativas (linha, coluna) dentro de uma caixa quadrada de lado
/// [size]; `row`/`col` é a posição dessa caixa dentro do tabuleiro.
class _ActivePiece {
  final String type;
  List<List<int>> cells;
  final int size;
  final Color color;
  int row;
  int col;

  _ActivePiece({
    required this.type,
    required this.cells,
    required this.size,
    required this.color,
    required this.row,
    required this.col,
  });
}

/// Tetris simplificado: tabuleiro 10x20, as 7 peças clássicas, rotação
/// com "wall kick" simples e velocidade que aumenta a cada nível.
/// Igual aos outros jogos livres, o recorde (maior pontuação) fica salvo
/// só no aparelho, sem passar pelo professor.
class TetrisView extends StatefulWidget {
  const TetrisView({super.key});

  @override
  State<TetrisView> createState() => _TetrisViewState();
}

class _TetrisViewState extends State<TetrisView> {
  static const String _gameId = 'tetris';
  static const int _rows = 20;
  static const int _cols = 10;

  // Cada peça é descrita pela posição das suas 4 casas dentro de uma
  // caixa quadrada (2x2 pro quadrado, 3x3 pra maioria, 4x4 pra peça "I",
  // que precisa de mais espaço pra girar).
  static final Map<String, List<List<int>>> _shapes = {
    'I': [[1, 0], [1, 1], [1, 2], [1, 3]],
    'O': [[0, 0], [0, 1], [1, 0], [1, 1]],
    'T': [[0, 1], [1, 0], [1, 1], [1, 2]],
    'S': [[0, 1], [0, 2], [1, 0], [1, 1]],
    'Z': [[0, 0], [0, 1], [1, 1], [1, 2]],
    'J': [[0, 0], [1, 0], [1, 1], [1, 2]],
    'L': [[0, 2], [1, 0], [1, 1], [1, 2]],
  };
  static const Map<String, int> _shapeSize = {
    'I': 4, 'O': 2, 'T': 3, 'S': 3, 'Z': 3, 'J': 3, 'L': 3,
  };
  static const Map<String, Color> _shapeColor = {
    'I': AppTheme.galaxyCyan,
    'O': AppTheme.galaxyStar,
    'T': AppTheme.galaxyPurple,
    'S': AppTheme.galaxyGreen,
    'Z': AppTheme.galaxyPink,
    'J': Color(0xFF3B82F6),
    'L': Color(0xFFF97316),
  };

  final _recordsService = CasualRecordsService();
  final _random = math.Random();

  late List<List<Color?>> _board;
  late _ActivePiece _current;
  late _ActivePiece _nextPiece;
  Timer? _timer;

  int _score = 0;
  int _lines = 0;
  int _level = 1;
  int _tickMs = 700;
  bool _gameOver = false;
  bool _paused = false;
  CasualGameStats? _stats;

  @override
  void initState() {
    super.initState();
    _board = List.generate(_rows, (_) => List<Color?>.filled(_cols, null));
    _current = _spawnPiece();
    _nextPiece = _spawnPiece();
    _loadStats();
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final s = await _recordsService.loadStats(_gameId);
    if (mounted) setState(() => _stats = s);
  }

  _ActivePiece _spawnPiece() {
    final type = _shapes.keys.elementAt(_random.nextInt(_shapes.length));
    final size = _shapeSize[type]!;
    return _ActivePiece(
      type: type,
      cells: _shapes[type]!,
      size: size,
      color: _shapeColor[type]!,
      row: 0,
      col: (_cols - size) ~/ 2,
    );
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _tickMs), (_) => _tick());
  }

  bool _collides(_ActivePiece p, {int rowOffset = 0, int colOffset = 0, List<List<int>>? cells}) {
    final testCells = cells ?? p.cells;
    for (final c in testCells) {
      final r = p.row + c[0] + rowOffset;
      final col = p.col + c[1] + colOffset;
      if (col < 0 || col >= _cols || r >= _rows) return true;
      if (r >= 0 && _board[r][col] != null) return true;
    }
    return false;
  }

  void _tick() {
    if (_gameOver || _paused) return;
    if (!_collides(_current, rowOffset: 1)) {
      setState(() => _current.row++);
    } else {
      _lockPiece();
    }
  }

  void _lockPiece() {
    for (final c in _current.cells) {
      final r = _current.row + c[0];
      final col = _current.col + c[1];
      if (r >= 0 && r < _rows && col >= 0 && col < _cols) {
        _board[r][col] = _current.color;
      }
    }
    _clearLines();

    final upcoming = _nextPiece;
    if (_collides(upcoming)) {
      setState(() {});
      _endGame();
      return;
    }
    setState(() {
      _current = upcoming;
      _nextPiece = _spawnPiece();
    });
  }

  void _clearLines() {
    int cleared = 0;
    for (int r = _rows - 1; r >= 0; r--) {
      if (_board[r].every((cell) => cell != null)) {
        _board.removeAt(r);
        _board.insert(0, List<Color?>.filled(_cols, null));
        cleared++;
        r++; // reavalia a mesma posição, já que uma linha nova entrou aqui
      }
    }
    if (cleared > 0) {
      const points = [0, 100, 300, 500, 800];
      setState(() {
        _score += points[cleared.clamp(0, 4)] * _level;
        _lines += cleared;
        _level = 1 + (_lines ~/ 10);
      });
      final newTickMs = math.max(120, 700 - (_level - 1) * 60);
      if (newTickMs != _tickMs) {
        _tickMs = newTickMs;
        _restartTimer();
      }
    }
  }

  void _move(int dc) {
    if (_gameOver || _paused) return;
    if (!_collides(_current, colOffset: dc)) setState(() => _current.col += dc);
  }

  void _rotate() {
    if (_gameOver || _paused || _current.type == 'O') return;
    final n = _current.size;
    // Gira 90° no sentido horário dentro da caixa NxN da peça.
    final rotated = _current.cells.map((c) => [c[1], n - 1 - c[0]]).toList();
    if (!_collides(_current, cells: rotated)) {
      setState(() => _current.cells = rotated);
      return;
    }
    // "Wall kick" simples: tenta empurrar a peça pros lados se a rotação
    // esbarrar numa parede ou noutra peça.
    for (final k in [-1, 1, -2, 2]) {
      if (!_collides(_current, cells: rotated, colOffset: k)) {
        setState(() {
          _current.cells = rotated;
          _current.col += k;
        });
        return;
      }
    }
  }

  void _hardDrop() {
    if (_gameOver || _paused) return;
    int drop = 0;
    while (!_collides(_current, rowOffset: drop + 1)) {
      drop++;
    }
    setState(() => _current.row += drop);
    _lockPiece();
  }

  Future<void> _endGame() async {
    _timer?.cancel();
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
      _current = _spawnPiece();
      _nextPiece = _spawnPiece();
      _score = 0;
      _lines = 0;
      _level = 1;
      _tickMs = 700;
      _gameOver = false;
      _paused = false;
    });
    _restartTimer();
  }

  void _togglePause() {
    if (_gameOver) return;
    setState(() => _paused = !_paused);
  }

  Color? _cellColor(int r, int c) {
    final boardColor = _board[r][c];
    if (boardColor != null) return boardColor;
    for (final cell in _current.cells) {
      if (_current.row + cell[0] == r && _current.col + cell[1] == c) {
        return _current.color;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      appBar: AppBar(
        title: const Text('Tetris'),
        actions: [
          IconButton(
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause, color: Colors.white),
            onPressed: _togglePause,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statBox('Pontos', '$_score'),
                  _statBox('Nível', '$_level'),
                  _statBox('Linhas', '$_lines'),
                  _statBox('Recorde', '${_stats?.bestScore ?? 0}'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final v = details.primaryVelocity ?? 0;
                    if (v > 250) {
                      _move(1);
                    } else if (v < -250) {
                      _move(-1);
                    }
                  },
                  onVerticalDragEnd: (details) {
                    final v = details.primaryVelocity ?? 0;
                    if (v > 250) _hardDrop();
                  },
                  onTap: _rotate,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: _cols / _rows,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.galaxyMid,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                GridView.builder(
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
                                    final color = _cellColor(r, c);
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: color ?? Colors.white.withOpacity(0.03),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  },
                                ),
                                if (_paused)
                                  Container(
                                    color: Colors.black.withOpacity(0.6),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Pausado',
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        children: [
                          const Text('Próxima', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 4),
                          _nextPiecePreview(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(Icons.chevron_left, () => _move(-1)),
                  _controlButton(Icons.rotate_right, _rotate),
                  _controlButton(Icons.chevron_right, () => _move(1)),
                  _controlButton(Icons.arrow_downward, _hardDrop),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppTheme.galaxyStar, fontSize: 10)),
      ],
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.galaxyMid,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _nextPiecePreview() {
    const previewSize = 4;
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppTheme.galaxyMid, borderRadius: BorderRadius.circular(10)),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: previewSize),
        itemCount: previewSize * previewSize,
        itemBuilder: (context, i) {
          final r = i ~/ previewSize;
          final c = i % previewSize;
          final occupied = _nextPiece.cells.any((cell) => cell[0] == r && cell[1] == c);
          return Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: occupied ? _nextPiece.color : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        },
      ),
    );
  }
}
