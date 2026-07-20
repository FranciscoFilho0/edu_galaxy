import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/professor_controller.dart';
import '../../models/student_model.dart';
import '../../models/game_result_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/pdf_service.dart';

/// Tela de detalhe de um único aluno: dados de cadastro, estatísticas de
/// desempenho e o histórico completo de resultados. É também daqui que o
/// professor edita o nome do aluno ou o exclui.
class ProfessorStudentDetailView extends StatelessWidget {
  final String studentId;
  const ProfessorStudentDetailView({super.key, required this.studentId});

  void _showEditNameDialog(BuildContext context, StudentModel student) {
    final ctrl = TextEditingController(text: student.name);
    final professorCtrl = context.read<ProfessorController>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Aluno', style: TextStyle(color: AppTheme.profPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do aluno',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              final ok = await professorCtrl.updateStudentName(student.id, newName);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted && !ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Não foi possível salvar o novo nome.')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, StudentModel student) {
    final professorCtrl = context.read<ProfessorController>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Aluno', style: TextStyle(color: AppTheme.profError, fontWeight: FontWeight.w700)),
        content: Text(
          'Tem certeza que deseja excluir "${student.name}"? '
          'Todos os resultados de jogos desse aluno também serão apagados. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.profError),
            onPressed: () async {
              final ok = await professorCtrl.deleteStudent(student.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                if (ok) {
                  context.pop(); // volta para a lista de alunos
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Não foi possível excluir o aluno.')),
                  );
                }
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prof = context.watch<ProfessorController>();

    // O aluno é procurado na lista já carregada pelo ProfessorController —
    // não precisamos buscar de novo no banco, e a tela atualiza sozinha
    // (graças ao notifyListeners) assim que o nome muda ou o aluno some.
    StudentModel? student;
    for (final s in prof.students) {
      if (s.id == studentId) {
        student = s;
        break;
      }
    }

    if (student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aluno')),
        body: const Center(child: Text('Aluno não encontrado.')),
      );
    }

    final results = prof.getResultsForStudent(student.id);
    final avgScore = results.isEmpty
        ? 0.0
        : results.map((r) => r.percentage).reduce((a, b) => a + b) / results.length;
    final totalStars = results.fold<int>(0, (sum, r) => sum + r.score);
    final avatars = ['🧑‍🚀', '👾', '🤖', '🧙', '🦸'];
    final avatarIdx = int.tryParse(student.avatarIndex) ?? 0;

    // Agrupa os resultados por matéria para mostrar a média em cada uma.
    final subjects = <String, List<GameResultModel>>{};
    for (final r in results) {
      subjects.putIfAbsent(r.subject, () => []).add(r);
    }

    return Scaffold(
      backgroundColor: AppTheme.profBackground,
      appBar: AppBar(
        title: const Text('Perfil do Aluno'),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => PdfService.shareStudentReport(
              student: student!,
              results: prof.getResultsForStudent(student.id),
            ),
          ),
          IconButton(
            tooltip: 'Editar nome',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditNameDialog(context, student!),
          ),
          IconButton(
            tooltip: 'Excluir aluno',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmDialog(context, student!),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Cabeçalho com avatar, nome e dados de cadastro ──────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.profPrimary.withOpacity(0.1),
                    child: Text(avatars[avatarIdx % avatars.length], style: const TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(height: 12),
                  Text(student.name, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.profSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Sala ${student.roomCode}',
                      style: const TextStyle(color: AppTheme.profSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Estatísticas gerais ──────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _StatCard(icon: Icons.gamepad_outlined, label: 'Jogos', value: '${results.length}')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.trending_up, label: 'Média geral', value: '${avgScore.toStringAsFixed(0)}%')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.star_outline, label: 'Estrelas', value: '$totalStars')),
            ],
          ),

          if (subjects.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Desempenho por matéria', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...subjects.entries.map((e) {
              final subjectAvg = e.value.map((r) => r.percentage).reduce((a, b) => a + b) / e.value.length;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                      Text('${e.value.length} jogos', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(width: 12),
                      Text('${subjectAvg.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.profPrimary)),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 16),
          Text('Histórico de resultados', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Esse aluno ainda não jogou nenhum jogo.', style: TextStyle(color: Colors.grey))),
            )
          else
            ...results.map((r) => _ResultTile(result: r)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.profPrimary, size: 20),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.profPrimary)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final GameResultModel result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = result.percentage.toInt();
    final color = pct >= 70 ? AppTheme.profSuccess : pct >= 50 ? AppTheme.profWarning : AppTheme.profError;
    final mins = result.durationSeconds ~/ 60;
    final secs = result.durationSeconds % 60;
    final date = result.playedAt;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.gameName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('$dateStr · $mins min $secs s', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
