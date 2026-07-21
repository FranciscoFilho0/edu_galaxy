import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/professor_controller.dart';
import '../../models/game_result_model.dart';
import '../../core/theme/app_theme.dart';

class ProfessorResultsView extends StatefulWidget {
  const ProfessorResultsView({super.key});

  @override
  State<ProfessorResultsView> createState() => _ProfessorResultsViewState();
}

class _ProfessorResultsViewState extends State<ProfessorResultsView> {
  String _selectedSubject = 'Todos';
  // null = "Todos os meses". Quando definido, guarda o dia 1 do mês/ano escolhido.
  DateTime? _selectedMonth;

  static const _monthNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  String _monthLabel(DateTime month) => '${_monthNames[month.month - 1]} ${month.year}';

  @override
  Widget build(BuildContext context) {
    final prof = context.watch<ProfessorController>();
    final subjects = ['Todos', ...{...prof.results.map((r) => r.subject)}];

    // Meses em que existe pelo menos um resultado, do mais recente para o mais antigo.
    final months = <DateTime>{
      for (final r in prof.results) DateTime(r.playedAt.year, r.playedAt.month),
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    // Se o mês selecionado não existir mais na lista (ex.: dados mudaram), volta para "Todos".
    if (_selectedMonth != null && !months.contains(_selectedMonth)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedMonth = null);
      });
    }

    final bySubject = _selectedSubject == 'Todos'
        ? prof.results
        : prof.results.where((r) => r.subject == _selectedSubject).toList();

    final filtered = _selectedMonth == null
        ? bySubject
        : bySubject.where((r) =>
            r.playedAt.year == _selectedMonth!.year && r.playedAt.month == _selectedMonth!.month).toList();

    return Scaffold(
      backgroundColor: AppTheme.profBackground,
      appBar: AppBar(title: const Text('Resultados')),
      body: Column(
        children: [
          // Filters - Matéria
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: subjects.map((s) {
                  final active = s == _selectedSubject;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s),
                      selected: active,
                      onSelected: (_) => setState(() => _selectedSubject = s),
                      selectedColor: AppTheme.profPrimary.withOpacity(0.15),
                      checkmarkColor: AppTheme.profPrimary,
                      labelStyle: TextStyle(
                        color: active ? AppTheme.profPrimary : Colors.grey.shade700,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Filters - Mês
          if (months.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: _selectedMonth == null ? AppTheme.profPrimary : Colors.grey.shade600,
                        ),
                        label: const Text('Todos os meses'),
                        selected: _selectedMonth == null,
                        onSelected: (_) => setState(() => _selectedMonth = null),
                        selectedColor: AppTheme.profPrimary.withOpacity(0.15),
                        checkmarkColor: AppTheme.profPrimary,
                        labelStyle: TextStyle(
                          color: _selectedMonth == null ? AppTheme.profPrimary : Colors.grey.shade700,
                          fontWeight: _selectedMonth == null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    ...months.map((m) {
                      final active = _selectedMonth == m;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_monthLabel(m)),
                          selected: active,
                          onSelected: (_) => setState(() => _selectedMonth = m),
                          selectedColor: AppTheme.profPrimary.withOpacity(0.15),
                          checkmarkColor: AppTheme.profPrimary,
                          labelStyle: TextStyle(
                            color: active ? AppTheme.profPrimary : Colors.grey.shade700,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          // Summary
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _SummaryChip(label: '${filtered.length} registros', icon: Icons.list),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: 'Média: ${filtered.isEmpty ? 0 : (filtered.map((r) => r.percentage).reduce((a, b) => a + b) / filtered.length).toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: prof.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Nenhum resultado encontrado.', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _ResultCard(result: filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SummaryChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.profPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.profPrimary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.profPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final GameResultModel result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = result.percentage.toInt();
    final color = pct >= 70 ? AppTheme.profSuccess : pct >= 50 ? AppTheme.profWarning : AppTheme.profError;
    final mins = result.durationSeconds ~/ 60;
    final secs = result.durationSeconds % 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.profPrimary.withOpacity(0.1),
              child: Text(result.studentName[0], style: const TextStyle(color: AppTheme.profPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(result.gameName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoPill(text: result.subject, color: AppTheme.profSecondary),
                      const SizedBox(width: 6),
                      _InfoPill(text: '${mins}m ${secs}s', color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                const SizedBox(height: 4),
                Text('${result.score}/${result.totalQuestions}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  final Color color;
  const _InfoPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
