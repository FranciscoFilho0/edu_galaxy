import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/room_model.dart';
import '../../services/room_service.dart';
import '../../services/firestore_service.dart';
import '../../controllers/current_room_controller.dart';
import '../../controllers/professor_controller.dart';
import '../../controllers/game_content_controller.dart';
import '../../core/router/app_routes.dart';
import 'package:go_router/go_router.dart';

class SelectRoomView extends StatefulWidget {
  const SelectRoomView({super.key});

  @override
  State<SelectRoomView> createState() => _SelectRoomViewState();
}

class _SelectRoomViewState extends State<SelectRoomView> {
  // Guardamos o Stream numa variável de estado, criado uma única vez em
  // [initState]. Antes ele era criado direto dentro de build() a cada
  // rebuild (ex.: assim que `selectProfessorRoom` chamava notifyListeners
  // no meio do onPressed) — isso fazia o StreamBuilder trocar de stream,
  // voltar para o estado de "carregando" e desmontar o Card/botão que
  // tinha acabado de ser tocado, cancelando o fluxo de entrada na sala
  // no meio do caminho (o `context.mounted` do onPressed passava a ser
  // false e o método retornava sem navegar). Mantendo o mesmo Stream
  // entre rebuilds, a lista de salas não é mais recriada à toa e o botão
  // "Entrar" permanece montado até terminar de carregar os dados e navegar.
  late final Stream<List<RoomModel>> _roomsStream;

  @override
  void initState() {
    super.initState();
    final professorId = context.read<AuthController>().currentUser?.id ?? '';
    _roomsStream = RoomService().getProfessorRooms(professorId);
  }

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

  Future<void> _enterRoom(BuildContext context, RoomModel room) async {
    final auth = context.read<AuthController>();
    final professor = auth.currentUser;
    final professorId = professor?.id ?? '';

    // Carrega os dados da sala escolhida antes de navegar, sem depender do
    // initState da Dashboard — que pode não rodar de novo se o GoRouter
    // reaproveitar a página já existente da shell.
    await context.read<ProfessorController>().loadData(
          professorId,
          professorName: professor?.name ?? 'Professor',
          roomId: room.id,
        );

    if (!context.mounted) return;

    await context
        .read<GameContentController>()
        .loadContent(room.id, professorId: professorId);

    if (!context.mounted) return;

    // Só marca a sala como selecionada (memória + persistência) depois que
    // os dados já estão carregados, e navega em seguida — assim nenhum
    // notifyListeners() no meio do caminho derruba o Card/botão que
    // disparou essa ação antes que a navegação aconteça.
    await auth.selectProfessorRoom(room);
    if (!context.mounted) return;

    context.read<CurrentRoomController>().selectRoom(room);

    context.go(AppRoutes.professorDashboard);
  }

  @override
  Widget build(BuildContext context) {
    // Lido com `read`: essa tela não precisa se reconstruir quando o
    // AuthController notifica (ex.: ao selecionar a sala) — só precisamos
    // do professor logado, que não muda enquanto estamos aqui. Reconstruir
    // a tela à toa recriava o StreamBuilder abaixo e cancelava o fluxo de
    // entrada na sala (ver comentário em `_roomsStream`).
    final professor = context.read<AuthController>().currentUser;

    if (professor == null) {
      return const Scaffold(
        body: Center(
          child: Text('Professor não encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Sala'),
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
              stream: _roomsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final rooms = snapshot.data ?? [];

                if (rooms.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma sala cadastrada'),
                  );
                }

                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.school,
                          size: 40,
                        ),
                        title: Text(
                          room.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Código: ${room.code}'),
                            Text('${room.grade} - ${room.schoolYear}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Excluir sala',
                              onPressed: () => _confirmDeleteRoom(context, room),
                            ),
                            ElevatedButton(
                              onPressed: () => _enterRoom(context, room),
                              child: const Text('Entrar'),
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
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nova Sala'),
                onPressed: () {
                  context.push(AppRoutes.createRoom);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
