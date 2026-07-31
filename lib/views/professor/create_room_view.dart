import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../services/firestore_service.dart';
import '../../core/router/app_routes.dart';


class CreateRoomView extends StatefulWidget {

  const CreateRoomView({super.key});


  @override
  State<CreateRoomView> createState() =>
      _CreateRoomViewState();

}



class _CreateRoomViewState extends State<CreateRoomView> {


  final _formKey = GlobalKey<FormState>();


  final _nameController =
      TextEditingController();


  final _gradeController =
      TextEditingController();


  final _yearController =
      TextEditingController();



  bool _loading = false;



  final List<String> _subjects = [

    'Matemática',

    'Português',

    'Ciências',

  ];



  final Set<String> _selectedSubjects = {

    'Matemática',

    'Português',

    'Ciências',

  };




  Future<void> _createRoom() async {


    if (!_formKey.currentState!.validate()) {
      return;
    }


    final auth =
        context.read<AuthController>();


    final professor =
        auth.currentUser;



    if (professor == null) {

      return;

    }



    setState(() {

      _loading = true;

    });



    try {


      await FirestoreService.instance.createRoom(

        professorId: professor.id,

        professorName: professor.name,


        name:
            _nameController.text.trim(),


        grade:
            _gradeController.text.trim(),


        schoolYear:
            _yearController.text.trim(),


      );



      if (!mounted) return;



      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content:
              Text(
                'Sala criada com sucesso!',
              ),

        ),

      );



      context.go(
        AppRoutes.selectRoom,
      );



    } catch(e){


      debugPrint(
        'Erro criando sala: $e',
      );


      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content:
              Text(
                'Erro: $e',
              ),
        ),

      );


    }



    setState(() {

      _loading = false;

    });


  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title:
            const Text(
              'Nova Sala',
            ),

      ),



      body:
      SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),


        child:
        Form(

          key:_formKey,


          child:
          Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,


            children:[



              TextFormField(

                controller:
                    _nameController,


                decoration:
                const InputDecoration(

                  labelText:
                      'Nome da Sala',

                  hintText:
                      'Ex: 5º Ano A',

                  border:
                      OutlineInputBorder(),

                ),


                validator:(v){

                  if(v == null ||
                      v.trim().isEmpty){

                    return
                    'Digite o nome da sala';

                  }

                  return null;

                },

              ),



              const SizedBox(height:20),




              TextFormField(

                controller:
                    _gradeController,


                decoration:
                const InputDecoration(

                  labelText:
                      'Série/Turma',

                  hintText:
                      'Ex: Ensino Fundamental 1',

                  border:
                      OutlineInputBorder(),

                ),

              ),




              const SizedBox(height:20),





              TextFormField(

                controller:
                    _yearController,


                keyboardType:
                    TextInputType.number,


                decoration:
                const InputDecoration(

                  labelText:
                      'Ano Letivo',

                  hintText:
                      '2026',

                  border:
                      OutlineInputBorder(),

                ),


              ),




              const SizedBox(height:25),



              const Text(

                'Matérias ativas',

                style:
                TextStyle(

                  fontSize:18,

                  fontWeight:
                      FontWeight.bold,

                ),

              ),




              ..._subjects.map((subject){


                return CheckboxListTile(

                  title:
                      Text(subject),


                  value:
                      _selectedSubjects
                          .contains(subject),


                  onChanged:(value){


                    setState((){


                      if(value == true){

                        _selectedSubjects
                            .add(subject);

                      }else{

                        _selectedSubjects
                            .remove(subject);

                      }


                    });


                  },

                );


              }),




              const SizedBox(height:30),





              SizedBox(

                width:
                    double.infinity,


                child:
                ElevatedButton.icon(

                  icon:
                  _loading

                  ? const SizedBox(

                    width:20,

                    height:20,

                    child:
                    CircularProgressIndicator(
                      strokeWidth:2,
                    ),

                  )

                  :
                  const Icon(
                    Icons.add,
                  ),



                  label:
                  Text(

                    _loading
                    ? 'Criando...'
                    :
                    'Criar Sala',

                  ),




                  onPressed:
                  _loading
                  ? null
                  :
                  _createRoom,


                ),

              )



            ],

          ),

        ),

      ),

    );

  }


}