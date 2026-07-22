import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/student_controller.dart';
import '../../controllers/game_content_controller.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/achievement_model.dart';
import 'widgets/achievement_badge.dart';

class StudentHomeView extends StatefulWidget {
  const StudentHomeView({super.key});

  @override
  State<StudentHomeView> createState() => _StudentHomeViewState();
}

class _StudentHomeViewState extends State<StudentHomeView> {
  static const List<String> _avatars = ['🧑‍🚀', '👾', '🤖', '🧙', '🦸', '🐉'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final student = auth.currentStudent;
      if (student == null) return;
      // Sempre buscamos os jogos ativos e as perguntas/palavras da sala
      // do professor deste aluno (student.professorId) — nunca de outra sala.
      context.read<StudentController>().loadGames(
            professorId: student.professorId,
            studentId: student.id,
          );
      context.read<GameContentController>().loadContent(student.professorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final ctrl = context.watch<StudentController>();
    final student = auth.currentStudent;
    final avatarIdx = int.tryParse(student?.avatarIndex ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: Stack(
        children: [
          const Positioned.fill(child: _GalaxyBackground()),
          SafeArea(
            child: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.galaxyViolet))
                : CustomScrollView(
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.galaxyPurple, AppTheme.galaxyCyan],
                                  ),
                                  boxShadow: [BoxShadow(color: AppTheme.galaxyPurple.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)],
                                ),
                                child: Center(child: Text(_avatars[avatarIdx % _avatars.length], style: const TextStyle(fontSize: 28))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Olá, ${student?.name ?? 'Astronauta'}!', style: const TextStyle(
                                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                                    )),
                                    Text('Turma: ${student?.roomCode ?? '------'}', style: const TextStyle(
                                      color: AppTheme.galaxyCyan, fontSize: 12, letterSpacing: 1,
                                    )),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Color(0xFF89B4FA)),
                               onPressed: () async {
  await auth.logout();
  context.go(AppRoutes.login);
},
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Stats
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(child: _GlowStatCard(
                                emoji: '⭐',
                                value: '${ctrl.totalStars}',
                                label: 'Estrelas',
                                color: AppTheme.galaxyStar,
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _GlowStatCard(
                                emoji: '🎮',
                                value: '${ctrl.gamesPlayed}',
                                label: 'Missões',
                                color: AppTheme.galaxyPurple,
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _GlowStatCard(
                                emoji: '🚀',
                                value: '${ctrl.availableGames.length}',
                                label: 'Jogos',
                                color: AppTheme.galaxyCyan,
                              )),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 28)),

                      // CTA card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GestureDetector(
                            onTap: () => context.go(AppRoutes.studentGameSelect),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.galaxyPurple, Color(0xFF4C1D95)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: AppTheme.galaxyPurple.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 6))],
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('🚀 Iniciar Missão!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 6),
                                        Text('Escolha um jogo e comece a explorar a galáxia do conhecimento!',
                                            style: TextStyle(color: Color(0xFFCDD6F4), fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // Conquistas (preview)
                      SliverToBoxAdapter(
                        child: _AchievementsPreview(achievements: ctrl.achievements),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // Recent activity title
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Últimas Missões 🛸', style: TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                          )),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 12)),

                      // Recent results
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            if (i >= ctrl.myResults.length) return null;
                            final r = ctrl.myResults[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              child: _MissionResultTile(
                                emoji: r.gameId == 'calculos' ? '🔢' : r.gameId == 'soletrar' ? '🔤' : r.gameId == 'forca' ? '🪐' : r.gameId == 'silabas' ? '🧩' : '❓',
                                gameName: r.gameName,
                                score: r.score,
                                total: r.totalQuestions,
                              ),
                            );
                          },
                          childCount: ctrl.myResults.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GlowStatCard extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _GlowStatCard({required this.emoji, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.galaxyMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Color(0xFF89B4FA), fontSize: 11)),
        ],
      ),
    );
  }
}

class _MissionResultTile extends StatelessWidget {
  final String emoji, gameName;
  final int score, total;
  const _MissionResultTile({required this.emoji, required this.gameName, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = (score / total * 100).toInt();
    final stars = (pct / 100 * 3).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.galaxyMid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gameName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: List.generate(3, (i) => Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  color: AppTheme.galaxyStar, size: 16,
                ))),
              ],
            ),
          ),
          Text('$score/$total', style: const TextStyle(color: AppTheme.galaxyCyan, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _AchievementsPreview extends StatelessWidget {
  final List<AchievementProgress> achievements;
  const _AchievementsPreview({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    // Mostra primeiro as desbloqueadas (pra comemorar) e depois as que
    // faltam, até um total de 6 cards no preview da home.
    final unlocked = achievements.where((a) => a.unlocked).toList();
    final locked = achievements.where((a) => !a.unlocked).toList();
    final preview = [...unlocked, ...locked].take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('Conquistas 🏅', style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
              )),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(AppRoutes.studentAchievements),
                child: Text(
                  '$unlockedCount/${achievements.length} · Ver todas',
                  style: const TextStyle(color: AppTheme.galaxyCyan, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: preview.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => AchievementBadgeCard(progress: preview[i]),
          ),
        ),
      ],
    );
  }
}

class _GalaxyBackground extends StatelessWidget {
  const _GalaxyBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GalaxyPainter());
  }
}

class _GalaxyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Nebula glow top
    paint.shader = RadialGradient(
      colors: [const Color(0xFF7C3AED).withOpacity(0.15), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.8, 0), radius: size.width * 0.6));
    canvas.drawCircle(Offset(size.width * 0.8, 0), size.width * 0.6, paint);

    // Nebula glow bottom
    paint.shader = RadialGradient(
      colors: [const Color(0xFF06B6D4).withOpacity(0.1), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(0, size.height), radius: size.width * 0.5));
    canvas.drawCircle(Offset(0, size.height), size.width * 0.5, paint);

    // Stars
    paint.shader = null;
    final starPositions = [
      [0.1, 0.1], [0.3, 0.05], [0.6, 0.08], [0.85, 0.12],
      [0.05, 0.25], [0.7, 0.22], [0.45, 0.3], [0.9, 0.35],
      [0.15, 0.5], [0.55, 0.55], [0.8, 0.6], [0.35, 0.65],
      [0.65, 0.75], [0.2, 0.8], [0.75, 0.85], [0.5, 0.9],
    ];
    for (int i = 0; i < starPositions.length; i++) {
      paint.color = Colors.white.withOpacity(i % 3 == 0 ? 0.8 : 0.3);
      canvas.drawCircle(
        Offset(size.width * starPositions[i][0], size.height * starPositions[i][1]),
        i % 5 == 0 ? 2.0 : 1.0, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
