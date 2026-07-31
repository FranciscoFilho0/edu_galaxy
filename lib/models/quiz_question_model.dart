class QuizQuestionModel {

  final String id;


  /// Sala onde essa pergunta pertence
  final String roomId;


  /// Professor dono da sala
  final String professorId;


  final String question;


  final List<String> options;


  final int correctIndex;


  final String subject;




  const QuizQuestionModel({

    required this.id,

    required this.roomId,

    required this.professorId,

    required this.question,

    required this.options,

    required this.correctIndex,

    required this.subject,

  });





  String get correctAnswer {

    if(correctIndex < 0 ||
       correctIndex >= options.length){

      return '';

    }

    return options[correctIndex];

  }





  // ============================================================
  // FIRESTORE
  // ============================================================


  factory QuizQuestionModel.fromFirestore(

    String id,

    Map<String,dynamic> map,

  ){

    return QuizQuestionModel(


      id: id,


      roomId:
          map['roomId'] ??
          '',



      professorId:
          map['professorId'] ??
          '',



      question:
          map['question'] ??
          '',



      options:
          map['options'] != null
              ? List<String>.from(
                  map['options'],
                )
              : [],



      correctIndex:
          map['correctIndex'] ??
          0,



      subject:
          map['subject'] ??
          '',

    );

  }





  // Compatibilidade com dados antigos

  factory QuizQuestionModel.fromMap(

    Map<String,dynamic> map,

  ){

    return QuizQuestionModel.fromFirestore(

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


      'question':
          question,


      'options':
          options,


      'correctIndex':
          correctIndex,


      'subject':
          subject,


    };

  }







  QuizQuestionModel copyWith({

    String? id,

    String? roomId,

    String? professorId,

    String? question,

    List<String>? options,

    int? correctIndex,

    String? subject,

  }){


    return QuizQuestionModel(


      id:
          id ??
          this.id,


      roomId:
          roomId ??
          this.roomId,


      professorId:
          professorId ??
          this.professorId,


      question:
          question ??
          this.question,


      options:
          options ??
          this.options,


      correctIndex:
          correctIndex ??
          this.correctIndex,


      subject:
          subject ??
          this.subject,

    );

  }

}