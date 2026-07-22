import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/game_content_controller.dart';
import '../../../controllers/student_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/word_entry_model.dart';
import '../../../models/game_result_model.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/game_top_bar.dart';
import '../shared/game_result_screen.dart';
import '../shared/speak_button.dart';
import '../../../services/tts_service.dart';

class SoletrarGameView extends StatefulWidget {
  const SoletrarGameView({super.key});

  @override
  State<SoletrarGameView> createState() => _SoletrarGameViewState();
}

class _SoletrarGameViewState extends State<SoletrarGameView> {
  List<WordEntryModel> _words = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isFinished = false;
  DateTime _startTime = DateTime.now();

  List<String> _letterBank = [];
  List<String?> _slots = [];
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWords());
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _loadWords() {
    final content = context.read<GameContentController>();
    final list = [...content.spellingWords]..shuffle();
    setState(() {
      _words = list.take(8).toList();
      _setupRound();
    });
  }

  void _setupRound() {
    final word = _words[_currentIndex].word.toUpperCase();
    final letters = word.split('');
    final shuffled = [...letters]..shuffle(Random());
    // Avoid the lucky case where shuffle equals original for short words
    if (shuffled.join() == word && letters.length > 1) {
      shuffled.shuffle(Random());
    }
    _letterBank = shuffled;
    _slots = List.filled(letters.length, null);
    _answered = false;
    _isCorrect = false;
  }

  void _tapLetter(int bankIndex) {
    if (_answered) return;
    final emptySlot = _slots.indexWhere((s) => s == null);
    if (emptySlot == -1) return;

    setState(() {
      _slots[emptySlot] = _letterBank[bankIndex];
      _letterBank[bankIndex] = '\u0000'; // mark as used
    });

    if (!_slots.contains(null)) {
      _checkAnswer();
    }
  }

  void _tapSlot(int slotIndex) {
    if (_answered || _slots[slotIndex] == null) return;
    setState(() {
      final letter = _slots[slotIndex]!;
      final freeIndex = _letterBank.indexOf('\u0000');
      // find first used slot matching letter to restore — simplistic: restore to first marked slot
      for (int i = 0; i < _letterBank.length; i++) {
        if (_letterBank[i] == '\u0000') {
          _letterBank[i] = letter;
          break;
        }
      }
      _slots[slotIndex] = null;
    });
  }

  void _checkAnswer() {
    final attempt = _slots.join();
    final correct = attempt == _words[_currentIndex].word.toUpperCase();
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
        _saveResult();
      }
    });
  }

  Set<String> _unlockedBeforeIds = {};

  void _saveResult() {
    final auth = context.read<AuthController>();
    final student = auth.currentStudent;
    if (student == null) return;
    final studentController = context.read<StudentController>();
    // Snapshot de quais conquistas já estavam desbloqueadas ANTES desta
    // partida ser salva — a tela de resultado usa isso pra saber quais são
    // novas e mostrar o pop-up de conquista.
    _unlockedBeforeIds = studentController.achievements
        .where((a) => a.unlocked)
        .map((a) => a.achievement.id)
        .toSet();
    studentController.saveResult(
          professorId: student.professorId,
          result: GameResultModel(
            id: '',
            studentId: student.id,
            studentName: student.name,
            gameId: 'soletrar',
            gameName: 'Soletrar Espacial',
            subject: 'Português',
            score: _score,
            totalQuestions: _words.length,
            playedAt: DateTime.now(),
            durationSeconds: DateTime.now().difference(_startTime).inSeconds,
          ),
        );
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
    if (content.isLoading || content.spellingWords.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.galaxyDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.galaxyViolet)),
      );
    }

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: AppTheme.galaxyDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.galaxyViolet)),
      );
    }

    if (_isFinished) {
      return GameResultScreen(
        gameEmoji: '🔤',
        gameTitle: 'Soletrar Espacial',
        score: _score,
        total: _words.length,
        durationSeconds: DateTime.now().difference(_startTime).inSeconds,
        onPlayAgain: _restart,
        previouslyUnlockedIds: _unlockedBeforeIds,
      );
    }

    final word = _words[_currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: SafeArea(
        child: Column(
          children: [
            GameTopBar(title: '🔤 Soletrar Espacial', current: _currentIndex, total: _words.length, score: _score),
            const SizedBox(height: 12),
            // Hint card
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
                  const Text('💡', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(word.hint, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  if (content.ttsHintEnabled) SpeakButton(textToSpeak: word.hint),
                ],
              ),
            ),
            const Spacer(),
            // Slots (answer area)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8, runSpacing: 8,
              children: List.generate(_slots.length, (i) {
                final filled = _slots[i] != null;
                Color border = AppTheme.galaxyPurple;
                Color bg = AppTheme.galaxyMid;
                if (_answered) {
                  border = _isCorrect ? AppTheme.galaxyGreen : AppTheme.galaxyPink;
                  bg = (_isCorrect ? AppTheme.galaxyGreen : AppTheme.galaxyPink).withOpacity(0.15);
                }
                return GestureDetector(
                  onTap: () => _tapSlot(i),
                  child: Container(
                    width: 38, height: 46,
                    decoration: BoxDecoration(
                      color: filled ? bg : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border, width: 2),
                    ),
                    child: Center(
                      child: Text(filled ? _slots[i]! : '', style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
                      )),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (_answered)
              Text(
                _isCorrect ? '✅ Correto!' : '❌ Era: ${word.word.toUpperCase()}',
                style: TextStyle(
                  color: _isCorrect ? AppTheme.galaxyGreen : AppTheme.galaxyPink,
                  fontWeight: FontWeight.bold, fontSize: 16,
                ),
              ),
            const Spacer(),
            // Letter bank
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10, runSpacing: 10,
                children: List.generate(_letterBank.length, (i) {
                  final used = _letterBank[i] == '\u0000';
                  return GestureDetector(
                    onTap: used ? null : () => _tapLetter(i),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: used ? 0.0 : 1.0,
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.galaxyPurple, AppTheme.galaxyCyan]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: AppTheme.galaxyPurple.withOpacity(0.4), blurRadius: 8)],
                        ),
                        child: Center(
                          child: Text(used ? '' : _letterBank[i], style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
                          )),
                        ),
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

  bool get _initialized => _words.isNotEmpty;
}
