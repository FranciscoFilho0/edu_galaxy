/// Matérias disponíveis para o professor cadastrar perguntas e palavras,
/// baseadas no currículo comum do Ensino Fundamental 1 (1º ao 5º ano).
///
/// Mantida como lista fixa (em vez de texto livre) para que os resultados
/// fiquem sempre organizados nas mesmas matérias, tanto na tela de
/// "Resultados" do professor quanto nos relatórios em PDF.
class AppSubjects {
  AppSubjects._();

  static const List<String> all = [
    'Português',
    'Matemática',
    'Ciências',
    'História',
    'Geografia',
    'Artes',
    'Educação Física',
    'Inglês',
  ];
}
