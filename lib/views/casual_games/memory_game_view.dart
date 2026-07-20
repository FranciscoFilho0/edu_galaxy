import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/casual_records_service.dart';
import '../../models/casual_game_stats_model.dart';
import '../../core/theme/app_theme.dart';

enum _MemoryMode { solo, twoPlayers }

class _MemoryCard {
  final String emoji;
  bool revealed;
  bool matched;
  _MemoryCard(this.emoji, {this.revealed = false, this.matched = false});
}

/// Jogo da memória temático (emojis espaciais). No modo Solo o recorde
/// salvo é o de menor número de jogadas e menor tempo. No modo 2
/// jogadores, os dois disputam pontos (pares encontrados) na mesma
/// sessão — quem acerta um par joga de novo; quem erra passa a vez.
class MemoryGameView extends StatefulWidget {
  const MemoryGameView({super.key});

  @override
  State<MemoryGameView> createState() => _MemoryGameViewState();
}

class _MemoryGameViewState extends State<MemoryGameView> {
  static const String _gameId = 'memoria';
  static const _emojis = ['🚀', '🪐', '👽', '🛸', '⭐', '🌙', '☄️', '🔭'];

  final _recordsService = CasualRecordsService();
  final _random = math.Random();

  _MemoryMode _mode = _MemoryMode.solo;
  CasualGameStats? _stats;

  late List<_MemoryCard> _cards;
  int? _firstIndex;
  int? _secondIndex;
  bool _busy = false; // true enquanto duas cartas erradas estão sendo mostradas
  int _moves = 0;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _finished = false;

  int _p1Score = 0;
  int _p2Score = 0;
  int _currentPlayer = 1;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _setupGame();
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

  void _setupGame() {
    _timer?.cancel();
    final deck = [..._emojis, ..._emojis].map((e) => _MemoryCard(e)).toList()..shuffle(_random);
    setState(() {
      _cards = deck;
      _firstIndex = null;
      _secondIndex = null;
      _busy = false;
      _moves = 0;
      _elapsedSeconds = 0;
      _finished = false;
      _p1Score = 0;
      _p2Score = 0;
      _currentPlayer = 1;
    });
  }

  void _ensureTimerRunning() {
    if (_mode != _MemoryMode.solo || _timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _handleTap(int index) {
    if (_busy || _finished) return;
    if (_cards[index].revealed || _cards[index].matched) return;

    _ensureTimerRunning();
    setState(() => _cards[index].revealed = true);

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    _secondIndex = index;
    _busy = true;
    _moves++;

    final first = _cards[_firstIndex!];
    final second = _cards[_secondIndex!];

    if (first.emoji == second.emoji) {
      setState(() {
        first.matched = true;
        second.matched = true;
        if (_mode == _MemoryMode.twoPlayers) {
          if (_currentPlayer == 1) {
            _p1Score++;
          } else {
            _p2Score++;
          }
        }
        _firstIndex = null;
        _secondIndex = null;
        _busy = false;
      });
      if (_cards.every((c) => c.matched)) _finishGame();
    } else {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          first.revealed = false;
          second.revealed = false;
          _firstIndex = null;
          _secondIndex = null;
          _busy = false;
          if (_mode == _MemoryMode.twoPlayers) _currentPlayer = _currentPlayer == 1 ? 2 : 1;
        });
      });
    }
  }

  Future<void> _finishGame() async {
    _timer?.cancel();
    setState(() => _finished = true);

    if (_mode == _MemoryMode.solo) {
      final updated = await _recordsService.recordMemoryRun(_gameId, moves: _moves, seconds: _elapsedSeconds);
      if (mounted) setState(() => _stats = updated);
      if (mounted) _showEndDialog('Você terminou! 🎉', '$_moves jogadas · $_elapsedSeconds s');
    } else {
      final title = _p1Score == _p2Score
          ? 'Empate! ($_p1Score x $_p2Score)'
          : _p1Score > _p2Score
              ? 'Jogador 1 venceu! ($_p1Score x $_p2Score)'
              : 'Jogador 2 venceu! ($_p1Score x $_p2Score)';
      if (mounted) _showEndDialog(title, null);
    }
  }

  void _showEndDialog(String title, String? subtitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.galaxyMid,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: subtitle == null ? null : Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Voltar', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _setupGame();
            },
            child: const Text('Jogar de novo'),
          ),
        ],
      ),
    );
  }

  void _changeMode(_MemoryMode mode) {
    setState(() => _mode = mode);
    _setupGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      appBar: AppBar(title: const Text('Jogo da Memória')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppTheme.galaxyMid, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: [
                    _modeOption('Solo', _MemoryMode.solo),
                    _modeOption('2 jogadores', _MemoryMode.twoPlayers),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_mode == _MemoryMode.solo) ...[
                Text(
                  _stats == null || _stats!.bestMoves == null
                      ? 'Ainda sem recorde'
                      : 'Recorde: ${_stats!.bestMoves} jogadas · ${_stats!.bestTimeSeconds}s',
                  style: const TextStyle(color: AppTheme.galaxyStar, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text('Jogadas: $_moves · Tempo: ${_elapsedSeconds}s', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ] else
                Text(
                  'Jogador 1: $_p1Score  ·  Jogador 2: $_p2Score  ·  vez do Jogador $_currentPlayer',
                  style: const TextStyle(color: AppTheme.galaxyStar, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, i) => _MemoryCardTile(card: _cards[i], onTap: () => _handleTap(i)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeOption(String label, _MemoryMode value) {
    final selected = _mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeMode(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.galaxyPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(
            color: selected ? Colors.white : Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.bold, fontSize: 13,
          )),
        ),
      ),
    );
  }
}

class _MemoryCardTile extends StatelessWidget {
  final _MemoryCard card;
  final VoidCallback onTap;
  const _MemoryCardTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final showFace = card.revealed || card.matched;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: card.matched ? AppTheme.galaxyGreen.withOpacity(0.25) : AppTheme.galaxyMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        alignment: Alignment.center,
        child: Text(
          showFace ? card.emoji : '❔',
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }
}
