class GameResultModel {

  final String id;


  /// Sala onde o resultado foi gerado
  final String roomId;


  /// Professor dono da sala
  final String professorId;


  final String studentId;


  final String studentName;


  final String gameId;


  final String gameName;


  final String subject;


  final int score;


  final int totalQuestions;


  final DateTime playedAt;


  final int durationSeconds;




  const GameResultModel({

    required this.id,

    required this.roomId,

    required this.professorId,

    required this.studentId,

    required this.studentName,

    required this.gameId,

    required this.gameName,

    required this.subject,

    required this.score,

    required this.totalQuestions,

    required this.playedAt,

    required this.durationSeconds,

  });





  double get percentage {

    if(totalQuestions == 0){

      return 0;

    }

    return (score / totalQuestions) * 100;

  }





  // ============================================================
  // FIRESTORE
  // ============================================================


  factory GameResultModel.fromFirestore(

    String id,

    Map<String,dynamic> map,

  ){

    return GameResultModel(


      id: id,


      roomId:
          map['roomId'] ??
          '',



      professorId:
          map['professorId'] ??
          '',



      studentId:
          map['studentId'] ??
          '',



      studentName:
          map['studentName'] ??
          '',



      gameId:
          map['gameId'] ??
          '',



      gameName:
          map['gameName'] ??
          '',



      subject:
          map['subject'] ??
          '',



      score:
          map['score'] ??
          0,



      totalQuestions:
          map['totalQuestions'] ??
          0,



      playedAt:
          DateTime.tryParse(
            map['playedAt'] ?? '',
          )
          ??
          DateTime.now(),



      durationSeconds:
          map['durationSeconds'] ??
          0,

    );

  }





  // Compatibilidade antiga

  factory GameResultModel.fromMap(
    Map<String,dynamic> map,
  ){

    return GameResultModel.fromFirestore(

      map['id'] ?? '',

      map,

    );

  }






  Map<String,dynamic> toMap(){


    return {


      'roomId':
          roomId,


      'professorId':
          professorId,


      'studentId':
          studentId,


      'studentName':
          studentName,


      'gameId':
          gameId,


      'gameName':
          gameName,


      'subject':
          subject,


      'score':
          score,


      'totalQuestions':
          totalQuestions,


      'playedAt':
          playedAt.toIso8601String(),


      'durationSeconds':
          durationSeconds,


    };

  }





  GameResultModel copyWith({

    String? id,

    String? roomId,

    String? professorId,

    String? studentId,

    String? studentName,

    String? gameId,

    String? gameName,

    String? subject,

    int? score,

    int? totalQuestions,

    DateTime? playedAt,

    int? durationSeconds,

  }){


    return GameResultModel(


      id:
          id ??
          this.id,


      roomId:
          roomId ??
          this.roomId,


      professorId:
          professorId ??
          this.professorId,


      studentId:
          studentId ??
          this.studentId,


      studentName:
          studentName ??
          this.studentName,


      gameId:
          gameId ??
          this.gameId,


      gameName:
          gameName ??
          this.gameName,


      subject:
          subject ??
          this.subject,


      score:
          score ??
          this.score,


      totalQuestions:
          totalQuestions ??
          this.totalQuestions,


      playedAt:
          playedAt ??
          this.playedAt,


      durationSeconds:
          durationSeconds ??
          this.durationSeconds,


    );

  }

}