import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/student_controller.dart';
import '../../models/ranking_entry_model.dart';
import '../../core/theme/app_theme.dart';

// Mesma lista de avatares usada na criação de perfil do aluno — o
// avatarIndex salvo no banco é só a posição nessa lista.
const List<String> _avatarEmojis = ['🧑‍🚀', '👾', '🤖', '🧙', '🦸', '🐉'];

String _avatarFor(String avatarIndex) {
  final i = int.tryParse(avatarIndex) ?? 0;
  return _avatarEmojis[i % _avatarEmojis.length];
}

class StudentRankingView extends StatefulWidget {
  const StudentRankingView({super.key});

  @override
  State<StudentRankingView> createState() => _StudentRankingViewState();
}

class _StudentRankingViewState extends State<StudentRankingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final student = context.read<AuthController>().currentStudent;
      if (student == null) return;
      context.read<StudentController>().loadRanking(student.professorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<StudentController>();
    final ranking = ctrl.ranking;

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.galaxyPurple,
          onRefresh: () async {
            final student = context.read<AuthController>().currentStudent;
            if (student != null) {
              await context.read<StudentController>().loadRanking(student.professorId);
            }
          },
          child: ranking.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          Text('🏆 Ranking da Turma', style: TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
                          )),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          'Ainda não há alunos com pontuação nesta turma.',
                          style: TextStyle(color: Color(0xFF89B4FA)),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          Text('🏆 Ranking da Turma', style: TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Pódio com o Top 3 (só aparece quem realmente existe na turma)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (ranking.length > 1) _PodiumPlace(rank: 2, entry: ranking[1], height: 100),
                          if (ranking.length > 1) const SizedBox(width: 8),
                          _PodiumPlace(rank: 1, entry: ranking[0], height: 130),
                          if (ranking.length > 2) const SizedBox(width: 8),
                          if (ranking.length > 2) _PodiumPlace(rank: 3, entry: ranking[2], height: 80),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Resto da turma (a partir da 4ª posição)
                    if (ranking.length > 3)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            for (int i = 3; i < ranking.length; i++) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.galaxyMid,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.15)),
                                ),
                                child: Row(
                                  children: [
                                    Text('#${i + 1}', style: const TextStyle(color: Color(0xFF89B4FA), fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(width: 14),
                                    Text(_avatarFor(ranking[i].avatarIndex), style: const TextStyle(fontSize: 28)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(ranking[i].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                    Row(
                                      children: [
                                        const Text('⭐', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 4),
                                        Text('${ranking[i].stars}', style: const TextStyle(color: AppTheme.galaxyStar, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (i < ranking.length - 1) const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final int rank;
  final RankingEntryModel entry;
  final double height;
  const _PodiumPlace({required this.rank, required this.entry, required this.height});

  Color get _podiumColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    return const Color(0xFFCD7F32);
  }

  String get _medal => rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(_avatarFor(entry.avatarIndex), style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            entry.name.split(' ').first,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 12)),
              Text('${entry.stars}', style: const TextStyle(color: AppTheme.galaxyStar, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_podiumColor.withOpacity(0.8), _podiumColor.withOpacity(0.4)],
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Center(child: Text(_medal, style: const TextStyle(fontSize: 28))),
          ),
        ],
      ),
    );
  }
}
