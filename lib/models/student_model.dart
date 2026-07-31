import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;

  /// Sala onde o aluno pertence
  final String roomId;

  /// Código público da sala
  final String roomCode;

  /// Professor dono da sala
  final String professorId;

  final String name;

  final String avatarIndex;

  final DateTime createdAt;


  const StudentModel({
    required this.id,
    required this.roomId,
    required this.roomCode,
    required this.professorId,
    required this.name,
    required this.avatarIndex,
    required this.createdAt,
  });



  // ============================================================
  // FIRESTORE
  // ============================================================

  factory StudentModel.fromFirestore(
    String id,
    Map<String, dynamic> map,
  ) {

    return StudentModel(

      id: id,


      roomId:
          map['roomId'] ??
          '',


      roomCode:
          map['roomCode'] ??
          '',


      professorId:
          map['professorId'] ??
          '',


      name:
          map['name'] ??
          '',


      avatarIndex:
          map['avatarIndex'] ??
          '0',


      createdAt:
          _parseDate(
            map['createdAt'],
          ),

    );

  }





  // Compatibilidade com código antigo
  factory StudentModel.fromMap(
    Map<String,dynamic> map,
  ){

    return StudentModel(

      id:
          map['id'] ??
          '',


      roomId:
          map['roomId'] ??
          '',


      roomCode:
          map['roomCode'] ??
          '',


      professorId:
          map['professorId'] ??
          '',


      name:
          map['name'] ??
          '',


      avatarIndex:
          map['avatarIndex'] ??
          '0',


      createdAt:
          _parseDate(
            map['createdAt'],
          ),

    );

  }






  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }




  Map<String,dynamic> toMap(){

    return {


      'roomId':
          roomId,


      'roomCode':
          roomCode,


      'professorId':
          professorId,


      'name':
          name,


      'avatarIndex':
          avatarIndex,


      'createdAt':
          createdAt.toIso8601String(),

    };

  }







  StudentModel copyWith({

    String? id,

    String? roomId,

    String? roomCode,

    String? professorId,

    String? name,

    String? avatarIndex,

    DateTime? createdAt,

  }){


    return StudentModel(

      id:
          id ??
          this.id,


      roomId:
          roomId ??
          this.roomId,


      roomCode:
          roomCode ??
          this.roomCode,


      professorId:
          professorId ??
          this.professorId,


      name:
          name ??
          this.name,


      avatarIndex:
          avatarIndex ??
          this.avatarIndex,


      createdAt:
          createdAt ??
          this.createdAt,

    );

  }


}