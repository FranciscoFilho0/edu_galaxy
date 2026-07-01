import 'student_model.dart';

class RoomModel {
  final String code;
  final String professorId;
  final String professorName;
  final List<StudentModel> students;
  final List<String> activeSubjects;
  final DateTime createdAt;

  const RoomModel({
    required this.code,
    required this.professorId,
    required this.professorName,
    required this.students,
    required this.activeSubjects,
    required this.createdAt,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      code: map['code'] ?? '',
      professorId: map['professorId'] ?? '',
      professorName: map['professorName'] ?? '',
      students: (map['students'] as List<dynamic>? ?? [])
          .map((s) => StudentModel.fromMap(s as Map<String, dynamic>))
          .toList(),
      activeSubjects: List<String>.from(map['activeSubjects'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
