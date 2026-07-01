import 'package:flutter/foundation.dart';

class GameSessionController extends ChangeNotifier {
  int _score = 0;
  int _totalQuestions = 0;
  int _currentIndex = 0;
  DateTime? _startTime;
  bool _finished = false;

  int get score => _score;
  int get totalQuestions => _totalQuestions;
  int get currentIndex => _currentIndex;
  bool get finished => _finished;
  int get elapsedSeconds =>
      _startTime == null ? 0 : DateTime.now().difference(_startTime!).inSeconds;

  void start(int totalQuestions) {
    _score = 0;
    _totalQuestions = totalQuestions;
    _currentIndex = 0;
    _startTime = DateTime.now();
    _finished = false;
    notifyListeners();
  }

  void registerCorrect() {
    _score++;
    notifyListeners();
  }

  void nextQuestion() {
    _currentIndex++;
    if (_currentIndex >= _totalQuestions) {
      _finished = true;
    }
    notifyListeners();
  }

  void finish() {
    _finished = true;
    notifyListeners();
  }

  void reset() {
    _score = 0;
    _currentIndex = 0;
    _startTime = null;
    _finished = false;
    notifyListeners();
  }
}
