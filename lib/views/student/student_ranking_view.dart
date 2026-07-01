import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/student_controller.dart';
import '../../core/theme/app_theme.dart';

class StudentRankingView extends StatelessWidget {
  const StudentRankingView({super.key});

  static const _mockRanking = [
    {'name': 'Carla Mendes', 'stars': 47, 'avatar': '🧙', 'rank': 1},
    {'name': 'Ana Silva', 'stars': 42, 'avatar': '🧑‍🚀', 'rank': 2},
    {'name': 'Diego Souza', 'stars': 38, 'avatar': '🤖', 'rank': 3},
    {'name': 'Bruno Costa', 'stars': 31, 'avatar': '👾', 'rank': 4},
    {'name': 'Elena Rocha', 'stars': 27, 'avatar': '🦸', 'rank': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: SafeArea(
        child: Column(
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
            // Top 3 podium
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PodiumPlace(rank: 2, data: _mockRanking[1], height: 100),
                  const SizedBox(width: 8),
                  _PodiumPlace(rank: 1, data: _mockRanking[0], height: 130),
                  const SizedBox(width: 8),
                  _PodiumPlace(rank: 3, data: _mockRanking[2], height: 80),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Rest of ranking
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _mockRanking.length - 3,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final data = _mockRanking[i + 3];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.galaxyMid,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Text('#${data['rank']}', style: const TextStyle(color: Color(0xFF89B4FA), fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 14),
                        Text(data['avatar'] as String, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(data['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                        Row(
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text('${data['stars']}', style: const TextStyle(color: AppTheme.galaxyStar, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;
  final double height;
  const _PodiumPlace({required this.rank, required this.data, required this.height});

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
          Text(data['avatar'] as String, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            (data['name'] as String).split(' ').first,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 12)),
              Text('${data['stars']}', style: const TextStyle(color: AppTheme.galaxyStar, fontSize: 12, fontWeight: FontWeight.bold)),
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
