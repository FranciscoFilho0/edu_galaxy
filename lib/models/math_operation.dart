/// Operações matemáticas que o jogo "Cálculos Espaciais" pode sortear.
/// Fica em um arquivo próprio (fora do controller) só para evitar que
/// o controller e o serviço de banco de dados precisem importar um ao outro.
enum MathOperation { soma, subtracao, multiplicacao, divisao }
