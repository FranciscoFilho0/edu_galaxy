import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../models/student_model.dart';
import '../models/game_result_model.dart';
import '../models/quiz_question_model.dart';
import '../models/word_entry_model.dart';
import '../models/math_operation.dart';

/// FirestoreService centraliza TODO o acesso ao banco de dados (Firestore).
///
/// Estrutura de dados usada:
///
/// roomCodes/{CODIGO}                -> { professorId }
///   -> índice usado só para: (1) garantir que um código nunca se repita
///      e (2) o aluno encontrar a sala pelo código digitado.
///
/// rooms/{professorId}               -> { code, professorName, activeSubjects, createdAt }
///   -> UMA sala por professor. O ID do documento é o UID do professor
///      (vem do Firebase Auth), então nunca existe ambiguidade sobre
///      "de quem" é a sala.
///
/// rooms/{professorId}/students/{studentId}    -> alunos daquele professor
/// rooms/{professorId}/results/{resultId}      -> resultados dos jogos daquele professor
/// rooms/{professorId}/games/{gameId}          -> { isActive } por jogo
/// rooms/{professorId}/quizQuestions/{id}      -> perguntas do jogo "Perguntas Espaciais"
/// rooms/{professorId}/spellingWords/{id}      -> palavras do "Soletrar" / "Forca"
/// rooms/{professorId}/syllableWords/{id}      -> palavras do "Quebra-Sílabas"
/// rooms/{professorId}/settings/mathConfig     -> configuração do jogo de Cálculos
///
/// Como cada professor só lê/escreve dentro de rooms/{seuProprioId}/...,
/// e o aluno só acessa a sala do professor que ele encontrou pelo código,
/// os dados de professores diferentes nunca se misturam.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _roomCodes => _db.collection('roomCodes');
  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('rooms');

  DocumentReference<Map<String, dynamic>> _roomDoc(String professorId) => _rooms.doc(professorId);

  // ── Sala do professor ────────────────────────────────────────────────────

  /// Gera um código de 6 caracteres (letras+números) que ainda não existe
  /// em `roomCodes`. Tenta algumas vezes até achar um livre.
  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sem O/0/I/1 para não confundir alunos
    final rng = Random();
    for (int attempt = 0; attempt < 15; attempt++) {
      final code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
      final doc = await _roomCodes.doc(code).get();
      if (!doc.exists) return code;
    }
    throw Exception('Não foi possível gerar um código de sala único. Tente novamente.');
  }

  /// Busca a sala do professor. Se ele estiver logando pela primeira vez
  /// (documento ainda não existe), cria a sala com um código novo.
  /// Sempre retorna a MESMA sala para o MESMO professor (professorId = UID do Auth).
  Future<RoomModel> getOrCreateRoom({
    required String professorId,
    required String professorName,
  }) async {
    final existing = await _roomDoc(professorId).get();
    if (existing.exists) {
      return RoomModel.fromMap(professorId, existing.data()!);
    }

    final code = await _generateUniqueCode();
    final room = RoomModel(
      code: code,
      professorId: professorId,
      professorName: professorName,
      activeSubjects: const ['Matemática', 'Português', 'Ciências'],
      createdAt: DateTime.now(),
    );

    // Usamos uma transação para garantir que o código e a sala sejam
    // criados juntos, sem risco de dois professores ficarem com o mesmo código.
    await _db.runTransaction((tx) async {
      tx.set(_roomDoc(professorId), room.toMap());
      tx.set(_roomCodes.doc(code), {'professorId': professorId});
    });

    return room;
  }

  /// Permite o professor trocar o código da própria sala, desde que o novo
  /// código não esteja em uso por outro professor.
  Future<bool> changeRoomCode({
    required String professorId,
    required String currentCode,
    required String newCode,
  }) async {
    final normalized = newCode.trim().toUpperCase();
    if (normalized.isEmpty || normalized == currentCode) return false;

    return _db.runTransaction<bool>((tx) async {
      final newCodeDoc = await tx.get(_roomCodes.doc(normalized));
      if (newCodeDoc.exists) {
        // já existe outro professor usando esse código
        return false;
      }
      tx.set(_roomCodes.doc(normalized), {'professorId': professorId});
      tx.delete(_roomCodes.doc(currentCode));
      tx.update(_roomDoc(professorId), {'code': normalized});
      return true;
    });
  }

  /// Usado pelo aluno: recebe o código digitado e descobre a qual professor
  /// ele pertence. Retorna null se o código não existir.
  Future<Map<String, String>?> resolveRoomByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final codeDoc = await _roomCodes.doc(normalized).get();
    if (!codeDoc.exists) return null;

    final professorId = codeDoc.data()!['professorId'] as String;
    final roomDoc = await _roomDoc(professorId).get();
    if (!roomDoc.exists) return null;

    return {
      'professorId': professorId,
      'professorName': roomDoc.data()!['professorName'] ?? '',
      'code': normalized,
    };
  }

  // ── Alunos ───────────────────────────────────────────────────────────────

  Future<List<StudentModel>> fetchStudents(String professorId) async {
    final snap = await _roomDoc(professorId).collection('students').get();
    return snap.docs.map((d) => StudentModel.fromMap(d.data())).toList();
  }

  /// Atualiza só o avatar de um aluno que JÁ existe (usado quando o aluno,
  /// pré-cadastrado pelo professor, escolhe seu avatar ao entrar na turma).
  /// Não cria nenhum documento novo.
  Future<void> updateStudentAvatar({
    required String professorId,
    required String studentId,
    required String avatarIndex,
  }) async {
    await _roomDoc(professorId)
        .collection('students')
        .doc(studentId)
        .update({'avatarIndex': avatarIndex});
  }

  Future<StudentModel> addStudent({
    required String professorId,
    required String roomCode,
    required String name,
    required String avatarIndex,
  }) async {
    final ref = _roomDoc(professorId).collection('students').doc();
    final student = StudentModel(
      id: ref.id,
      name: name,
      roomCode: roomCode,
      avatarIndex: avatarIndex,
      professorId: professorId,
    );
    await ref.set(student.toMap());
    return student;
  }

  /// Atualiza o nome de um aluno já cadastrado.
  Future<void> updateStudentName({
    required String professorId,
    required String studentId,
    required String name,
  }) async {
    await _roomDoc(professorId)
        .collection('students')
        .doc(studentId)
        .update({'name': name});
  }

  /// Exclui o aluno e também todos os resultados de jogos que ele já tinha
  /// registrado, para não deixar "lixo" órfão no banco (resultado apontando
  /// para um aluno que não existe mais).
  Future<void> deleteStudent({
    required String professorId,
    required String studentId,
  }) async {
    final resultsSnap = await _roomDoc(professorId)
        .collection('results')
        .where('studentId', isEqualTo: studentId)
        .get();

    // Batch: agrupa várias operações de escrita para executar de uma vez só,
    // em vez de fazer uma chamada ao banco por resultado.
    final batch = _db.batch();
    for (final doc in resultsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_roomDoc(professorId).collection('students').doc(studentId));
    await batch.commit();
  }

  // ── Resultados de jogos ─────────────────────────────────────────────────

  Future<List<GameResultModel>> fetchResults(String professorId) async {
    final snap = await _roomDoc(professorId)
        .collection('results')
        .orderBy('playedAt', descending: true)
        .get();
    return snap.docs.map((d) => GameResultModel.fromMap(d.data())).toList();
  }

  Future<void> saveResult({
    required String professorId,
    required GameResultModel result,
  }) async {
    final ref = _roomDoc(professorId).collection('results').doc();
    final withId = GameResultModel(
      id: ref.id,
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
    await ref.set(withId.toMap());
  }

  // ── Jogos ativos/inativos ───────────────────────────────────────────────

  /// Retorna um mapa {gameId: isActive}. Jogos que nunca foram configurados
  /// pelo professor não aparecem no mapa (a tela trata a ausência como "ativo").
  Future<Map<String, bool>> fetchGamesActivation(String professorId) async {
    final snap = await _roomDoc(professorId).collection('games').get();
    return {for (final d in snap.docs) d.id: (d.data()['isActive'] ?? true) as bool};
  }

  Future<void> setGameActive(String professorId, String gameId, bool isActive) async {
    await _roomDoc(professorId).collection('games').doc(gameId).set({'isActive': isActive});
  }

  // ── Conteúdo: Perguntas e Respostas ─────────────────────────────────────

  Future<List<QuizQuestionModel>> fetchQuizQuestions(String professorId) async {
    final snap = await _roomDoc(professorId).collection('quizQuestions').get();
    return snap.docs.map((d) => QuizQuestionModel.fromMap(d.data())).toList();
  }

  Future<void> saveQuizQuestion(String professorId, QuizQuestionModel q) async {
    await _roomDoc(professorId).collection('quizQuestions').doc(q.id).set(q.toMap());
  }

  Future<void> deleteQuizQuestion(String professorId, String id) async {
    await _roomDoc(professorId).collection('quizQuestions').doc(id).delete();
  }

  // ── Conteúdo: Soletrar / Forca / Sílabas (mesmo formato, coleções diferentes) ──

  Future<List<WordEntryModel>> fetchWords(String professorId, String collectionName) async {
    final snap = await _roomDoc(professorId).collection(collectionName).get();
    return snap.docs.map((d) => WordEntryModel.fromMap(d.data())).toList();
  }

  Future<void> saveWord(String professorId, String collectionName, WordEntryModel w) async {
    await _roomDoc(professorId).collection(collectionName).doc(w.id).set(w.toMap());
  }

  Future<void> deleteWord(String professorId, String collectionName, String id) async {
    await _roomDoc(professorId).collection(collectionName).doc(id).delete();
  }

  // ── Conteúdo: Configuração do jogo de Cálculos ──────────────────────────

  Future<Map<String, dynamic>?> fetchMathConfig(String professorId) async {
    final doc = await _roomDoc(professorId).collection('settings').doc('mathConfig').get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> saveMathConfig({
    required String professorId,
    required Set<MathOperation> operations,
    required int maxNumber,
  }) async {
    await _roomDoc(professorId).collection('settings').doc('mathConfig').set({
      'operations': operations.map((o) => o.name).toList(),
      'maxNumber': maxNumber,
    });
  }
}
