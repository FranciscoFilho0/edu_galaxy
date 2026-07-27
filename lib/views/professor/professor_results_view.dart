import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/professor_controller.dart';
import '../../models/game_result_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_routes.dart';

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

    // Agrupa os resultados filtrados por aluno, para não misturar todas as
    // partidas de todos os alunos numa lista só. Cada aluno vira um card
    // (com média e nº de jogos) que expande para mostrar o histórico.
    final byStudent = <String, List<GameResultModel>>{};
    for (final r in filtered) {
      byStudent.putIfAbsent(r.studentId, () => []).add(r);
    }
    for (final list in byStudent.values) {
      list.sort((a, b) => b.playedAt.compareTo(a.playedAt)); // mais recente primeiro
    }
    final studentGroups = byStudent.values.toList()
      ..sort((a, b) => b.first.playedAt.compareTo(a.first.playedAt)); // aluno mais ativo recentemente no topo

    return Scaffold(
      backgroundColor: AppTheme.profBackground,
      appBar: AppBar(title: const Text('Resultados')),
      body: Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _SummaryChip(label: '${studentGroups.length} alunos', icon: Icons.groups_outlined),
                const SizedBox(width: 8),
                _SummaryChip(label: '${filtered.length} jogos', icon: Icons.list),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: 'Média: ${filtered.isEmpty ? 0 : (filtered.map((r) => r.percentage).reduce((a, b) => a + b) / filtered.length).toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                ),
              ],
            ),
          ),
          Expanded(
            child: prof.isLoading
                ? const Center(child: CircularProgressIndicator())
                : studentGroups.isEmpty
                    ? const Center(child: Text('Nenhum resultado encontrado.', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: studentGroups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _StudentGroupCard(results: studentGroups[i]),
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
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.profPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Card compacto de um aluno: mostra o nome, quantos jogos ele tem e a média
/// geral. Ao tocar, expande e revela o histórico recente de partidas, com
/// atalho para o perfil completo do aluno (histórico total + exportar PDF).
class _StudentGroupCard extends StatelessWidget {
  final List<GameResultModel> results; // já ordenado do mais recente pro mais antigo
  static const _maxPreview = 5;

  const _StudentGroupCard({required this.results});

  @override
  Widget build(BuildContext context) {
    final first = results.first;
    final studentId = first.studentId;
    final studentName = first.studentName;
    final avg = results.map((r) => r.percentage).reduce((a, b) => a + b) / results.length;
    final pct = avg.round();
    final color = pct >= 70 ? AppTheme.profSuccess : pct >= 50 ? AppTheme.profWarning : AppTheme.profError;
    final lastDate = first.playedAt;
    final dateStr = '${lastDate.day.toString().padLeft(2, '0')}/${lastDate.month.toString().padLeft(2, '0')}/${lastDate.year}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('student_group_$studentId'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.profPrimary.withOpacity(0.1),
            child: Text(
              studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
              style: TextStyle(color: AppTheme.profPrimary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Text(
            '${results.length} jogo${results.length == 1 ? '' : 's'} · último em $dateStr',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(width: 4),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            const Divider(height: 1),
            ...results.take(_maxPreview).map((r) => _CompactResultRow(result: r)),
            if (results.length > _maxPreview)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'e mais ${results.length - _maxPreview} resultado${results.length - _maxPreview == 1 ? '' : 's'}...',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.push(AppRoutes.professorStudentDetailPath(studentId)),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Ver perfil completo'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.profPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha compacta usada dentro do card expandido — uma partida por linha.
class _CompactResultRow extends StatelessWidget {
  final GameResultModel result;
  const _CompactResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = result.percentage.toInt();
    final color = pct >= 70 ? AppTheme.profSuccess : pct >= 50 ? AppTheme.profWarning : AppTheme.profError;
    final mins = result.durationSeconds ~/ 60;
    final secs = result.durationSeconds % 60;
    final date = result.playedAt;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.gameName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _InfoPill(text: result.subject, color: AppTheme.profSecondary),
                    const SizedBox(width: 6),
                    Text('$dateStr · ${mins}m ${secs}s', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 2),
              Text('${result.score}/${result.totalQuestions}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
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
