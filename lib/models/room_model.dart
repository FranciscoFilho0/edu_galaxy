class RoomModel {
  final String code;
  final String professorId;
  final String professorName;
  final List<String> activeSubjects;
  final DateTime createdAt;

  const RoomModel({
    required this.code,
    required this.professorId,
    required this.professorName,
    required this.activeSubjects,
    required this.createdAt,
  });

  factory RoomModel.fromMap(String professorId, Map<String, dynamic> map) {
    return RoomModel(
      code: map['code'] ?? '',
      professorId: professorId,
      professorName: map['professorName'] ?? '',
      activeSubjects: List<String>.from(map['activeSubjects'] ?? const ['Matemática', 'Português', 'Ciências']),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'professorName': professorName,
        'activeSubjects': activeSubjects,
        'createdAt': createdAt.toIso8601String(),
      };

  RoomModel copyWith({String? code}) {
    return RoomModel(
      code: code ?? this.code,
      professorId: professorId,
      professorName: professorName,
      activeSubjects: activeSubjects,
      createdAt: createdAt,
    );
  }
}
