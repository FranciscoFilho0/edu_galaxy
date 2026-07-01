import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/game_content_controller.dart';
import '../../../core/theme/app_theme.dart';

class MathConfigEditorView extends StatelessWidget {
  const MathConfigEditorView({super.key});

  String _opLabel(MathOperation op) {
    switch (op) {
      case MathOperation.soma: return 'Soma (+)';
      case MathOperation.subtracao: return 'Subtração (−)';
      case MathOperation.multiplicacao: return 'Multiplicação (×)';
      case MathOperation.divisao: return 'Divisão (÷)';
    }
  }

  String _opEmoji(MathOperation op) {
    switch (op) {
      case MathOperation.soma: return '➕';
      case MathOperation.subtracao: return '➖';
      case MathOperation.multiplicacao: return '✖️';
      case MathOperation.divisao: return '➗';
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<GameContentController>();

    return Scaffold(
      backgroundColor: AppTheme.profBackground,
      appBar: AppBar(
        title: const Text('Configurar Cálculos'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Operações ativas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.profPrimary)),
          const SizedBox(height: 4),
          Text('Escolha quais tipos de conta os alunos vão praticar.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ...MathOperation.values.map((op) {
            final active = content.enabledOperations.contains(op);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: SwitchListTile(
                value: active,
                onChanged: (_) => context.read<GameContentController>().toggleOperation(op),
                activeColor: AppTheme.profPrimary,
                title: Row(
                  children: [
                    Text(_opEmoji(op), style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(_opLabel(op), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text('Dificuldade numérica', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.profPrimary)),
          const SizedBox(height: 4),
          Text('Define o maior número usado em soma e subtração.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Número máximo', style: TextStyle(fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.profPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('${content.mathMaxNumber}', style: const TextStyle(color: AppTheme.profPrimary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Slider(
                    value: content.mathMaxNumber.toDouble(),
                    min: 10, max: 100, divisions: 9,
                    activeColor: AppTheme.profPrimary,
                    label: '${content.mathMaxNumber}',
                    onChanged: (v) => context.read<GameContentController>().setMathMaxNumber(v.round()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.profWarning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.profWarning, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'A multiplicação e divisão usam números de 1 a 10 para manter o desafio adequado.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
