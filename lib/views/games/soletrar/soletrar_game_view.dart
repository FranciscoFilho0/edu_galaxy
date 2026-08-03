import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/game_content_controller.dart';
import '../../../controllers/student_controller.dart';
import '../../../controllers/auth_controller.dart';

import '../../../models/word_entry_model.dart';
import '../../../models/game_result_model.dart';

import '../../../core/theme/app_theme.dart';

import '../shared/game_top_bar.dart';
import '../shared/game_result_screen.dart';
import '../shared/speak_button.dart';

import '../../../services/tts_service.dart';
import '../../../services/audio_service.dart';


class SoletrarGameView extends StatefulWidget {
  const SoletrarGameView({super.key});

  @override
  State<SoletrarGameView> createState() => _SoletrarGameViewState();
}


class _SoletrarGameViewState extends State<SoletrarGameView> {

  List<WordEntryModel> _words = [];

  int _currentIndex = 0;
  int _score = 0;

  bool _isFinished = false;

  DateTime _startTime = DateTime.now();


  List<String> _letterBank = [];

  List<String?> _slots = [];


  bool _answered = false;

  bool _isCorrect = false;



  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWords();
    });
  }



  @override
  void dispose() {

    TtsService.instance.stop();

    super.dispose();
  }




  void _loadWords(){

    final content = context.read<GameContentController>();

    final list = [...content.spellingWords]
      ..shuffle();


    setState(() {

      _words = list.take(8).toList();

      _currentIndex = 0;

      if(_words.isNotEmpty){
        _setupRound();
      }

    });

  }





  void _setupRound(){

    if(_words.isEmpty) return;


    final word = _words[_currentIndex]
        .word
        .toUpperCase();


    final letters = word.split('');


    _letterBank = [...letters]
      ..shuffle(Random());


    if(_letterBank.join() == word && letters.length > 1){

      _letterBank.shuffle(Random());

    }


    setState((){

      _slots = List.filled(
        letters.length,
        null,
      );


      _answered = false;

      _isCorrect = false;

    });

  }






  void _tapLetter(int index){

    if(_answered) return;


    final empty =
        _slots.indexWhere(
          (element)=> element == null,
        );


    if(empty == -1) return;


    setState((){

      _slots[empty] = _letterBank[index];

      _letterBank.removeAt(index);

    });



    if(!_slots.contains(null)){

      _checkAnswer();

    }

  }







  void _tapSlot(int index){

    if(_answered) return;


    final letter = _slots[index];


    if(letter == null) return;



    setState((){


      _letterBank.add(letter);


      _slots[index] = null;


    });

  }







  void _checkAnswer(){


    final attempt = _slots.join();


    final correct =
        attempt ==
        _words[_currentIndex]
            .word
            .toUpperCase();



    if(correct){

      AudioService().playSuccess();

    }else{

      AudioService().playError();

    }



    setState((){

      _answered = true;

      _isCorrect = correct;


      if(correct){

        _score++;

      }

    });



    Future.delayed(
      const Duration(milliseconds:1200),
      (){

        if(!mounted)return;



        if(_currentIndex < _words.length-1){


          setState((){

            _currentIndex++;

          });


          _setupRound();


        }else{


          setState((){

            _isFinished = true;

          });


          _saveResult();


        }


      },
    );


  }






  Set<String> _unlockedBeforeIds = {};



  void _saveResult(){


    final auth =
        context.read<AuthController>();


    final student =
        auth.currentStudent;


    if(student == null)return;



    final controller =
        context.read<StudentController>();



    _unlockedBeforeIds =
        controller.achievements
            .where((a)=>a.unlocked)
            .map((a)=>a.achievement.id)
            .toSet();




    controller.saveResult(

      roomId: student.roomId,


      result: GameResultModel(

        id:'',

        roomId: student.roomId,

        professorId: student.professorId,

        studentId: student.id,

        studentName: student.name,


        gameId:'soletrar',

        gameName:'Soletrar Espacial',

        subject:'Português',


        score:_score,

        totalQuestions:_words.length,


        playedAt:DateTime.now(),


        durationSeconds:
          DateTime.now()
          .difference(_startTime)
          .inSeconds,

      ),

    );


  }






  void _restart(){

    setState((){

      _currentIndex=0;

      _score=0;

      _isFinished=false;

      _startTime=DateTime.now();

    });


    _loadWords();

  }






  @override
  Widget build(BuildContext context){


    final content =
        context.watch<GameContentController>();


    if(content.isLoading || _words.isEmpty){

      return const Scaffold(

        backgroundColor:AppTheme.galaxyDeep,

        body:
        Center(
          child:CircularProgressIndicator(
            color:AppTheme.galaxyViolet,
          ),
        ),

      );

    }




    if(_isFinished){


      return GameResultScreen(

        gameEmoji:'🔤',

        gameTitle:'Soletrar Espacial',

        score:_score,

        total:_words.length,


        durationSeconds:
          DateTime.now()
          .difference(_startTime)
          .inSeconds,


        onPlayAgain:_restart,


        previouslyUnlockedIds:
          _unlockedBeforeIds,

      );

    }



    final word =
        _words[_currentIndex];




    return Scaffold(

      backgroundColor:
        AppTheme.galaxyDeep,


      body:SafeArea(

        child:Column(

          children:[


            GameTopBar(

              title:'🔤 Soletrar Espacial',

              current:_currentIndex,

              total:_words.length,

              score:_score,

            ),



            const SizedBox(height:15),




            Container(

              margin:
              const EdgeInsets.symmetric(horizontal:20),


              padding:
              const EdgeInsets.all(16),


              decoration:BoxDecoration(

                color:AppTheme.galaxyMid,

                borderRadius:
                BorderRadius.circular(16),

              ),


              child:Row(

                children:[


                  const Text(
                    '💡',
                    style:TextStyle(fontSize:24),
                  ),


                  const SizedBox(width:10),


                  Expanded(

                    child:Text(

                      word.hint,

                      style:
                      const TextStyle(
                        color:Colors.white,
                      ),

                    ),

                  ),


                  if(content.ttsHintEnabled)

                    SpeakButton(
                      textToSpeak:word.hint,
                    )

                ],

              ),

            ),




            const Spacer(),




            Wrap(

              spacing:8,

              children:

              List.generate(

                _slots.length,

                (i){


                  return GestureDetector(

                    onTap:()=>_tapSlot(i),


                    child:Container(

                      width:40,

                      height:45,


                      decoration:BoxDecoration(

                        border:Border.all(

                          color:
                          _answered

                          ? (_isCorrect
                              ? AppTheme.galaxyGreen
                              : AppTheme.galaxyPink)

                          : AppTheme.galaxyPurple,

                          width:2,

                        ),

                      ),


                      child:Center(

                        child:Text(

                          _slots[i] ?? '',

                          style:
                          const TextStyle(

                            color:Colors.white,

                            fontSize:20,

                            fontWeight:
                            FontWeight.bold,

                          ),

                        ),

                      ),

                    ),

                  );

                },

              ),

            ),




            const Spacer(),




            Wrap(

              spacing:10,

              children:

              List.generate(

                _letterBank.length,

                (i){

                  return GestureDetector(

                    onTap:()=>_tapLetter(i),


                    child:Container(

                      padding:
                      const EdgeInsets.all(14),


                      decoration:
                      BoxDecoration(

                        gradient:
                        const LinearGradient(

                          colors:[

                            AppTheme.galaxyPurple,

                            AppTheme.galaxyCyan

                          ],

                        ),

                        borderRadius:
                        BorderRadius.circular(10),

                      ),


                      child:Text(

                        _letterBank[i],

                        style:
                        const TextStyle(

                          color:Colors.white,

                          fontSize:20,

                          fontWeight:
                          FontWeight.bold,

                        ),

                      ),

                    ),

                  );

                },

              ),

            ),



            const SizedBox(height:30),


          ],

        ),

      ),

    );


  }

}