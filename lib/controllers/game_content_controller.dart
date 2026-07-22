import 'package:flutter/foundation.dart';
import '../models/quiz_question_model.dart';
import '../models/word_entry_model.dart';
import '../models/math_operation.dart';
import '../services/firestore_service.dart';

export '../models/math_operation.dart' show MathOperation;

/// GameContentController guarda o conteúdo dos jogos (perguntas, palavras,
/// configuração de matemática) DE UMA SALA POR VEZ. Por isso todo método
/// que altera dado agora recebe o professorId: é ele quem diz em qual
/// pasta do Firestore (rooms/{professorId}/...) a informação deve ser lida
/// ou gravada.
class GameContentController extends ChangeNotifier {
  final FirestoreService _db = FirestoreService.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _loadedForProfessorId;

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

  // ── Voz (TTS) dos jogos de palavras ────────────────────────────────────
  // Quando true, Forca/Soletrar/Sílabas mostram o botão de alto-falante que
  // lê a DICA (nunca a palavra) ao ser tocado. Quando false, nenhum som é
  // reproduzido nesses jogos.
  bool _ttsHintEnabled = true;
  bool get ttsHintEnabled => _ttsHintEnabled;

  /// Carrega o conteúdo da sala do [professorId]. Se essa sala nunca teve
  /// conteúdo cadastrado (professor novo), semeia com o conteúdo de exemplo
  /// e já salva no banco, para o professor começar com algo pronto.
  Future<void> loadContent(String professorId) async {
    if (professorId.isEmpty) return;
    if (_loadedForProfessorId == professorId) return; // já carregado, evita ida repetida ao banco
    _isLoading = true;
    notifyListeners();

    try {
      var quiz = await _db.fetchQuizQuestions(professorId);
      var spelling = await _db.fetchWords(professorId, 'spellingWords');
      var syllables = await _db.fetchWords(professorId, 'syllableWords');
      final mathConfig = await _db.fetchMathConfig(professorId);
      final wordGamesConfig = await _db.fetchWordGamesConfig(professorId);

      if (quiz.isEmpty && spelling.isEmpty && syllables.isEmpty && mathConfig == null) {
        await _seedDefaultContent(professorId);
        quiz = await _db.fetchQuizQuestions(professorId);
        spelling = await _db.fetchWords(professorId, 'spellingWords');
        syllables = await _db.fetchWords(professorId, 'syllableWords');
      }

      _quizQuestions = quiz;
      _spellingWords = spelling;
      _syllableWords = syllables;

      if (mathConfig != null) {
        final ops = (mathConfig['operations'] as List<dynamic>? ?? [])
            .map((s) => MathOperation.values.firstWhere((o) => o.name == s, orElse: () => MathOperation.soma))
            .toSet();
        _enabledOperations = ops.isEmpty ? {MathOperation.soma, MathOperation.subtracao} : ops;
        _mathMaxNumber = mathConfig['maxNumber'] ?? 20;
      } else {
        _enabledOperations = {MathOperation.soma, MathOperation.subtracao};
        _mathMaxNumber = 20;
        await _db.saveMathConfig(professorId: professorId, operations: _enabledOperations, maxNumber: _mathMaxNumber);
      }

      _ttsHintEnabled = wordGamesConfig?['ttsHintEnabled'] ?? true;

      _loadedForProfessorId = professorId;
    } catch (e) {
      debugPrint('Erro ao carregar conteúdo dos jogos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _seedDefaultContent(String professorId) async {
    final defaultQuiz = [
      const QuizQuestionModel(id: 'q1', subject: 'Ciências', question: 'Qual planeta é conhecido como Planeta Vermelho?', options: ['Vênus', 'Marte', 'Júpiter', 'Saturno'], correctIndex: 1),
      const QuizQuestionModel(id: 'q2', subject: 'Geografia', question: 'Qual é a capital do Brasil?', options: ['Rio de Janeiro', 'São Paulo', 'Brasília', 'Salvador'], correctIndex: 2),
      const QuizQuestionModel(id: 'q3', subject: 'História', question: 'Em que ano o Brasil foi descoberto?', options: ['1500', '1822', '1889', '1450'], correctIndex: 0),
      const QuizQuestionModel(id: 'q4', subject: 'Ciências', question: 'Quantos planetas existem no Sistema Solar?', options: ['7', '8', '9', '10'], correctIndex: 1),
      const QuizQuestionModel(id: 'q5', subject: 'Matemática', question: 'Quanto é 7 x 8?', options: ['54', '56', '64', '48'], correctIndex: 1),
    ];
    final defaultSpelling = [
      const WordEntryModel(id: 'w1', word: 'FOGUETE', hint: 'Veículo que viaja ao espaço', subject: 'Ciências'),
      const WordEntryModel(id: 'w2', word: 'PLANETA', hint: 'Corpo celeste que orbita uma estrela', subject: 'Ciências'),
      const WordEntryModel(id: 'w3', word: 'ESTRELA', hint: 'Brilha no céu à noite', subject: 'Ciências'),
      const WordEntryModel(id: 'w4', word: 'GALAXIA', hint: 'Conjunto de bilhões de estrelas', subject: 'Ciências'),
      const WordEntryModel(id: 'w5', word: 'ASTRONAUTA', hint: 'Pessoa que viaja ao espaço', subject: 'Ciências'),
      const WordEntryModel(id: 'w6', word: 'BORBOLETA', hint: 'Inseto colorido que voa', subject: 'Português'),
      const WordEntryModel(id: 'w7', word: 'ELEFANTE', hint: 'Animal grande com tromba', subject: 'Português'),
    ];
    final defaultSyllables = [
      const WordEntryModel(id: 's1', word: 'FOGUETE', hint: 'Veículo espacial', subject: 'Português'),
      const WordEntryModel(id: 's2', word: 'CACHORRO', hint: 'Melhor amigo do homem', subject: 'Português'),
      const WordEntryModel(id: 's3', word: 'BICICLETA', hint: 'Veículo de duas rodas', subject: 'Português'),
      const WordEntryModel(id: 's4', word: 'COMPUTADOR', hint: 'Usado para trabalhar e jogar', subject: 'Português'),
      const WordEntryModel(id: 's5', word: 'GIRASSOL', hint: 'Flor amarela que segue o sol', subject: 'Português'),
      const WordEntryModel(id: 's6', word: 'CHOCOLATE', hint: 'Doce muito gostoso', subject: 'Português'),
    ];

    for (final q in defaultQuiz) {
      await _db.saveQuizQuestion(professorId, q);
    }
    for (final w in defaultSpelling) {
      await _db.saveWord(professorId, 'spellingWords', w);
    }
    for (final w in defaultSyllables) {
      await _db.saveWord(professorId, 'syllableWords', w);
    }
  }

  // ── Quiz CRUD ───────────────────────────────────────────────────────────
  Future<void> addQuizQuestion(String professorId, QuizQuestionModel q) async {
    _quizQuestions = [..._quizQuestions, q];
    notifyListeners();
    await _db.saveQuizQuestion(professorId, q);
  }

  Future<void> updateQuizQuestion(String professorId, QuizQuestionModel q) async {
    _quizQuestions = _quizQuestions.map((e) => e.id == q.id ? q : e).toList();
    notifyListeners();
    await _db.saveQuizQuestion(professorId, q);
  }

  Future<void> removeQuizQuestion(String professorId, String id) async {
    _quizQuestions = _quizQuestions.where((e) => e.id != id).toList();
    notifyListeners();
    await _db.deleteQuizQuestion(professorId, id);
  }

  // ── Spelling words CRUD ────────────────────────────────────────────────
  Future<void> addSpellingWord(String professorId, WordEntryModel w) async {
    _spellingWords = [..._spellingWords, w];
    notifyListeners();
    await _db.saveWord(professorId, 'spellingWords', w);
  }

  Future<void> updateSpellingWord(String professorId, WordEntryModel w) async {
    _spellingWords = _spellingWords.map((e) => e.id == w.id ? w : e).toList();
    notifyListeners();
    await _db.saveWord(professorId, 'spellingWords', w);
  }

  Future<void> removeSpellingWord(String professorId, String id) async {
    _spellingWords = _spellingWords.where((e) => e.id != id).toList();
    notifyListeners();
    await _db.deleteWord(professorId, 'spellingWords', id);
  }

  // ── Syllable words CRUD ────────────────────────────────────────────────
  Future<void> addSyllableWord(String professorId, WordEntryModel w) async {
    _syllableWords = [..._syllableWords, w];
    notifyListeners();
    await _db.saveWord(professorId, 'syllableWords', w);
  }

  Future<void> updateSyllableWord(String professorId, WordEntryModel w) async {
    _syllableWords = _syllableWords.map((e) => e.id == w.id ? w : e).toList();
    notifyListeners();
    await _db.saveWord(professorId, 'syllableWords', w);
  }

  Future<void> removeSyllableWord(String professorId, String id) async {
    _syllableWords = _syllableWords.where((e) => e.id != id).toList();
    notifyListeners();
    await _db.deleteWord(professorId, 'syllableWords', id);
  }

  // ── Math config ─────────────────────────────────────────────────────────
  Future<void> toggleOperation(String professorId, MathOperation op) async {
    if (_enabledOperations.contains(op)) {
      if (_enabledOperations.length > 1) {
        _enabledOperations = {..._enabledOperations}..remove(op);
      }
    } else {
      _enabledOperations = {..._enabledOperations, op};
    }
    notifyListeners();
    await _db.saveMathConfig(professorId: professorId, operations: _enabledOperations, maxNumber: _mathMaxNumber);
  }

  Future<void> setMathMaxNumber(String professorId, int value) async {
    _mathMaxNumber = value;
    notifyListeners();
    await _db.saveMathConfig(professorId: professorId, operations: _enabledOperations, maxNumber: _mathMaxNumber);
  }

  // ── Voz (TTS) dos jogos de palavras ────────────────────────────────────
  Future<void> setTtsHintEnabled(String professorId, bool value) async {
    _ttsHintEnabled = value;
    notifyListeners();
    await _db.saveWordGamesConfig(professorId: professorId, ttsHintEnabled: value);
  }
}
