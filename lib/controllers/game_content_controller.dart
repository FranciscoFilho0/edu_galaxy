import 'package:flutter/foundation.dart';
import '../models/quiz_question_model.dart';
import '../models/word_entry_model.dart';

enum MathOperation { soma, subtracao, multiplicacao, divisao }

class GameContentController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Perguntas e Respostas ──────────────────────────────────────────────
  List<QuizQuestionModel> _quizQuestions = [];
  List<QuizQuestionModel> get quizQuestions => _quizQuestions;

  // ── Soletrar / Forca ────────────────────────────────────────────────────
  List<WordEntryModel> _spellingWords = [];
  List<WordEntryModel> get spellingWords => _spellingWords;

  // ── Sílabas ─────────────────────────────────────────────────────────────
  List<WordEntryModel> _syllableWords = [];
  List<WordEntryModel> get syllableWords => _syllableWords;

  // ── Cálculos config ─────────────────────────────────────────────────────
  Set<MathOperation> _enabledOperations = {
    MathOperation.soma,
    MathOperation.subtracao,
  };
  Set<MathOperation> get enabledOperations => _enabledOperations;
  int _mathMaxNumber = 20;
  int get mathMaxNumber => _mathMaxNumber;

  Future<void> loadContent() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));

    _quizQuestions = [
      const QuizQuestionModel(
        id: 'q1', subject: 'Ciências',
        question: 'Qual planeta é conhecido como Planeta Vermelho?',
        options: ['Vênus', 'Marte', 'Júpiter', 'Saturno'],
        correctIndex: 1,
      ),
      const QuizQuestionModel(
        id: 'q2', subject: 'Geografia',
        question: 'Qual é a capital do Brasil?',
        options: ['Rio de Janeiro', 'São Paulo', 'Brasília', 'Salvador'],
        correctIndex: 2,
      ),
      const QuizQuestionModel(
        id: 'q3', subject: 'História',
        question: 'Em que ano o Brasil foi descoberto?',
        options: ['1500', '1822', '1889', '1450'],
        correctIndex: 0,
      ),
      const QuizQuestionModel(
        id: 'q4', subject: 'Ciências',
        question: 'Quantos planetas existem no Sistema Solar?',
        options: ['7', '8', '9', '10'],
        correctIndex: 1,
      ),
      const QuizQuestionModel(
        id: 'q5', subject: 'Matemática',
        question: 'Quanto é 7 x 8?',
        options: ['54', '56', '64', '48'],
        correctIndex: 1,
      ),
    ];

    _spellingWords = [
      const WordEntryModel(id: 'w1', word: 'FOGUETE', hint: 'Veículo que viaja ao espaço', subject: 'Ciências'),
      const WordEntryModel(id: 'w2', word: 'PLANETA', hint: 'Corpo celeste que orbita uma estrela', subject: 'Ciências'),
      const WordEntryModel(id: 'w3', word: 'ESTRELA', hint: 'Brilha no céu à noite', subject: 'Ciências'),
      const WordEntryModel(id: 'w4', word: 'GALAXIA', hint: 'Conjunto de bilhões de estrelas', subject: 'Ciências'),
      const WordEntryModel(id: 'w5', word: 'ASTRONAUTA', hint: 'Pessoa que viaja ao espaço', subject: 'Ciências'),
      const WordEntryModel(id: 'w6', word: 'BORBOLETA', hint: 'Inseto colorido que voa', subject: 'Português'),
      const WordEntryModel(id: 'w7', word: 'ELEFANTE', hint: 'Animal grande com tromba', subject: 'Português'),
    ];

    _syllableWords = [
      const WordEntryModel(id: 's1', word: 'FOGUETE', hint: 'Veículo espacial', subject: 'Português'),
      const WordEntryModel(id: 's2', word: 'CACHORRO', hint: 'Melhor amigo do homem', subject: 'Português'),
      const WordEntryModel(id: 's3', word: 'BICICLETA', hint: 'Veículo de duas rodas', subject: 'Português'),
      const WordEntryModel(id: 's4', word: 'COMPUTADOR', hint: 'Usado para trabalhar e jogar', subject: 'Português'),
      const WordEntryModel(id: 's5', word: 'GIRASSOL', hint: 'Flor amarela que segue o sol', subject: 'Português'),
      const WordEntryModel(id: 's6', word: 'CHOCOLATE', hint: 'Doce muito gostoso', subject: 'Português'),
    ];

    _isLoading = false;
    notifyListeners();
  }

  // ── Quiz CRUD ───────────────────────────────────────────────────────────
  void addQuizQuestion(QuizQuestionModel q) {
    _quizQuestions = [..._quizQuestions, q];
    notifyListeners();
  }

  void updateQuizQuestion(QuizQuestionModel q) {
    _quizQuestions = _quizQuestions.map((e) => e.id == q.id ? q : e).toList();
    notifyListeners();
  }

  void removeQuizQuestion(String id) {
    _quizQuestions = _quizQuestions.where((e) => e.id != id).toList();
    notifyListeners();
  }

  // ── Spelling words CRUD ────────────────────────────────────────────────
  void addSpellingWord(WordEntryModel w) {
    _spellingWords = [..._spellingWords, w];
    notifyListeners();
  }

  void updateSpellingWord(WordEntryModel w) {
    _spellingWords = _spellingWords.map((e) => e.id == w.id ? w : e).toList();
    notifyListeners();
  }

  void removeSpellingWord(String id) {
    _spellingWords = _spellingWords.where((e) => e.id != id).toList();
    notifyListeners();
  }

  // ── Syllable words CRUD ────────────────────────────────────────────────
  void addSyllableWord(WordEntryModel w) {
    _syllableWords = [..._syllableWords, w];
    notifyListeners();
  }

  void updateSyllableWord(WordEntryModel w) {
    _syllableWords = _syllableWords.map((e) => e.id == w.id ? w : e).toList();
    notifyListeners();
  }

  void removeSyllableWord(String id) {
    _syllableWords = _syllableWords.where((e) => e.id != id).toList();
    notifyListeners();
  }

  // ── Math config ─────────────────────────────────────────────────────────
  void toggleOperation(MathOperation op) {
    if (_enabledOperations.contains(op)) {
      if (_enabledOperations.length > 1) {
        _enabledOperations = {..._enabledOperations}..remove(op);
      }
    } else {
      _enabledOperations = {..._enabledOperations, op};
    }
    notifyListeners();
  }

  void setMathMaxNumber(int value) {
    _mathMaxNumber = value;
    notifyListeners();
  }
}
