class WordEntryModel {
  final String id;
  final String word;
  final String hint;
  final String subject;

  const WordEntryModel({
    required this.id,
    required this.word,
    required this.hint,
    required this.subject,
  });

  List<String> get syllables => _splitSyllables(word);

  // Simple Portuguese syllable splitter (heuristic - good enough for game content)
  static List<String> _splitSyllables(String word) {
    final w = word.toLowerCase();
    const vowels = 'aeiouáéíóúâêîôûãõ';
    final List<String> result = [];
    String current = '';
    for (int i = 0; i < w.length; i++) {
      current += w[i];
      final isVowel = vowels.contains(w[i]);
      final nextIsConsonant = i + 1 < w.length && !vowels.contains(w[i + 1]);
      final nextNextIsVowel = i + 2 < w.length && vowels.contains(w[i + 2]);
      if (isVowel && nextIsConsonant && nextNextIsVowel) {
        result.add(current);
        current = '';
      }
    }
    if (current.isNotEmpty) result.add(current);
    return result.isEmpty ? [word] : result;
  }

  WordEntryModel copyWith({String? word, String? hint, String? subject}) {
    return WordEntryModel(
      id: id,
      word: word ?? this.word,
      hint: hint ?? this.hint,
      subject: subject ?? this.subject,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'word': word,
        'hint': hint,
        'subject': subject,
      };

  factory WordEntryModel.fromMap(Map<String, dynamic> map) {
    return WordEntryModel(
      id: map['id'] ?? '',
      word: map['word'] ?? '',
      hint: map['hint'] ?? '',
      subject: map['subject'] ?? '',
    );
  }
}
