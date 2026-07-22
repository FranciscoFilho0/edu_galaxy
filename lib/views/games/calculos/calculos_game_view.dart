import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/game_content_controller.dart';
import '../../../controllers/student_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/game_result_model.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/game_top_bar.dart';
import '../shared/game_result_screen.dart';

class _MathQuestion {
  final String expression;
  final int answer;
  final List<int> options;
  const _MathQuestion({required this.expression, required this.answer, required this.options});
}

class CalculosGameView extends StatefulWidget {
  const CalculosGameView({super.key});

  @override
  State<CalculosGameView> createState() => _CalculosGameViewState();
}

class _CalculosGameViewState extends State<CalculosGameView> {
  static const int totalQuestions = 10;

  late List<_MathQuestion> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  bool _isFinished = false;
  DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateQuestions());
  }

  void _generateQuestions() {
    final content = context.read<GameContentController>();
    final ops = content.enabledOperations.toList();
    final maxN = content.mathMaxNumber;
    final rng = Random();

    _questions = List.generate(totalQuestions, (_) {
      final op = ops[rng.nextInt(ops.length)];
      late int a, b, answer;
      late String symbol;

      switch (op) {
        case MathOperation.soma:
          a = rng.nextInt(maxN) + 1;
          b = rng.nextInt(maxN) + 1;
          answer = a + b;
          symbol = '+';
          break;
        case MathOperation.subtracao:
          a = rng.nextInt(maxN) + 1;
          b = rng.nextInt(a) + 1; // avoid negative
          answer = a - b;
          symbol = '−';
          break;
        case MathOperation.multiplicacao:
          a = rng.nextInt(10) + 1;
          b = rng.nextInt(10) + 1;
          answer = a * b;
          symbol = '×';
          break;
        case MathOperation.divisao:
          b = rng.nextInt(9) + 1;
          answer = rng.nextInt(10) + 1;
          a = answer * b; // ensures whole number division
          symbol = '÷';
          break;
      }

      // Generate distractor options
      final optionsSet = <int>{answer};
      while (optionsSet.length < 4) {
        final delta = rng.nextInt(9) - 4;
        final fake = answer + delta;
        if (fake >= 0 && fake != answer) optionsSet.add(fake);
      }
      final options = optionsSet.toList()..shuffle();

      return _MathQuestion(expression: '$a $symbol $b', answer: answer, options: options);
    });

    setState(() {});
  }

  void _selectAnswer(int value) {
    if (_answered) return;
    setState(() {
      _selectedOption = value;
      _answered = true;
      if (value == _questions[_currentIndex].answer) _score++;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_currentIndex < totalQuestions - 1) {
        setState(() {
          _currentIndex++;
          _selectedOption = null;
          _answered = false;
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
            gameId: 'calculos',
            gameName: 'Cálculos Espaciais',
            subject: 'Matemática',
            score: _score,
            totalQuestions: totalQuestions,
            playedAt: DateTime.now(),
            durationSeconds: DateTime.now().difference(_startTime).inSeconds,
          ),
        );
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
      _isFinished = false;
      _startTime = DateTime.now();
    });
    _generateQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<GameContentController>();
    if (content.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.galaxyDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.galaxyViolet)),
      );
    }

    if (_questions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.galaxyDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.galaxyViolet)),
      );
    }

    final isFinished = _isFinished;

    if (isFinished) {
      return GameResultScreen(
        gameEmoji: '🔢',
        gameTitle: 'Quiz Matemático',
        score: _score,
        total: totalQuestions,
        durationSeconds: DateTime.now().difference(_startTime).inSeconds,
        onPlayAgain: _restart,
        previouslyUnlockedIds: _unlockedBeforeIds,
      );
    }

    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: SafeArea(
        child: Column(
          children: [
            GameTopBar(title: '🔢 Cálculos Espaciais', current: _currentIndex, total: totalQuestions, score: _score),
            const Spacer(),
            // Expression card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.galaxyPurple, Color(0xFF4C1D95)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppTheme.galaxyPurple.withOpacity(0.4), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  const Text('🛸', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
                  Text(q.expression, style: const TextStyle(
                    color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold, letterSpacing: 2,
                  )),
                  const SizedBox(height: 8),
                  const Text('= ?', style: TextStyle(color: Colors.white70, fontSize: 22)),
                ],
              ),
            ),
            const SizedBox(height: 36),
            // Options grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 2.2,
                children: q.options.map((opt) {
                  Color bg = AppTheme.galaxyMid;
                  Color border = AppTheme.galaxyPurple.withOpacity(0.3);
                  if (_answered) {
                    if (opt == q.answer) {
                      bg = AppTheme.galaxyGreen.withOpacity(0.25);
                      border = AppTheme.galaxyGreen;
                    } else if (opt == _selectedOption) {
                      bg = AppTheme.galaxyPink.withOpacity(0.25);
                      border = AppTheme.galaxyPink;
                    }
                  }
                  return GestureDetector(
                    onTap: () => _selectAnswer(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border, width: 2),
                      ),
                      child: Center(
                        child: Text('$opt', style: const TextStyle(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
                        )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
