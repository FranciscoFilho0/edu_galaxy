import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/room_model.dart';
import '../../services/room_service.dart';
import '../../services/firestore_service.dart';
import '../../controllers/current_room_controller.dart';
import '../../core/router/app_routes.dart';
import 'package:go_router/go_router.dart';


class SelectRoomView extends StatelessWidget {

  const SelectRoomView({super.key});


  Future<void> _confirmDeleteRoom(BuildContext context, RoomModel room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir sala'),
        content: Text(
          'Tem certeza que deseja excluir "${room.name}"? '
          'Todos os alunos, resultados e configurações dessa sala serão apagados permanentemente. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await FirestoreService.instance.deleteRoom(roomId: room.id);

      if (!context.mounted) return;

      // Se a sala excluída era a que estava selecionada, limpa a seleção
      // pra não deixar o dashboard tentando carregar uma sala que não existe mais.
      final currentRoomCtrl = context.read<CurrentRoomController>();
      if (currentRoomCtrl.currentRoom?.id == room.id) {
        currentRoomCtrl.clear();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sala excluída.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir sala: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {

    final auth = context.watch<AuthController>();

    final professor = auth.currentUser;


    if (professor == null) {

      return const Scaffold(
        body: Center(
          child: Text(
            'Professor não encontrado',
          ),
        ),
      );

    }


    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Selecionar Sala',
        ),
      ),


      body: Column(

        children: [


          Padding(
            padding: const EdgeInsets.all(20),

            child: Align(

              alignment: Alignment.centerLeft,

              child: Text(
                'Olá, ${professor.name}\n\nEscolha uma sala',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ),

          ),



          Expanded(

            child: StreamBuilder<List<RoomModel>>(

              stream: RoomService()
                  .getProfessorRooms(professor.id),


              builder:(context,snapshot){


                if(snapshot.connectionState ==
                    ConnectionState.waiting){

                  return const Center(
                    child:CircularProgressIndicator(),
                  );

                }



                final rooms =
                    snapshot.data ?? [];



                if(rooms.isEmpty){

                  return const Center(

                    child: Text(
                      'Nenhuma sala cadastrada',
                    ),

                  );

                }



                return ListView.builder(

                  itemCount: rooms.length,


                  itemBuilder:(context,index){


                    final room = rooms[index];


                    return Card(

                      margin:
                      const EdgeInsets.symmetric(
                        horizontal:16,
                        vertical:8,
                      ),


                      child: ListTile(

                        leading: const Icon(
                          Icons.school,
                          size:40,
                        ),


                        title: Text(
                          room.name,
                          style: const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),


                        subtitle: Column(

                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children:[

                            Text(
                              'Código: ${room.code}',
                            ),

                            Text(
                              '${room.grade} - ${room.schoolYear}',
                            ),

                          ],

                        ),



                        trailing:
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Excluir sala',
                              onPressed: () => _confirmDeleteRoom(context, room),
                            ),
                            ElevatedButton(

                              child:
                              const Text(
                                'Entrar',
                              ),
onPressed: () {

  context
      .read<CurrentRoomController>()
      .selectRoom(room);


  context.go(
    AppRoutes.professorDashboard,
  );

},

                            ),
                          ],
                        ),

                      ),

                    );


                  },


                );


              },


            ),

          ),




          Padding(

            padding:
            const EdgeInsets.all(20),


            child:SizedBox(

              width:double.infinity,


              child:
              ElevatedButton.icon(

                icon:
                const Icon(
                  Icons.add,
                ),


                label:
                const Text(
                  'Nova Sala',
                ),


                onPressed:(){

  context.push(
    AppRoutes.createRoom,
  );

},

              ),

            ),

          ),



        ],

      ),

    );

  }

}