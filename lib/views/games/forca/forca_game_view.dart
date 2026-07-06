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

class ForcaGameView extends StatefulWidget {
  const ForcaGameView({super.key});

  @override
  State<ForcaGameView> createState() => _ForcaGameViewState();
}

class _ForcaGameViewState extends State<ForcaGameView> {
  static const int maxMistakes = 6;
  static const List<String> alphabet = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
  ];

  List<WordEntryModel> _words = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isFinished = false;
  DateTime _startTime = DateTime.now();

  Set<String> _guessedLetters = {};
  int _mistakes = 0;
  bool _roundOver = false;
  bool _roundWon = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWords());
  }

  void _loadWords() {
    final content = context.read<GameContentController>();
    final list = [...content.spellingWords]..shuffle();
    setState(() {
      _words = list.take(6).toList();
      _setupRound();
    });
  }

  void _setupRound() {
    _guessedLetters = {};
    _mistakes = 0;
    _roundOver = false;
    _roundWon = false;
  }

  void _guessLetter(String letter) {
    if (_roundOver || _guessedLetters.contains(letter)) return;
    final word = _words[_currentIndex].word.toUpperCase();

    setState(() {
      _guessedLetters.add(letter);
      if (!word.contains(letter)) {
        _mistakes++;
      }

      final allRevealed = word.split('').every((c) => _guessedLetters.contains(c));
      if (allRevealed) {
        _roundOver = true;
        _roundWon = true;
        _score++;
      } else if (_mistakes >= maxMistakes) {
        _roundOver = true;
        _roundWon = false;
      }
    });

    if (_roundOver) {
      Future.delayed(const Duration(milliseconds: 1400), () {
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
  }

  void _saveResult() {
    final auth = context.read<AuthController>();
    final student = auth.currentStudent;
    if (student == null) return;
    context.read<StudentController>().saveResult(
          professorId: student.professorId,
          result: GameResultModel(
            id: '',
            studentId: student.id,
            studentName: student.name,
            gameId: 'forca',
            gameName: 'Forca Galáctica',
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
    if (content.isLoading || _words.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.galaxyDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.galaxyViolet)),
      );
    }

    if (_isFinished) {
      return GameResultScreen(
        gameEmoji: '🪐',
        gameTitle: 'Forca Galáctica',
        score: _score,
        total: _words.length,
        durationSeconds: DateTime.now().difference(_startTime).inSeconds,
        onPlayAgain: _restart,
      );
    }

    final word = _words[_currentIndex];
    final wordUpper = word.word.toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: SafeArea(
        child: Column(
          children: [
            GameTopBar(title: '🪐 Forca Galáctica', current: _currentIndex, total: _words.length, score: _score),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: _AstronautHangman(mistakes: _mistakes, maxMistakes: maxMistakes),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.galaxyMid,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.galaxyCyan.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(word.hint, style: const TextStyle(color: Colors.white, fontSize: 13))),
                  Text('${maxMistakes - _mistakes} ❤️', style: const TextStyle(color: AppTheme.galaxyPink, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8, runSpacing: 8,
              children: wordUpper.split('').map((letter) {
                final revealed = _guessedLetters.contains(letter) || (_roundOver && !_roundWon);
                return Container(
                  width: 32, height: 40,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(
                      color: revealed ? AppTheme.galaxyCyan : Colors.white24, width: 2,
                    )),
                  ),
                  child: Center(
                    child: Text(revealed ? letter : '', style: TextStyle(
                      color: _guessedLetters.contains(letter) ? Colors.white : AppTheme.galaxyPink.withOpacity(0.7),
                      fontSize: 22, fontWeight: FontWeight.bold,
                    )),
                  ),
                );
              }).toList(),
            ),
            if (_roundOver) ...[
              const SizedBox(height: 12),
              Text(
                _roundWon ? '✅ Você salvou o astronauta!' : '❌ A palavra era: $wordUpper',
                style: TextStyle(
                  color: _roundWon ? AppTheme.galaxyGreen : AppTheme.galaxyPink,
                  fontWeight: FontWeight.bold, fontSize: 14,
                ),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6, runSpacing: 6,
                children: alphabet.map((letter) {
                  final guessed = _guessedLetters.contains(letter);
                  final isHit = guessed && wordUpper.contains(letter);
                  final isMiss = guessed && !wordUpper.contains(letter);

                  Color bg = AppTheme.galaxyMid;
                  Color textColor = Colors.white;
                  if (isHit) { bg = AppTheme.galaxyGreen.withOpacity(0.3); textColor = AppTheme.galaxyGreen; }
                  if (isMiss) { bg = AppTheme.galaxyPink.withOpacity(0.2); textColor = Colors.white38; }

                  return GestureDetector(
                    onTap: (guessed || _roundOver) ? null : () => _guessLetter(letter),
                    child: Container(
                      width: 32, height: 38,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.galaxyPurple.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(letter, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _AstronautHangman extends StatelessWidget {
  final int mistakes;
  final int maxMistakes;
  const _AstronautHangman({required this.mistakes, required this.maxMistakes});

  @override
  Widget build(BuildContext context) {
    final oxygenLeft = (1 - mistakes / maxMistakes).clamp(0.0, 1.0);
    final emoji = mistakes == 0
        ? '🧑‍🚀'
        : mistakes < maxMistakes * 0.5
            ? '😰'
            : mistakes < maxMistakes
                ? '😱'
                : '💀';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: oxygenLeft,
                minHeight: 10,
                backgroundColor: AppTheme.galaxyMid,
                valueColor: AlwaysStoppedAnimation(
                  oxygenLeft > 0.5 ? AppTheme.galaxyGreen : oxygenLeft > 0.25 ? AppTheme.galaxyStar : AppTheme.galaxyPink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text('Oxigênio', style: TextStyle(color: Color(0xFF89B4FA), fontSize: 10)),
        ],
      ),
    );
  }
}
