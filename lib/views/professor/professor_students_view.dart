import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/professor_controller.dart';
import '../../models/student_model.dart';
import '../../core/theme/app_theme.dart';

class ProfessorStudentsView extends StatelessWidget {
  const ProfessorStudentsView({super.key});

  void _showAddStudentDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Aluno', style: TextStyle(color: AppTheme.profPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do aluno',
            prefixIcon: Icon(Icons.person_add_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await context.read<ProfessorController>().addStudent(ctrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prof = context.watch<ProfessorController>();

    return Scaffold(
      backgroundColor: AppTheme.profBackground,
      appBar: AppBar(
        title: const Text('Alunos'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddStudentDialog(context),
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text('Novo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: prof.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar aluno...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                // Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${prof.students.length} alunos cadastrados',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                // List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: prof.students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _StudentCard(
                      student: prof.students[i],
                      results: prof.getResultsForStudent(prof.students[i].id),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(context),
        backgroundColor: AppTheme.profPrimary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Cadastrar Aluno', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentModel student;
  final List<dynamic> results;
  const _StudentCard({required this.student, required this.results});

  @override
  Widget build(BuildContext context) {
    final avgScore = results.isEmpty
        ? 0.0
        : results.map((r) => r.percentage as double).reduce((a, b) => a + b) / results.length;
    final avatars = ['🧑‍🚀', '👾', '🤖', '🧙', '🦸'];
    final avatarIdx = int.tryParse(student.avatarIndex) ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.profPrimary.withOpacity(0.1),
              child: Text(avatars[avatarIdx % avatars.length], style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.gamepad_outlined, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${results.length} jogos', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_outline, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Média ${avgScore.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
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
