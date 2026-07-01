import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/game_content_controller.dart';
import '../../../models/word_entry_model.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/game_top_bar.dart';
import '../shared/game_result_screen.dart';

class SilabasGameView extends StatefulWidget {
  const SilabasGameView({super.key});

  @override
  State<SilabasGameView> createState() => _SilabasGameViewState();
}

class _SilabasGameViewState extends State<SilabasGameView> {
  List<WordEntryModel> _words = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isFinished = false;
  DateTime _startTime = DateTime.now();

  List<String> _shuffledSyllables = [];
  List<int> _selectedOrder = [];
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWords());
  }

  void _loadWords() {
    final content = context.read<GameContentController>();
    final list = [...content.syllableWords]..shuffle();
    setState(() {
      _words = list.take(8).toList();
      _setupRound();
    });
  }

  void _setupRound() {
    final syllables = _words[_currentIndex].syllables;
    final shuffled = [...syllables]..shuffle(Random());
    _shuffledSyllables = shuffled;
    _selectedOrder = [];
    _answered = false;
    _isCorrect = false;
  }

  void _tapSyllable(int index) {
    if (_answered || _selectedOrder.contains(index)) return;
    setState(() => _selectedOrder.add(index));

    if (_selectedOrder.length == _shuffledSyllables.length) {
      _checkAnswer();
    }
  }

  void _removeFromOrder(int posInOrder) {
    if (_answered) return;
    setState(() => _selectedOrder.removeAt(posInOrder));
  }

  void _checkAnswer() {
    final attempt = _selectedOrder.map((i) => _shuffledSyllables[i]).join();
    final correctWord = _words[_currentIndex].syllables.join();
    final correct = attempt.toUpperCase() == correctWord.toUpperCase();

    setState(() {
      _answered = true;
      _isCorrect = correct;
      if (correct) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentIndex < _words.length - 1) {
        setState(() {
          _currentIndex++;
          _setupRound();
        });
      } else {
        setState(() => _isFinished = true);
      }
    });
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _isFinished = false;
      _startTime = DateTime.now();
    });
    _loadWords();
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<GameContentController>();
    if (content.isLoading || _words.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.galaxyDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.galaxyViolet)),
      );
    }

    if (_isFinished) {
      return GameResultScreen(
        gameEmoji: '🧩',
        gameTitle: 'Quebra-Sílabas',
        score: _score,
        total: _words.length,
        durationSeconds: DateTime.now().difference(_startTime).inSeconds,
        onPlayAgain: _restart,
      );
    }

    final word = _words[_currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: SafeArea(
        child: Column(
          children: [
            GameTopBar(title: '🧩 Quebra-Sílabas', current: _currentIndex, total: _words.length, score: _score),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.galaxyMid,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.galaxyCyan.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(word.hint, style: const TextStyle(color: Colors.white, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              constraints: const BoxConstraints(minHeight: 64),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.galaxyDeep,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _answered
                      ? (_isCorrect ? AppTheme.galaxyGreen : AppTheme.galaxyPink)
                      : AppTheme.galaxyPurple.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8, runSpacing: 8,
                children: _selectedOrder.isEmpty
                    ? [const Text('Toque nas sílabas abaixo', style: TextStyle(color: Color(0xFF89B4FA), fontSize: 13))]
                    : List.generate(_selectedOrder.length, (pos) {
                        final syllableIndex = _selectedOrder[pos];
                        return GestureDetector(
                          onTap: () => _removeFromOrder(pos),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppTheme.galaxyPurple, AppTheme.galaxyCyan]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_shuffledSyllables[syllableIndex], style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                            )),
                          ),
                        );
                      }),
              ),
            ),
            if (_answered) ...[
              const SizedBox(height: 12),
              Text(
                _isCorrect ? '✅ Correto!' : '❌ Era: ${word.syllables.join("-")}',
                style: TextStyle(
                  color: _isCorrect ? AppTheme.galaxyGreen : AppTheme.galaxyPink,
                  fontWeight: FontWeight.bold, fontSize: 14,
                ),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12, runSpacing: 12,
                children: List.generate(_shuffledSyllables.length, (i) {
                  final used = _selectedOrder.contains(i);
                  return GestureDetector(
                    onTap: used ? null : () => _tapSyllable(i),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: used ? 0.25 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.galaxyMid,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.galaxyPurple.withOpacity(0.4)),
                        ),
                        child: Text(_shuffledSyllables[i], style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                        )),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
