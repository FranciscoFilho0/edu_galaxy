class StudentModel {
  final String id;
  final String name;
  final String roomCode;
  final String avatarIndex;
  // ID do professor dono da sala. É esse campo que garante que os dados
  // de um aluno fiquem sempre vinculados ao professor certo no banco.
  final String professorId;

  const StudentModel({
    required this.id,
    required this.name,
    required this.roomCode,
    required this.avatarIndex,
    required this.professorId,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      roomCode: map['roomCode'] ?? '',
      avatarIndex: map['avatarIndex'] ?? '0',
      professorId: map['professorId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'roomCode': roomCode,
        'avatarIndex': avatarIndex,
        'professorId': professorId,
      };

  StudentModel copyWith({
    String? id,
    String? name,
    String? roomCode,
    String? avatarIndex,
    String? professorId,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      roomCode: roomCode ?? this.roomCode,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      professorId: professorId ?? this.professorId,
    );
  }
}
