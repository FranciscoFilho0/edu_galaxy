import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/game_content_controller.dart';
import '../../../controllers/student_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/quiz_question_model.dart';
import '../../../models/game_result_model.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/game_top_bar.dart';
import '../shared/game_result_screen.dart';

class PerguntasGameView extends StatefulWidget {
  const PerguntasGameView({super.key});

  @override
  State<PerguntasGameView> createState() => _PerguntasGameViewState();
}

class _PerguntasGameViewState extends State<PerguntasGameView> {
  List<QuizQuestionModel> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isFinished = false;
  DateTime _startTime = DateTime.now();

  int? _selectedIndex;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
  }

  void _loadQuestions() {
    final content = context.read<GameContentController>();
    final list = [...content.quizQuestions]..shuffle();
    setState(() => _questions = list.take(8).toList());
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    final correct = index == _questions[_currentIndex].correctIndex;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (correct) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedIndex = null;
          _answered = false;
        });
      } else {
        setState(() => _isFinished = true);
        _saveResult();
      }
    });
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
            gameId: 'perguntas',
            gameName: 'Perguntas Espaciais',
            subject: 'Geral',
            score: _score,
            totalQuestions: _questions.length,
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
      _selectedIndex = null;
      _answered = false;
      _startTime = DateTime.now();
    });
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<GameContentController>();
    if (content.isLoading || _questions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.galaxyDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.galaxyViolet)),
      );
    }

    if (_isFinished) {
      return GameResultScreen(
        gameEmoji: '❓',
        gameTitle: 'Perguntas Espaciais',
        score: _score,
        total: _questions.length,
        durationSeconds: DateTime.now().difference(_startTime).inSeconds,
        onPlayAgain: _restart,
      );
    }

    final q = _questions[_currentIndex];
    final letters = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: SafeArea(
        child: Column(
          children: [
            GameTopBar(title: '❓ Perguntas Espaciais', current: _currentIndex, total: _questions.length, score: _score),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.galaxyCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(q.subject, style: const TextStyle(color: AppTheme.galaxyCyan, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.galaxyPurple, Color(0xFF4C1D95)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppTheme.galaxyPurple.withOpacity(0.4), blurRadius: 16)],
              ),
              child: Column(
                children: [
                  const Text('🛰️', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 10),
                  Text(q.question, textAlign: TextAlign.center, style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.3,
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: q.options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  Color bg = AppTheme.galaxyMid;
                  Color border = AppTheme.galaxyPurple.withOpacity(0.3);
                  if (_answered) {
                    if (i == q.correctIndex) {
                      bg = AppTheme.galaxyGreen.withOpacity(0.2);
                      border = AppTheme.galaxyGreen;
                    } else if (i == _selectedIndex) {
                      bg = AppTheme.galaxyPink.withOpacity(0.2);
                      border = AppTheme.galaxyPink;
                    }
                  }
                  return GestureDetector(
                    onTap: () => _selectAnswer(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Center(child: Text(letters[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(q.options[i], style: const TextStyle(color: Colors.white, fontSize: 15))),
                          if (_answered && i == q.correctIndex)
                            const Icon(Icons.check_circle, color: AppTheme.galaxyGreen, size: 20),
                          if (_answered && i == _selectedIndex && i != q.correctIndex)
                            const Icon(Icons.cancel, color: AppTheme.galaxyPink, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
