import 'package:flutter/foundation.dart';

import '../models/quiz_question_model.dart';
import '../models/word_entry_model.dart';
import '../models/math_operation.dart';
import '../services/firestore_service.dart';

export '../models/math_operation.dart' show MathOperation;


/// Controller responsável pelo conteúdo dos jogos de UMA SALA.
///
/// Toda informação dos jogos pertence a uma turma específica.
/// Por isso utilizamos roomId e não professorId.
///
/// Estrutura Firebase:
///
/// rooms/{roomId}/
///    quizQuestions
///    spellingWords
///    syllableWords
///    mathConfig
///    wordGamesConfig
///
class GameContentController extends ChangeNotifier {


  final FirestoreService _db =
      FirestoreService.instance;



  // ============================================================
  // ESTADO
  // ============================================================


  bool _isLoading = false;


  bool get isLoading =>
      _isLoading;



  /// Guarda qual sala está carregada atualmente.
  /// Evita consultas repetidas no Firebase.
  String? _loadedForRoomId;




  // ============================================================
  // QUIZ
  // ============================================================


  List<QuizQuestionModel> _quizQuestions = [];


  List<QuizQuestionModel> get quizQuestions =>
      _quizQuestions;




  // ============================================================
  // PALAVRAS - SOLETRAR
  // ============================================================


  List<WordEntryModel> _spellingWords = [];


  List<WordEntryModel> get spellingWords =>
      _spellingWords;




  // ============================================================
  // PALAVRAS - SÍLABAS
  // ============================================================


  List<WordEntryModel> _syllableWords = [];


  List<WordEntryModel> get syllableWords =>
      _syllableWords;




  // ============================================================
  // CONFIGURAÇÃO MATEMÁTICA
  // ============================================================


  Set<MathOperation> _enabledOperations = {

    MathOperation.soma,

    MathOperation.subtracao,

  };



  Set<MathOperation> get enabledOperations =>
      _enabledOperations;



  int _mathMaxNumber = 20;



  int get mathMaxNumber =>
      _mathMaxNumber;




  // ============================================================
  // CONFIGURAÇÃO DE ÁUDIO
  // ============================================================


  bool _ttsHintEnabled = true;



  bool get ttsHintEnabled =>
      _ttsHintEnabled;



  // ============================================================
  // CARREGAR CONTEÚDO DA SALA
  // ============================================================


  /// Carrega todos os conteúdos pertencentes a uma sala.
  ///
  /// Cada sala possui seus próprios:
  /// - Quiz
  /// - Palavras
  /// - Sílabas
  /// - Configuração matemática
  ///
  Future<void> loadContent(String roomId, {String professorId = ''}) async {


    if (roomId.isEmpty) return;



    // Evita consultas repetidas
    if (_loadedForRoomId == roomId) {
      return;
    }



    _isLoading = true;

    notifyListeners();



    try {



var spelling =
    await _db.fetchWords(
      roomId: roomId,
      collectionName: 'spellingWords',
    );


var syllables =
    await _db.fetchWords(
      roomId: roomId,
      collectionName: 'syllableWords',
    );


final mathConfig =
    await _db.fetchMathConfig(
      roomId: roomId,
    );


final wordGamesConfig =
    await _db.fetchWordGamesConfig(
      roomId: roomId,
    );

    var quiz =
    await _db.fetchQuizQuestions(
      roomId: roomId,
    );





      // Caso seja uma sala nova,
      // cria conteúdo inicial.
      if(
        quiz.isEmpty &&
        spelling.isEmpty &&
        syllables.isEmpty &&
        mathConfig == null
      ){


        await _seedDefaultContent(
          roomId,
          professorId,
        );



       var quiz =
    await _db.fetchQuizQuestions(
      roomId: roomId,
    );



        var spelling =
    await _db.fetchWords(
  roomId: roomId,
  collectionName: 'spellingWords',
);



        syllables =
            await _db.fetchWords(
  roomId: roomId,
  collectionName: 'syllableWords',
);


      }




      _quizQuestions = quiz;


      _spellingWords = spelling;


      _syllableWords = syllables;





      // ========================================================
      // CONFIG MATEMÁTICA
      // ========================================================


      if(mathConfig != null){


        final operations =
            (mathConfig['operations']
                as List<dynamic>? ??
                [])
            .map(
              (item) =>
                  MathOperation.values.firstWhere(
                    (op) =>
                        op.name == item,
                    orElse: () =>
                        MathOperation.soma,
                  ),
            )
            .toSet();



        _enabledOperations =
            operations.isEmpty
                ?
                {
                  MathOperation.soma,
                  MathOperation.subtracao,
                }
                :
                operations;



        _mathMaxNumber =
            mathConfig['maxNumber'] ?? 20;



      }else{


        _enabledOperations =
        {
          MathOperation.soma,
          MathOperation.subtracao,
        };


        _mathMaxNumber = 20;



        await _db.saveMathConfig(
          roomId: roomId,
          operations: _enabledOperations,
          maxNumber: _mathMaxNumber,
        );


      }





      _ttsHintEnabled =
          wordGamesConfig?['ttsHintEnabled']
          ??
          true;




      _loadedForRoomId =
          roomId;



    }catch(e){


      debugPrint(
        'Erro ao carregar conteúdo dos jogos: $e',
      );


    }



    _isLoading = false;


    notifyListeners();

  }

  // ============================================================
  // CONTEÚDO INICIAL DA SALA
  // ============================================================


  Future<void> _seedDefaultContent(
    String roomId,
    String professorId,
  ) async {


    final defaultQuiz = [


      QuizQuestionModel(
        id: 'q1',
        roomId: roomId,
        professorId: professorId,
        subject: 'Ciências',
        question:
            'Qual planeta é conhecido como Planeta Vermelho?',
        options:
        [
          'Vênus',
          'Marte',
          'Júpiter',
          'Saturno',
        ],
        correctIndex: 1,
      ),



      QuizQuestionModel(
        id: 'q2',
        roomId: roomId,
        professorId: professorId,
        subject: 'Geografia',
        question:
            'Qual é a capital do Brasil?',
        options:
        [
          'Rio de Janeiro',
          'São Paulo',
          'Brasília',
          'Salvador',
        ],
        correctIndex: 2,
      ),



      QuizQuestionModel(
        id: 'q3',
        roomId: roomId,
        professorId: professorId,
        subject: 'História',
        question:
            'Em que ano o Brasil foi descoberto?',
        options:
        [
          '1500',
          '1822',
          '1889',
          '1450',
        ],
        correctIndex: 0,
      ),



      QuizQuestionModel(
        id: 'q4',
        roomId: roomId,
        professorId: professorId,
        subject: 'Ciências',
        question:
            'Quantos planetas existem no Sistema Solar?',
        options:
        [
          '7',
          '8',
          '9',
          '10',
        ],
        correctIndex: 1,
      ),



      QuizQuestionModel(
        id: 'q5',
        roomId: roomId,
        professorId: professorId,
        subject: 'Matemática',
        question:
            'Quanto é 7 x 8?',
        options:
        [
          '54',
          '56',
          '64',
          '48',
        ],
        correctIndex: 1,
      ),

    ];




    final defaultSpelling = [


      WordEntryModel(
        id: 'w1',
        roomId: roomId,
        professorId: professorId,
        word: 'FOGUETE',
        hint:
            'Veículo que viaja ao espaço',
        subject:
            'Ciências',
      ),



      WordEntryModel(
        id: 'w2',
        roomId: roomId,
        professorId: professorId,
        word: 'PLANETA',
        hint:
            'Corpo celeste que orbita uma estrela',
        subject:
            'Ciências',
      ),



      WordEntryModel(
        id: 'w3',
        roomId: roomId,
        professorId: professorId,
        word: 'ESTRELA',
        hint:
            'Brilha no céu à noite',
        subject:
            'Ciências',
      ),



      WordEntryModel(
        id: 'w4',
        roomId: roomId,
        professorId: professorId,
        word: 'GALAXIA',
        hint:
            'Conjunto de bilhões de estrelas',
        subject:
            'Ciências',
      ),



      WordEntryModel(
        id: 'w5',
        roomId: roomId,
        professorId: professorId,
        word: 'ASTRONAUTA',
        hint:
            'Pessoa que viaja ao espaço',
        subject:
            'Ciências',
      ),

    ];





    final defaultSyllables = [


      WordEntryModel(
        id: 's1',
        roomId: roomId,
        professorId: professorId,
        word: 'FOGUETE',
        hint:
            'Veículo espacial',
        subject:
            'Português',
      ),



      WordEntryModel(
        id: 's2',
        roomId: roomId,
        professorId: professorId,
        word: 'CACHORRO',
        hint:
            'Melhor amigo do homem',
        subject:
            'Português',
      ),



      WordEntryModel(
        id: 's3',
        roomId: roomId,
        professorId: professorId,
        word: 'BICICLETA',
        hint:
            'Veículo de duas rodas',
        subject:
            'Português',
      ),



      WordEntryModel(
        id: 's4',
        roomId: roomId,
        professorId: professorId,
        word: 'COMPUTADOR',
        hint:
            'Usado para trabalhar e jogar',
        subject:
            'Português',
      ),



      WordEntryModel(
        id: 's5',
        roomId: roomId,
        professorId: professorId,
        word: 'GIRASSOL',
        hint:
            'Flor amarela que segue o sol',
        subject:
            'Português',
      ),


    ];





    // Salva perguntas iniciais

    for(final q in defaultQuiz){

      await _db.saveQuizQuestion(
  roomId: roomId,
  question: q,
);

    }





    // Salva palavras de soletrar

    for(final word in defaultSpelling){
await _db.saveWord(
  roomId: roomId,
  collectionName: 'spellingWords',
  word: word,
);

    }





    // Salva palavras de sílabas

    for(final word in defaultSyllables){

      await _db.saveWord(
  roomId: roomId,
  collectionName: 'syllableWords',
  word: word,
);

    }

  }
  // ── Quiz CRUD ───────────────────────────────────────────────────────────
Future<void> addQuizQuestion(
  String roomId,
  QuizQuestionModel q,
) async {

  _quizQuestions = [
    ..._quizQuestions,
    q,
  ];

  notifyListeners();

  await _db.saveQuizQuestion(
    roomId: roomId,
    question: q,
  );
}
Future<void> updateQuizQuestion(
  String roomId,
  QuizQuestionModel q,
) async {

  _quizQuestions =
      _quizQuestions.map(
        (e) => e.id == q.id ? q : e,
      ).toList();

  notifyListeners();

  await _db.saveQuizQuestion(
    roomId: roomId,
    question: q,
  );
}
Future<void> removeQuizQuestion(
  String roomId,
  String id,
) async {

  _quizQuestions =
      _quizQuestions
          .where((e) => e.id != id)
          .toList();

  notifyListeners();

  await _db.deleteQuizQuestion(
    roomId: roomId,
    id: id,
  );
}
  // ── Spelling words CRUD ────────────────────────────────────────────────
Future<void> addSpellingWord(
 String roomId,
 WordEntryModel w,
) async {

  _spellingWords = [
    ..._spellingWords,
    w,
  ];

  notifyListeners();

  await _db.saveWord(
    roomId: roomId,
    collectionName: 'spellingWords',
    word: w,
  );
}
  // ── Spelling words CRUD ────────────────────────────────────────────────
Future<void> updateSpellingWord(
  String roomId,
  WordEntryModel w,
) async {

  _spellingWords =
      _spellingWords
          .map(
            (e) => e.id == w.id ? w : e,
          )
          .toList();

  notifyListeners();

  await _db.saveWord(
    roomId: roomId,
    collectionName: 'spellingWords',
    word: w,
  );
}


Future<void> removeSpellingWord(
  String roomId,
  String id,
) async {

  _spellingWords =
      _spellingWords
          .where(
            (e) => e.id != id,
          )
          .toList();

  notifyListeners();

  await _db.deleteWord(
    roomId: roomId,
    collectionName: 'spellingWords',
    id: id,
  );
}


// ── Syllable words CRUD ────────────────────────────────────────────────


Future<void> addSyllableWord(
  String roomId,
  WordEntryModel w,
) async {

  _syllableWords = [
    ..._syllableWords,
    w,
  ];

  notifyListeners();

  await _db.saveWord(
    roomId: roomId,
    collectionName: 'syllableWords',
    word: w,
  );
}



Future<void> updateSyllableWord(
  String roomId,
  WordEntryModel w,
) async {

  _syllableWords =
      _syllableWords
          .map(
            (e) => e.id == w.id ? w : e,
          )
          .toList();

  notifyListeners();

  await _db.saveWord(
    roomId: roomId,
    collectionName: 'syllableWords',
    word: w,
  );
}



Future<void> removeSyllableWord(
  String roomId,
  String id,
) async {

  _syllableWords =
      _syllableWords
          .where(
            (e) => e.id != id,
          )
          .toList();

  notifyListeners();

  await _db.deleteWord(
    roomId: roomId,
    collectionName: 'syllableWords',
    id: id,
  );
}



// ── Math config ─────────────────────────────────────────────────────────


Future<void> toggleOperation(
  String roomId,
  MathOperation op,
) async {

  if (_enabledOperations.contains(op)) {

    if (_enabledOperations.length > 1) {

      _enabledOperations =
          {..._enabledOperations}
            ..remove(op);

    }

  } else {

    _enabledOperations =
        {
          ..._enabledOperations,
          op,
        };

  }


  notifyListeners();


  await _db.saveMathConfig(
    roomId: roomId,
    operations: _enabledOperations,
    maxNumber: _mathMaxNumber,
  );

}



Future<void> setMathMaxNumber(
  String roomId,
  int value,
) async {

  _mathMaxNumber = value;

  notifyListeners();


  await _db.saveMathConfig(
    roomId: roomId,
    operations: _enabledOperations,
    maxNumber: _mathMaxNumber,
  );

}



// ── Voz (TTS) dos jogos de palavras ────────────────────────────────────


Future<void> setTtsHintEnabled(
  String roomId,
  bool value,
) async {

  _ttsHintEnabled = value;

  notifyListeners();


  await _db.saveWordGamesConfig(
    roomId: roomId,
    ttsHintEnabled: value,
  );

}
}