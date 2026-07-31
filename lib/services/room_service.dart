import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =====================================================
  // Buscar todas as salas do professor
  // =====================================================

  Stream<List<RoomModel>> getProfessorRooms(String professorId) {
    return _firestore.collection('rooms').snapshots().map((snapshot) {
      final rooms = snapshot.docs.where((doc) {
        final data = doc.data();

        return data['professorId'] == professorId || doc.id == professorId;
      }).map((doc) {
        final data = doc.data();

        // compatibilidade com salas antigas
        if (!data.containsKey('id')) {
          data['name'] ??= 'Minha Turma';
          data['grade'] ??= '';
          data['schoolYear'] ??= DateTime.now().year.toString();
        }

        return RoomModel.fromMap(doc.id, data);
      }).toList();

      return rooms;
    });
  }

  // =====================================================
  // Criar nova sala
  // =====================================================

  Future<String> createRoom({
    required String professorId,
    required String professorName,
    required String name,
    String grade = '',
    String schoolYear = '',
    List<String> subjects = const [
      'Matemática',
      'Português',
      'Ciências',
    ],
  }) async {
    final roomRef = _firestore.collection('rooms').doc(professorId);

    final code = DateTime.now().millisecondsSinceEpoch.toString().substring(7);

    final room = RoomModel(
      id: professorId,
      code: code,
      professorId: professorId,
      professorName: professorName,
      name: name,
      grade: grade,
      schoolYear:
          schoolYear.isEmpty ? DateTime.now().year.toString() : schoolYear,
      activeSubjects: subjects,
      createdAt: DateTime.now(),
    );

    await roomRef.set(
      room.toMap(),
    );

    return roomRef.id;
  }
}
