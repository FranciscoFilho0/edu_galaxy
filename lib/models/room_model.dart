import 'package:cloud_firestore/cloud_firestore.dart';


class RoomModel {

  final String id;

  final String code;

  final String professorId;

  final String professorName;


  /// Nome da sala
  final String name;


  /// Série/Turma
  final String grade;


  /// Ano letivo
  final String schoolYear;


  final List<String> activeSubjects;


  final DateTime createdAt;



  const RoomModel({

    required this.id,

    required this.code,

    required this.professorId,

    required this.professorName,

    required this.name,

    required this.grade,

    required this.schoolYear,

    required this.activeSubjects,

    required this.createdAt,

  });



  // ============================================================
  // FIRESTORE
  // ============================================================


  factory RoomModel.fromFirestore(
    DocumentSnapshot<Map<String,dynamic>> doc,
  ){

    return RoomModel.fromMap(
      doc.id,
      doc.data() ?? {},
    );

  }




  factory RoomModel.fromMap(
    String id,
    Map<String,dynamic> map,
  ){

    return RoomModel(

      id: id,


      code:
          map['code'] ?? '',


      professorId:
          map['professorId'] ?? '',


      professorName:
          map['professorName'] ?? '',



      name:
          map['name'] ?? 'Sala sem nome',



      grade:
          map['grade'] ?? '',



      schoolYear:
          map['schoolYear'] ??
          DateTime.now().year.toString(),




      activeSubjects:

          map['activeSubjects'] != null

          ?

          List<String>.from(
            map['activeSubjects'],
          )

          :

          const [

            'Matemática',

            'Português',

            'Ciências',

          ],




      createdAt:
          _parseDate(
            map['createdAt'],
          ),


    );


  }




  static DateTime _parseDate(dynamic value){

    if(value == null){

      return DateTime.now();

    }


    if(value is Timestamp){

      return value.toDate();

    }


    if(value is String){

      return DateTime.tryParse(value)
          ??
          DateTime.now();

    }


    return DateTime.now();

  }







  Map<String,dynamic> toMap(){

    return {


      'code':
          code,


      'professorId':
          professorId,


      'professorName':
          professorName,


      'name':
          name,


      'grade':
          grade,


      'schoolYear':
          schoolYear,


      'activeSubjects':
          activeSubjects,



      'createdAt':
          Timestamp.fromDate(
            createdAt,
          ),


    };

  }







  RoomModel copyWith({

    String? id,

    String? code,

    String? professorId,

    String? professorName,

    String? name,

    String? grade,

    String? schoolYear,

    List<String>? activeSubjects,

    DateTime? createdAt,

  }){


    return RoomModel(

      id:
          id ?? this.id,


      code:
          code ?? this.code,


      professorId:
          professorId ?? this.professorId,


      professorName:
          professorName ?? this.professorName,


      name:
          name ?? this.name,


      grade:
          grade ?? this.grade,


      schoolYear:
          schoolYear ?? this.schoolYear,


      activeSubjects:
          activeSubjects ?? this.activeSubjects,


      createdAt:
          createdAt ?? this.createdAt,

    );


  }





  @override
  String toString(){

    return '''

RoomModel(
 id: $id,
 code: $code,
 professorId: $professorId,
 name: $name
)

''';

  }


}