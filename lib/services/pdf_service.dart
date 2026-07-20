import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/student_model.dart';
import '../models/game_result_model.dart';

/// Serviço responsável por gerar o PDF do "Perfil do Aluno" — o mesmo
/// conteúdo que aparece em [ProfessorStudentDetailView], só que desenhado
/// em páginas de PDF em vez de widgets de tela.
///
/// Repare que esse arquivo não sabe nada sobre Firestore nem sobre a UI:
/// ele só recebe os dados prontos (StudentModel + lista de resultados) e
/// devolve os bytes do PDF. Quem busca os dados continua sendo o
/// ProfessorController, exatamente como já acontece na tela.
class PdfService {
  /// Gera o PDF e já abre a tela nativa de compartilhar/salvar/imprimir.
  /// É esse método que o botão na tela vai chamar.
  static Future<void> shareStudentReport({
    required StudentModel student,
    required List<GameResultModel> results,
  }) async {
    final bytes = await _buildStudentReport(student: student, results: results);

    // Printing.sharePdf abre o menu do sistema (compartilhar, salvar em
    // arquivos, enviar por WhatsApp/e-mail, etc.) — é o mesmo pacote que
    // sabe converter os bytes num arquivo temporário e chamar esse menu.
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'relatorio_${_slug(student.name)}.pdf',
    );
  }

  /// Monta o documento PDF em si. Separado do método acima só pra ficar
  /// fácil de testar ou reaproveitar (ex: se um dia você quiser gerar
  /// vários PDFs de uma vez, ou salvar sem abrir o menu de compartilhar).
  static Future<Uint8List> _buildStudentReport({
    required StudentModel student,
    required List<GameResultModel> results,
  }) async {
    final doc = pw.Document();

    // Mesmos cálculos que já existem em ProfessorStudentDetailView —
    // repetidos aqui porque o PDF é montado de forma independente da tela.
    final avgScore = results.isEmpty
        ? 0.0
        : results.map((r) => r.percentage).reduce((a, b) => a + b) / results.length;
    final totalStars = results.fold<int>(0, (sum, r) => sum + r.score);

    final subjects = <String, List<GameResultModel>>{};
    for (final r in results) {
      subjects.putIfAbsent(r.subject, () => []).add(r);
    }

    // pw.MultiPage quebra o conteúdo em várias páginas automaticamente
    // se a lista de resultados for grande — diferente de pw.Page, que
    // corta o conteúdo se não couber numa página só.
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(student),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildStatsRow(results.length, avgScore, totalStars),
          if (subjects.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('Desempenho por matéria',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...subjects.entries.map((e) => _buildSubjectRow(e.key, e.value)),
          ],
          pw.SizedBox(height: 20),
          pw.Text('Histórico de resultados',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (results.isEmpty)
            pw.Text('Esse aluno ainda não jogou nenhum jogo.',
                style: const pw.TextStyle(color: PdfColors.grey700))
          else
            _buildResultsTable(results),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHeader(StudentModel student) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Relatório de Desempenho',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(student.name,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text('Sala ${student.roomCode}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey400),
      ],
    );
  }

  static pw.Widget _buildStatsRow(int totalGames, double avgScore, int totalStars) {
    return pw.Row(
      children: [
        _statBox('Jogos', '$totalGames'),
        pw.SizedBox(width: 10),
        _statBox('Média geral', '${avgScore.toStringAsFixed(0)}%'),
        pw.SizedBox(width: 10),
        _statBox('Estrelas', '$totalStars'),
      ],
    );
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            pw.Text(value, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSubjectRow(String subject, List<GameResultModel> subjectResults) {
    final avg = subjectResults.map((r) => r.percentage).reduce((a, b) => a + b) / subjectResults.length;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(subject),
          pw.Text('${subjectResults.length} jogos', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
          pw.Text('${avg.toStringAsFixed(0)}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  /// Tabela com o histórico completo — Table.fromTextArray monta cabeçalho
  /// + linhas automaticamente a partir de listas de strings, então basta
  /// converter cada GameResultModel numa linha de texto.
  static pw.Widget _buildResultsTable(List<GameResultModel> results) {
    return pw.Table.fromTextArray(
      headers: ['Jogo', 'Matéria', 'Data', 'Duração', 'Resultado'],
      data: results.map((r) {
        final pct = r.percentage.toInt();
        final mins = r.durationSeconds ~/ 60;
        final secs = r.durationSeconds % 60;
        final date = r.playedAt;
        final dateStr =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        return [
          r.gameName,
          r.subject,
          dateStr,
          '${mins}min ${secs}s',
          '$pct%',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellStyle: const pw.TextStyle(fontSize: 9.5),
      cellAlignment: pw.Alignment.centerLeft,
      cellHeight: 24,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    );
  }

  static String _slug(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
}
