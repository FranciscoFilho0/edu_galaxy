import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/student_controller.dart';
import '../../../models/achievement_model.dart';
import '../../student/widgets/achievement_popup_dialog.dart';

class GameResultScreen extends StatefulWidget {
  final String gameEmoji;
  final String gameTitle;
  final int score;
  final int total;
  final int durationSeconds;
  final VoidCallback onPlayAgain;

  /// IDs das conquistas que já estavam desbloqueadas *antes* desta partida
  /// ser salva. É comparando com isso que a tela descobre quais conquistas
  /// são novas e merecem um pop-up — cada jogo captura esse snapshot logo
  /// antes de chamar `StudentController.saveResult()`.
  final Set<String> previouslyUnlockedIds;

  const GameResultScreen({
    super.key,
    required this.gameEmoji,
    required this.gameTitle,
    required this.score,
    required this.total,
    required this.durationSeconds,
    required this.onPlayAgain,
    this.previouslyUnlockedIds = const {},
  });

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  // Conquistas que ainda precisam ter o pop-up exibido, e um controle para
  // não abrir vários pop-ups sobrepostos ao mesmo tempo.
  final List<AchievementModel> _pendingPopups = [];
  final Set<String> _alreadyQueuedIds = {};
  bool _isShowingPopup = false;

  @override
  void initState() {
    super.initState();

    // O resultado da partida é salvo de forma assíncrona (Firestore), então
    // a conquista pode ainda não estar calculada no exato momento em que
    // esta tela aparece. Em vez de checar uma única vez, escutamos o
    // StudentController: assim que `saveResult()` terminar e notificar os
    // listeners, `_checkForNewAchievements` roda de novo automaticamente.
    context.read<StudentController>().addListener(_checkForNewAchievements);

    // Ainda assim, fazemos uma checagem imediata após o primeiro frame,
    // cobrindo o caso em que o salvamento já tinha terminado antes mesmo
    // desta tela ser montada.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForNewAchievements());
  }

  @override
  void dispose() {
    context.read<StudentController>().removeListener(_checkForNewAchievements);
    super.dispose();
  }

  void _checkForNewAchievements() {
    if (!mounted) return;

    final achievements = context.read<StudentController>().achievements;
    final newlyUnlocked = achievements.where((a) =>
        a.unlocked &&
        !widget.previouslyUnlockedIds.contains(a.achievement.id) &&
        !_alreadyQueuedIds.contains(a.achievement.id));

    if (newlyUnlocked.isEmpty) return;

    setState(() {
      for (final progress in newlyUnlocked) {
        _alreadyQueuedIds.add(progress.achievement.id);
        _pendingPopups.add(progress.achievement);
      }
    });

    _showNextPopupIfNeeded();
  }

  Future<void> _showNextPopupIfNeeded() async {
    if (_isShowingPopup || _pendingPopups.isEmpty || !mounted) return;

    _isShowingPopup = true;
    final achievement = _pendingPopups.removeAt(0);

    await AchievementPopupDialog.show(context, achievement);

    _isShowingPopup = false;
    if (mounted && _pendingPopups.isNotEmpty) {
      _showNextPopupIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.score;
    final total = widget.total;
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final stars = total > 0 ? (score / total * 3).round().clamp(0, 3) : 0;
    final mins = widget.durationSeconds ~/ 60;
    final secs = widget.durationSeconds % 60;

    final String message;
    final String emoji;
    if (pct >= 80) {
      message = 'Incrível! Você é um verdadeiro explorador!';
      emoji = '🌟';
    } else if (pct >= 50) {
      message = 'Muito bem! Continue explorando!';
      emoji = '🚀';
    } else {
      message = 'Boa tentativa! Vamos treinar mais!';
      emoji = '🛰️';
    }

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 4),
              Text(widget.gameTitle, style: const TextStyle(color: AppTheme.galaxyCyan, fontSize: 14)),
              const SizedBox(height: 28),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: AppTheme.galaxyStar,
                    size: 48,
                  ),
                )),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.galaxyMid,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.galaxyPurple.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(label: 'Acertos', value: '$score/$total'),
                    _VerticalDivider(),
                    _StatColumn(label: 'Aproveitamento', value: '$pct%'),
                    _VerticalDivider(),
                    _StatColumn(label: 'Tempo', value: '${mins}m ${secs}s'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: widget.onPlayAgain,
                  icon: const Icon(Icons.replay),
                  label: const Text('Jogar Novamente', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.galaxyPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.studentGameSelect),
                  icon: const Icon(Icons.rocket_launch, color: Colors.white),
                  label: const Text('Outras Missões', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.galaxyCyan),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label, value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF89B4FA), fontSize: 11)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppTheme.galaxyPurple.withOpacity(0.3));
  }
}
