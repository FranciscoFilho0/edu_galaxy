import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/game_content_controller.dart';
import '../../../controllers/professor_controller.dart';
import '../../../models/word_entry_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/subjects.dart';
import '../widgets/subject_picker_field.dart';

enum WordListType { spelling, syllables }

class WordListEditorView extends StatelessWidget {
  final WordListType type;
  const WordListEditorView({super.key, required this.type});

  String get _title => type == WordListType.spelling
      ? 'Palavras (Soletrar / Forca)'
      : 'Palavras (Sílabas)';

  @override
  Widget build(BuildContext context) {
    final content = context.watch<GameContentController>();
    final roomId = context.watch<ProfessorController>().room?.id ?? '';
    final words = type == WordListType.spelling ? content.spellingWords : content.syllableWords;

    return Scaffold(
      backgroundColor: AppTheme.profBackground,
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.profSecondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.profSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  type == WordListType.spelling
                      ? 'Estas palavras são usadas nos jogos Soletrar e Forca.'
                      : 'A separação de sílabas é automática, mas você pode revisar a palavra e a dica.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.profSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.profPrimary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  content.ttsHintEnabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                  color: AppTheme.profPrimary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ler dica em voz alta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(
                        'Mostra o botão de alto-falante nos jogos de palavras (Soletrar, Forca e Sílabas). Ele sempre lê apenas a dica, nunca a palavra, e só quando o aluno tocar o botão.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: content.ttsHintEnabled,
                  onChanged: (value) => content.setTtsHintEnabled(roomId, value),
                  activeColor: AppTheme.profPrimary,
                ),
              ],
            ),
          ),
          Expanded(
            child: words.isEmpty
                ? const Center(child: Text('Nenhuma palavra cadastrada.', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: words.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final w = words[i];
                      return _WordCard(
                        word: w,
                        showSyllables: type == WordListType.syllables,
                        onEdit: () => _showEditDialog(context, w),
                        onDelete: () => type == WordListType.spelling
                            ? content.removeSpellingWord(roomId, w.id)
                            : content.removeSyllableWord(roomId, w.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, null),
        backgroundColor: AppTheme.profPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Palavra', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WordEntryModel? existing) {
    final content = context.read<GameContentController>();
    final room = context.read<ProfessorController>().room;
    final roomId = room?.id ?? '';
    final professorId = room?.professorId ?? '';
    final wordCtrl = TextEditingController(text: existing?.word ?? '');
    final hintCtrl = TextEditingController(text: existing?.hint ?? '');
    String subject = existing?.subject ?? AppSubjects.all.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Nova Palavra' : 'Editar Palavra',
              style: TextStyle(color: AppTheme.profPrimary, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: wordCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Palavra', prefixIcon: Icon(Icons.text_fields)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hintCtrl,
                  decoration: const InputDecoration(labelText: 'Dica', prefixIcon: Icon(Icons.lightbulb_outline)),
                ),
                const SizedBox(height: 12),
                SubjectPickerField(
                  value: subject,
                  onChanged: (v) => setDialogState(() => subject = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (wordCtrl.text.trim().isEmpty || hintCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Preencha palavra e dica.'), backgroundColor: AppTheme.profError),
                  );
                  return;
                }
                final newWord = WordEntryModel(
                  id: existing?.id ?? 'w_${DateTime.now().millisecondsSinceEpoch}',
                  roomId: roomId,
                  professorId: professorId,
                  word: wordCtrl.text.trim().toUpperCase(),
                  hint: hintCtrl.text.trim(),
                  subject: subject,
                );
                if (type == WordListType.spelling) {
                  existing == null
                      ? content.addSpellingWord(roomId, newWord)
                      : content.updateSpellingWord(roomId, newWord);
                } else {
                  existing == null
                      ? content.addSyllableWord(roomId, newWord)
                      : content.updateSyllableWord(roomId, newWord);
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

class _WordCard extends StatelessWidget {
  final WordEntryModel word;
  final bool showSyllables;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _WordCard({required this.word, required this.showSyllables, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(word.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.profSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(word.subject, style: TextStyle(fontSize: 10, color: AppTheme.profSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(word.hint, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if (showSyllables) ...[
                    const SizedBox(height: 4),
                    Text(word.syllables.join(' - '), style: TextStyle(fontSize: 12, color: AppTheme.profPrimary, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit, color: AppTheme.profPrimary),
            IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: onDelete, color: AppTheme.profError),
          ],
        ),
      ),
    );
  }
}
