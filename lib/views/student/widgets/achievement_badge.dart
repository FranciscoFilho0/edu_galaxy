import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/achievement_model.dart';

/// Card visual de uma conquista. Fica "apagado" (cinza, com o emoji meio
/// transparente) enquanto não é desbloqueada, e mostra uma barra de
/// progresso rumo à meta.
///
/// Usado em dois lugares:
///   - `student_home_view.dart`: numa lista horizontal (largura fixa)
///   - `student_achievements_view.dart`: numa grade (usa a largura do grid)
class AchievementBadgeCard extends StatelessWidget {
  final AchievementProgress progress;
  final bool fullWidth;

  const AchievementBadgeCard({
    super.key,
    required this.progress,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final achievement = progress.achievement;
    final unlocked = progress.unlocked;

    return Container(
      width: fullWidth ? null : 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.galaxyMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? AppTheme.galaxyStar.withOpacity(0.5) : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: unlocked ? 1 : 0.35,
            child: Text(achievement.emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF89B4FA), fontSize: 10.5),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.progressRatio,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                unlocked ? AppTheme.galaxyStar : AppTheme.galaxyPurple,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unlocked ? 'Concluída!' : '${progress.current}/${progress.target}',
            style: TextStyle(
              color: unlocked ? AppTheme.galaxyStar : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
