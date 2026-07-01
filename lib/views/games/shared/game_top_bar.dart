import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';

class GameTopBar extends StatelessWidget {
  final String title;
  final int current;
  final int total;
  final int score;

  const GameTopBar({
    super.key,
    required this.title,
    required this.current,
    required this.total,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => _confirmExit(context),
              ),
              Expanded(
                child: Text(title, textAlign: TextAlign.center, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                )),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: AppTheme.galaxyStar, size: 18),
                  const SizedBox(width: 4),
                  Text('$score', style: const TextStyle(color: AppTheme.galaxyStar, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.galaxyMid,
              valueColor: const AlwaysStoppedAnimation(AppTheme.galaxyPurple),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${current.clamp(0, total)}/$total', style: const TextStyle(
              color: Color(0xFF89B4FA), fontSize: 11,
            )),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.galaxyMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair da missão?', style: TextStyle(color: Colors.white)),
        content: const Text('Seu progresso nesta partida será perdido.', style: TextStyle(color: Color(0xFF89B4FA))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar', style: TextStyle(color: AppTheme.galaxyCyan)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.studentGameSelect);
            },
            child: const Text('Sair', style: TextStyle(color: Color(0xFFEC4899))),
          ),
        ],
      ),
    );
  }
}
