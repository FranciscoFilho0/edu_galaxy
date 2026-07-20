import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/casual_game_model.dart';
import '../../services/casual_records_service.dart';
import '../../models/casual_game_stats_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_routes.dart';

/// Hub dos "jogos livres" — separado das Missões porque aqui não existe
/// matéria, nem ativação pelo professor, nem envio de resultado: é só
/// diversão, com recorde salvo no próprio aparelho.
class CasualGamesHubView extends StatelessWidget {
  const CasualGamesHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jogos Livres', style: TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
                  )),
                  SizedBox(height: 4),
                  Text('Só pra se divertir — não conta pra nenhuma missão', style: TextStyle(
                    color: AppTheme.galaxyCyan, fontSize: 13,
                  )),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: CasualGameModel.allGames.length,
                itemBuilder: (context, i) => _CasualGameCard(game: CasualGameModel.allGames[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CasualGameCard extends StatefulWidget {
  final CasualGameModel game;
  const _CasualGameCard({required this.game});

  @override
  State<_CasualGameCard> createState() => _CasualGameCardState();
}

class _CasualGameCardState extends State<_CasualGameCard> {
  final _recordsService = CasualRecordsService();
  CasualGameStats? _stats;

  @override
  void initState() {
    super.initState();
    _recordsService.loadStats(widget.game.id).then((s) {
      if (mounted) setState(() => _stats = s);
    });
  }

  String _recordLabel() {
    final s = _stats;
    if (s == null) return '';
    if (widget.game.id == 'memoria') {
      if (s.bestMoves == null) return 'Ainda sem recorde';
      return 'Recorde: ${s.bestMoves} jogadas · ${s.bestTimeSeconds}s';
    }
    if (widget.game.id == 'tetris' || widget.game.id == 'block_blast') {
      if (s.bestScore == null) return 'Ainda sem recorde';
      return 'Recorde: ${s.bestScore} pontos';
    }
    if (s.totalMatches == 0) return 'Ainda sem partidas';
    return '${s.wins}V ${s.losses}D ${s.draws}E · sequência recorde: ${s.bestStreak}';
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.casualGamePath(game.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.galaxyMid,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: game.color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: game.color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(game.iconEmoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title, style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 3),
                  Text(game.description, style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 12,
                  )),
                  const SizedBox(height: 6),
                  Text(_recordLabel(), style: const TextStyle(
                    color: AppTheme.galaxyStar, fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: game.color),
          ],
        ),
      ),
    );
  }
}
