import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room_model.dart';
import '../models/student_model.dart';
import '../models/game_result_model.dart';
import '../models/quiz_question_model.dart';
import '../models/word_entry_model.dart';
import '../models/math_operation.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('rooms');

  CollectionReference<Map<String, dynamic>> get _roomCodes =>
      _db.collection('roomCodes');

// ============================================================
// REFERÊNCIAS DE SALAS
// ============================================================

/// Retorna a referência de uma sala pelo ID dela.
///
/// Toda a aplicação deve utilizar este método.
/// Nunca mais acessar rooms/{professorId}.
DocumentReference<Map<String, dynamic>> roomDoc(String roomId) {
  return _rooms.doc(roomId);
}

/// Mantido apenas durante a migração.
/// Será removido quando todas as telas forem convertidas.
@Deprecated('Use roomDoc(roomId)')
DocumentReference<Map<String, dynamic>> roomDocById(String roomId) {
  return roomDoc(roomId);
}

  // ============================================================
  // BUSCAR SALAS DO PROFESSOR
  // ============================================================

Query<Map<String, dynamic>> professorRooms(
  String professorId,
) {
  return _rooms
      .where(
        'professorId',
        isEqualTo: professorId,
      )
      .orderBy(
        'createdAt',
        descending: false,
      );
}

  /// Observa todas as salas do professor em tempo real.
  ///
  /// Usado pela tela:
  /// SelectRoomView
  ///
  Stream<List<RoomModel>> watchProfessorRooms(
  String professorId,
) {
  return professorRooms(
    professorId,
  ).snapshots().map(
    (snapshot) {
      return snapshot.docs
          .map(
            (doc) => RoomModel.fromMap(
              doc.id,
              doc.data(),
            ),
          )
          .toList();
    },
  );
}

// ============================================================
// BUSCAR SALA
// ============================================================

Future<RoomModel?> fetchRoom(
  String roomId,
) async {
  final doc = await roomDoc(
    roomId,
  ).get();

  if (!doc.exists) {
    return null;
  }

  return RoomModel.fromMap(
    doc.id,
    doc.data()!,
  );
}

Stream<RoomModel?> watchRoom(
  String roomId,
) {
  return roomDoc(
    roomId,
  ).snapshots().map(
    (doc) {
      if (!doc.exists) return null;

      return RoomModel.fromMap(
        doc.id,
        doc.data()!,
      );
    },
  );
}

  // ============================================================
  // GERADOR DE CÓDIGO DE SALA
  // ============================================================

  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    final random = Random();

    for (int attempt = 0; attempt < 15; attempt++) {
      final code = List.generate(
        6,
        (_) => chars[random.nextInt(chars.length)],
      ).join();

      final existing = await _roomCodes.doc(code).get();

      if (!existing.exists) {
        return code;
      }
    }

    throw Exception(
      'Não foi possível gerar código da sala.',
    );
  }

  // ============================================================
  // CRIAR NOVA SALA
  // ============================================================

Future<RoomModel> createRoom({
  required String professorId,
  required String professorName,
  required String name,
  String grade = '',
  String schoolYear = '',
  List<String> activeSubjects = const [
    'Matemática',
    'Português',
    'Ciências',
  ],
}) async {
  final roomRef = _rooms.doc();

  final code = await _generateUniqueCode();

  final room = RoomModel(
    id: roomRef.id,
    code: code,
    professorId: professorId,
    professorName: professorName,
    name: name,
    grade: grade,
    schoolYear: schoolYear.isEmpty
        ? DateTime.now().year.toString()
        : schoolYear,
    activeSubjects: activeSubjects,
    createdAt: DateTime.now(),
  );

  await _db.runTransaction((transaction) async {
    transaction.set(
      roomRef,
      room.toMap(),
    );

    transaction.set(
      _roomCodes.doc(code),
      {
        'roomId': room.id,
        'professorId': professorId,
      },
    );
  });

  return room;
}
  // ============================================================
  // SALA PRINCIPAL (COMPATIBILIDADE)
  // ============================================================

  /// Mantido para não quebrar o sistema atual.
  ///
  /// Futuramente será substituído pela seleção manual
  /// de salas.

Future<RoomModel> getOrCreateRoom({
  required String professorId,
  required String professorName,
}) async {
  final rooms = await professorRooms(
    professorId,
  ).limit(1).get();

  if (rooms.docs.isNotEmpty) {
    return RoomModel.fromMap(
      rooms.docs.first.id,
      rooms.docs.first.data(),
    );
  }

  return await createRoom(
    professorId: professorId,
    professorName: professorName,
    name: 'Minha primeira sala',
  );
}
// ============================================================
// RESOLVER SALA PELO CÓDIGO
// ============================================================

Future<Map<String, String>?> resolveRoomByCode(
  String code,
) async {
  final normalized = code.trim().toUpperCase();

  final codeDoc = await _roomCodes.doc(
    normalized,
  ).get();

  if (!codeDoc.exists) {
    return null;
  }

  final data = codeDoc.data();

  if (data == null) {
    return null;
  }

  // Antes isso era um cast direto ("as String"), que lançava exceção se
  // algum documento antigo/incompleto estivesse sem o campo. Agora trata
  // como "sala não encontrada" em vez de derrubar o app.
  final roomId = data['roomId'] as String?;

  if (roomId == null || roomId.isEmpty) {
    return null;
  }

  final professorId = data['professorId'] as String? ?? '';

  final room = await fetchRoom(
    roomId,
  );

  if (room == null) {
    return null;
  }

  return {
    'roomId': room.id,
    'professorId': professorId,
    'professorName': room.professorName,
    'code': room.code,
  };
}
// ============================================================
// ALUNOS
// ============================================================

Future<List<StudentModel>> fetchStudents({
  required String roomId,
}) async {
  final snapshot = await roomDoc(roomId)
      .collection('students')
      .get();

  return snapshot.docs
      .map(
        (doc) => StudentModel.fromFirestore(
          doc.id,
          doc.data(),
        ),
      )
      .toList();
}
Future<void> updateStudentAvatar({
  required String roomId,
  required String studentId,
  required String avatarIndex,
}) async {
  await roomDoc(roomId)
      .collection('students')
      .doc(studentId)
      .update({
    'avatarIndex': avatarIndex,
  });
}
Future<StudentModel> addStudent({
  required String roomId,
  required String professorId,
  required String roomCode,
  required String name,
  required String avatarIndex,
}) async {

  final ref = roomDoc(roomId)
      .collection('students')
      .doc();

  final student = StudentModel(
    id: ref.id,
    roomId: roomId,
    name: name,
    roomCode: roomCode,
    avatarIndex: avatarIndex,
    professorId: professorId,
    createdAt: DateTime.now(),
  );

  await ref.set(
    student.toMap(),
  );

  return student;
}
Future<void> updateStudentName({
  required String roomId,
  required String studentId,
  required String name,
}) async {

  await roomDoc(roomId)
      .collection('students')
      .doc(studentId)
      .update({
    'name': name,
  });

}
Future<void> deleteStudent({
  required String roomId,
  required String studentId,
}) async {

  final results = await roomDoc(roomId)
      .collection('results')
      .where(
        'studentId',
        isEqualTo: studentId,
      )
      .get();

  final batch = _db.batch();

  for (final doc in results.docs) {
    batch.delete(doc.reference);
  }

  batch.delete(
    roomDoc(roomId)
        .collection('students')
        .doc(studentId),
  );

  await batch.commit();

}
// ============================================================
// RESULTADOS DOS JOGOS
// ============================================================

Future<List<GameResultModel>> fetchResults({
  required String roomId,
}) async {

  final snapshot = await roomDoc(roomId)
      .collection('results')
      .orderBy(
        'playedAt',
        descending: true,
      )
      .get();


  return snapshot.docs
      .map(
        (doc) => GameResultModel.fromMap(
          doc.data(),
        ),
      )
      .toList();
}
Future<void> saveResult({
  required String roomId,
  required GameResultModel result,
}) async {

  final ref = roomDoc(roomId)
      .collection('results')
      .doc();


  final data = GameResultModel(
    id: ref.id,
    roomId: roomId,
    professorId: result.professorId,
    studentId: result.studentId,
    studentName: result.studentName,
    gameId: result.gameId,
    gameName: result.gameName,
    subject: result.subject,
    score: result.score,
    totalQuestions: result.totalQuestions,
    playedAt: result.playedAt,
    durationSeconds: result.durationSeconds,
  );


  await ref.set(
    data.toMap(),
  );

}
Future<void> deleteResultsForStudent({
  required String roomId,
  required String studentId,
}) async {


  final snapshot = await roomDoc(roomId)
      .collection('results')
      .where(
        'studentId',
        isEqualTo: studentId,
      )
      .get();


  final batch = _db.batch();


  for(final doc in snapshot.docs){

    batch.delete(
      doc.reference,
    );

  }


  await batch.commit();

}
Future<List<GameResultModel>> fetchStudentResults({
  required String roomId,
  required String studentId,
}) async {


  final snapshot = await roomDoc(roomId)
      .collection('results')
      .where(
        'studentId',
        isEqualTo: studentId,
      )
      .orderBy(
        'playedAt',
        descending: true,
      )
      .get();


  return snapshot.docs
      .map(
        (doc) => GameResultModel.fromMap(
          doc.data(),
        ),
      )
      .toList();

}
// ============================================================
// JOGOS ATIVOS / INATIVOS
// ============================================================

Future<Map<String, bool>> fetchGamesActivation({
  required String roomId,
}) async {

  final snapshot = await roomDoc(roomId)
      .collection('games')
      .get();


  return {
    for(final doc in snapshot.docs)
      doc.id:
      (doc.data()['isActive'] ?? true) as bool
  };

}
Future<void> setGameActive({
  required String roomId,
  required String gameId,
  required bool isActive,
}) async {


  await roomDoc(roomId)
      .collection('games')
      .doc(gameId)
      .set({

    'isActive': isActive,

  });

}
// ============================================================
// PERGUNTAS DO JOGO QUIZ
// ============================================================

Future<List<QuizQuestionModel>> fetchQuizQuestions({
  required String roomId,
}) async {


  final snapshot =
      await roomDoc(roomId)
          .collection('quizQuestions')
          .get();


  return snapshot.docs
      .map(
        (doc)=> QuizQuestionModel.fromMap(
          doc.data(),
        ),
      )
      .toList();

}
// ============================================================
// EXCLUIR SALA
// ============================================================

/// Apaga a sala inteira: o documento da sala, a entrada em `roomCodes`
/// (pra ninguém mais conseguir entrar com aquele código) e todas as
/// subcoleções (alunos, resultados, jogos, quiz, palavras, configurações).
Future<void> deleteRoom({
  required String roomId,
}) async {

  final roomSnap = await _rooms.doc(roomId).get();
  final code = roomSnap.data()?['code'] as String?;

  const subcollections = [
    'students',
    'results',
    'games',
    'quizQuestions',
    'settings',
    'spellingWords',
    'syllableWords',
  ];

  for (final name in subcollections) {
    final docs = await roomDoc(roomId).collection(name).get();

    var batch = _db.batch();
    var opCount = 0;

    for (final doc in docs.docs) {
      batch.delete(doc.reference);
      opCount++;

      // Limite de 500 operações por batch no Firestore; joga fora antes
      // de bater no teto pra continuar deletando com segurança.
      if (opCount >= 450) {
        await batch.commit();
        batch = _db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }
  }

  final finalBatch = _db.batch();

  finalBatch.delete(_rooms.doc(roomId));

  if (code != null && code.isNotEmpty) {
    finalBatch.delete(_roomCodes.doc(code));
  }

  await finalBatch.commit();
}

Future<bool> changeRoomCode({
  required String roomId,
  required String currentCode,
  required String newCode,
}) async {
    final normalized = newCode.trim().toUpperCase();

    if (normalized.isEmpty || normalized == currentCode) {
      return false;
    }

    return await _db.runTransaction<bool>((transaction) async {
      final newCodeDoc = await transaction.get(
        _roomCodes.doc(normalized),
      );

      // Código já usado por outra sala
      if (newCodeDoc.exists) {
        return false;
      }

      // Precisa buscar a sala para saber o professorId, já que
      // resolveRoomByCode() espera esse campo no documento de roomCodes.
      final roomSnap = await transaction.get(_rooms.doc(roomId));
      final professorId = roomSnap.data()?['professorId'] as String? ?? '';

      transaction.set(
  _roomCodes.doc(normalized),
  {
    'roomId': roomId,
    'professorId': professorId,
  },
);

      // remove código antigo
      transaction.delete(
        _roomCodes.doc(currentCode),
      );

     // atualiza a sala específica
transaction.update(
  _rooms.doc(roomId),
  {
    'code': normalized,
  },
);

return true;
    });
  }

Future<void> saveQuizQuestion({
  required String roomId,
  required QuizQuestionModel question,
}) async {


  await roomDoc(roomId)
      .collection('quizQuestions')
      .doc(question.id)
      .set(
        question.toMap(),
      );

}

Future<void> deleteQuizQuestion({
  required String roomId,
  required String id,
}) async {


  await roomDoc(roomId)
      .collection('quizQuestions')
      .doc(id)
      .delete();

}
// ============================================================
// PALAVRAS - SOLETRAR / FORCA / SILABAS
// ============================================================

Future<List<WordEntryModel>> fetchWords({

  required String roomId,

  required String collectionName,

}) async {


  final snapshot =
      await roomDoc(roomId)
          .collection(collectionName)
          .get();


  return snapshot.docs
      .map(
        (doc)=> WordEntryModel.fromMap(
          doc.data(),
        ),
      )
      .toList();

}
Future<void> saveWord({

  required String roomId,

  required String collectionName,

  required WordEntryModel word,

}) async {


  await roomDoc(roomId)
      .collection(collectionName)
      .doc(word.id)
      .set(
        word.toMap(),
      );

}

Future<void> deleteWord({

  required String roomId,

  required String collectionName,

  required String id,

}) async {


  await roomDoc(roomId)
      .collection(collectionName)
      .doc(id)
      .delete();

}

// ============================================================
// CONFIGURAÇÃO DO JOGO DE MATEMÁTICA
// ============================================================

Future<Map<String,dynamic>?> fetchMathConfig({

  required String roomId,

}) async {


  final doc =
      await roomDoc(roomId)
          .collection('settings')
          .doc('mathConfig')
          .get();


  if(!doc.exists){
    return null;
  }


  return doc.data();

}
Future<void> saveMathConfig({

  required String roomId,

  required Set<MathOperation> operations,

  required int maxNumber,

}) async {


  await roomDoc(roomId)
      .collection('settings')
      .doc('mathConfig')
      .set({

    'operations':
      operations
        .map(
          (e)=>e.name,
        )
        .toList(),

    'maxNumber':
      maxNumber,

  });

}
// ============================================================
// CONFIGURAÇÃO DE VOZ DOS JOGOS
// ============================================================

Future<Map<String,dynamic>?> fetchWordGamesConfig({

  required String roomId,

}) async {


  final doc =
      await roomDoc(roomId)
          .collection('settings')
          .doc('wordGamesConfig')
          .get();


  if(!doc.exists){
    return null;
  }


  return doc.data();

}
Future<void> saveWordGamesConfig({

  required String roomId,

  required bool ttsHintEnabled,

}) async {


  await roomDoc(roomId)
      .collection('settings')
      .doc('wordGamesConfig')
      .set({

    'ttsHintEnabled':
      ttsHintEnabled,

  });

}
}
