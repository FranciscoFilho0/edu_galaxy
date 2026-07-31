class WordEntryModel {

  final String id;


  /// Sala onde essa palavra pertence
  final String roomId;


  /// Professor dono da sala
  final String professorId;


  final String word;


  final String hint;


  final String subject;




  const WordEntryModel({

    required this.id,

    required this.roomId,

    required this.professorId,

    required this.word,

    required this.hint,

    required this.subject,

  });





  List<String> get syllables =>
      _splitSyllables(word);





  // ============================================================
  // DIVISOR DE SÍLABAS
  // ============================================================


  static List<String> _splitSyllables(
    String word,
  ) {

    final w =
        word.toLowerCase();


    const vowels =
        'aeiouáéíóúâêîôûãõ';


    final List<String> result = [];


    String current = '';



    for(
      int i = 0;
      i < w.length;
      i++
    ){

      current += w[i];


      final isVowel =
          vowels.contains(w[i]);



      final nextIsConsonant =
          i + 1 < w.length &&
          !vowels.contains(
            w[i + 1],
          );



      final nextNextIsVowel =
          i + 2 < w.length &&
          vowels.contains(
            w[i + 2],
          );



      if(
        isVowel &&
        nextIsConsonant &&
        nextNextIsVowel
      ){

        result.add(current);

        current = '';

      }

    }



    if(current.isNotEmpty){

      result.add(current);

    }



    return result.isEmpty
        ? [word]
        : result;

  }






  // ============================================================
  // FIRESTORE
  // ============================================================


  factory WordEntryModel.fromFirestore(

    String id,

    Map<String,dynamic> map,

  ){

    return WordEntryModel(


      id: id,


      roomId:
          map['roomId'] ??
          '',



      professorId:
          map['professorId'] ??
          '',



      word:
          map['word'] ??
          '',



      hint:
          map['hint'] ??
          '',



      subject:
          map['subject'] ??
          '',

    );

  }






  // Compatibilidade antiga

  factory WordEntryModel.fromMap(

    Map<String,dynamic> map,

  ){

    return WordEntryModel.fromFirestore(

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


      'word':
          word,


      'hint':
          hint,


      'subject':
          subject,


    };

  }








  WordEntryModel copyWith({

    String? id,

    String? roomId,

    String? professorId,

    String? word,

    String? hint,

    String? subject,

  }){


    return WordEntryModel(


      id:
          id ??
          this.id,


      roomId:
          roomId ??
          this.roomId,


      professorId:
          professorId ??
          this.professorId,


      word:
          word ??
          this.word,


      hint:
          hint ??
          this.hint,


      subject:
          subject ??
          this.subject,

    );

  }

}