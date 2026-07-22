import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/student_controller.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/achievement_badge.dart';

/// Tela com todas as conquistas do aluno — as já desbloqueadas e as que
/// ainda faltam, cada uma com sua barra de progresso.
class StudentAchievementsView extends StatelessWidget {
  const StudentAchievementsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<StudentController>();
    final achievements = ctrl.achievements;
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      appBar: AppBar(title: const Text('Conquistas 🏅')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    '$unlockedCount de ${achievements.length} desbloqueadas',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.galaxyStar.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${ctrl.totalStars} ⭐',
                      style: const TextStyle(color: AppTheme.galaxyStar, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, i) => AchievementBadgeCard(
                  progress: achievements[i],
                  fullWidth: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
