import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/game_content_controller.dart';
import '../../../models/quiz_question_model.dart';
import '../../../core/theme/app_theme.dart';

class QuizEditorView extends StatelessWidget {
  const QuizEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<GameContentController>();

    return Scaffold(
      backgroundColor: AppTheme.profBackground,
      appBar: AppBar(
        title: const Text('Editar Perguntas'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: content.quizQuestions.isEmpty
          ? const Center(child: Text('Nenhuma pergunta cadastrada.', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: content.quizQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final q = content.quizQuestions[i];
                return _QuestionCard(
                  question: q,
                  onEdit: () => _showEditDialog(context, q),
                  onDelete: () => content.removeQuizQuestion(q.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, null),
        backgroundColor: AppTheme.profPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Pergunta', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showEditDialog(BuildContext context, QuizQuestionModel? existing) {
    final content = context.read<GameContentController>();
    final questionCtrl = TextEditingController(text: existing?.question ?? '');
    final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
    final optionCtrls = List.generate(4, (i) =>
        TextEditingController(text: existing != null && i < existing.options.length ? existing.options[i] : ''));
    int correctIndex = existing?.correctIndex ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Nova Pergunta' : 'Editar Pergunta',
              style: const TextStyle(color: AppTheme.profPrimary, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(labelText: 'Matéria', prefixIcon: Icon(Icons.subject)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: questionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Pergunta', prefixIcon: Icon(Icons.help_outline)),
                  ),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerLeft, child: Text('Alternativas (selecione a correta):',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey))),
                  const SizedBox(height: 8),
                  ...List.generate(4, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: i,
                              groupValue: correctIndex,
                              activeColor: AppTheme.profSuccess,
                              onChanged: (v) => setDialogState(() => correctIndex = v ?? 0),
                            ),
                            Expanded(
                              child: TextField(
                                controller: optionCtrls[i],
                                decoration: InputDecoration(
                                  labelText: 'Opção ${String.fromCharCode(65 + i)}',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (questionCtrl.text.trim().isEmpty || optionCtrls.any((c) => c.text.trim().isEmpty)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Preencha todos os campos.'), backgroundColor: AppTheme.profError),
                  );
                  return;
                }
                final newQ = QuizQuestionModel(
                  id: existing?.id ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
                  question: questionCtrl.text.trim(),
                  subject: subjectCtrl.text.trim().isEmpty ? 'Geral' : subjectCtrl.text.trim(),
                  options: optionCtrls.map((c) => c.text.trim()).toList(),
                  correctIndex: correctIndex,
                );
                if (existing == null) {
                  content.addQuizQuestion(newQ);
                } else {
                  content.updateQuizQuestion(newQ);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuizQuestionModel question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _QuestionCard({required this.question, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.profSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(question.subject, style: const TextStyle(color: AppTheme.profSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit, color: AppTheme.profPrimary),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: onDelete, color: AppTheme.profError),
              ],
            ),
            const SizedBox(height: 6),
            Text(question.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: question.options.asMap().entries.map((e) {
                final isCorrect = e.key == question.correctIndex;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCorrect ? AppTheme.profSuccess.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: isCorrect ? Border.all(color: AppTheme.profSuccess.withOpacity(0.4)) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCorrect) const Icon(Icons.check, size: 12, color: AppTheme.profSuccess),
                      if (isCorrect) const SizedBox(width: 4),
                      Text(e.value, style: TextStyle(fontSize: 12, color: isCorrect ? AppTheme.profSuccess : Colors.grey.shade700)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
