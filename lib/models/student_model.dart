class StudentModel {
  final String id;
  final String name;
  final String roomCode;
  final String avatarIndex;

  const StudentModel({
    required this.id,
    required this.name,
    required this.roomCode,
    required this.avatarIndex,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      roomCode: map['roomCode'] ?? '',
      avatarIndex: map['avatarIndex'] ?? '0',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'roomCode': roomCode,
        'avatarIndex': avatarIndex,
      };
}
