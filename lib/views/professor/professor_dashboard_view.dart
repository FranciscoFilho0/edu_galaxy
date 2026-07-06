import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/professor_controller.dart';
import '../../controllers/game_content_controller.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_theme.dart';

class ProfessorDashboardView extends StatefulWidget {
  const ProfessorDashboardView({super.key});

  @override
  State<ProfessorDashboardView> createState() => _ProfessorDashboardViewState();
}

class _ProfessorDashboardViewState extends State<ProfessorDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthController>();
      final professorId = auth.currentUser?.id ?? '';
      await context.read<ProfessorController>().loadData(
            professorId,
            professorName: auth.currentUser?.name ?? 'Professor',
          );
      if (!mounted) return;
      context.read<GameContentController>().loadContent(professorId);
    });
  }

  void _showChangeCodeDialog(BuildContext context, String currentCode) {
    final ctrl = TextEditingController(text: currentCode);
    String? error;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Alterar código da turma', style: TextStyle(color: AppTheme.profPrimary, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolha um novo código de 6 caracteres. Se outro professor já estiver usando, você será avisado.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Novo código',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final newCode = ctrl.text.trim().toUpperCase();
                if (newCode.length != 6) {
                  setDialogState(() => error = 'O código precisa ter 6 caracteres.');
                  return;
                }
                final ok = await context.read<ProfessorController>().changeRoomCode(newCode);
                if (!ctx.mounted) return;
                if (ok) {
                  Navigator.pop(ctx);
                } else {
                  setDialogState(() => error = 'Esse código já está em uso. Tente outro.');
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final prof = context.watch<ProfessorController>();

    return Scaffold(
      backgroundColor: AppTheme.profBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, ${auth.currentUser?.name ?? 'Professor'}'),
            Text(
              auth.currentUser?.email ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await auth.logout();
              context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: prof.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => prof.loadData(auth.currentUser?.id ?? '', professorName: auth.currentUser?.name ?? 'Professor'),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoomCodeCard(
                      code: prof.room?.code ?? '------',
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: prof.room?.code ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Código copiado!'), duration: Duration(seconds: 1)),
                        );
                      },
                      onEdit: prof.room == null ? null : () => _showChangeCodeDialog(context, prof.room!.code),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _StatCard(label: 'Alunos', value: '${prof.students.length}', icon: Icons.people, color: AppTheme.profPrimary)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(label: 'Partidas', value: '${prof.results.length}', icon: Icons.sports_esports, color: AppTheme.profSecondary)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(label: 'Média', value: '${prof.averageScore.toStringAsFixed(0)}%', icon: Icons.trending_up, color: AppTheme.profSuccess)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Acesso rápido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.profPrimary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _QuickActionCard(
                          icon: Icons.bar_chart,
                          label: 'Resultados',
                          subtitle: '${prof.results.length} partidas',
                          color: AppTheme.profSecondary,
                          onTap: () => context.go(AppRoutes.professorResults),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickActionCard(
                          icon: Icons.people,
                          label: 'Alunos',
                          subtitle: '${prof.students.length} cadastrados',
                          color: AppTheme.profPrimary,
                          onTap: () => context.go(AppRoutes.professorStudents),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _QuickActionCard(
                          icon: Icons.games,
                          label: 'Jogos',
                          subtitle: '${prof.games.where((g) => g.isActive).length} ativos',
                          color: AppTheme.profAccent,
                          onTap: () => context.go(AppRoutes.professorGames),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickActionCard(
                          icon: Icons.person_add,
                          label: 'Novo Aluno',
                          subtitle: 'Cadastrar',
                          color: AppTheme.profWarning,
                          onTap: () {
                            context.go(AppRoutes.professorStudents);
                          },
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Últimas atividades', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.profPrimary)),
                    const SizedBox(height: 12),
                    if (prof.results.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Nenhuma partida registrada ainda.', style: TextStyle(color: Colors.grey)),
                      ),
                    ...prof.results.take(3).map((r) => _RecentResultTile(result: r)),
                  ],
                ),
              ),
            ),
    );
  }
}

class _RoomCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  final VoidCallback? onEdit;
  const _RoomCodeCard({required this.code, required this.onCopy, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.profPrimary, Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.profPrimary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.class_, color: Colors.white70, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Código da Turma', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(code, style: const TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4,
                )),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
              onPressed: onEdit,
              tooltip: 'Alterar código',
            ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white70),
            onPressed: onCopy,
            tooltip: 'Copiar código',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value, 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label, 
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label, 
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle, 
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentResultTile extends StatelessWidget {
  final dynamic result;
  const _RecentResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = result.percentage.toInt();
    final color = pct >= 70 ? AppTheme.profSuccess : pct >= 50 ? AppTheme.profWarning : AppTheme.profError;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.profPrimary.withOpacity(0.1),
            child: Text(result.studentName[0], style: const TextStyle(color: AppTheme.profPrimary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(result.gameName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}