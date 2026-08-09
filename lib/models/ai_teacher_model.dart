class AiTeacherExplanation {
  final String summary;
  final List<String> grammarNotes;
  final List<String> usageNotes;
  final List<AiTeacherExample> examples;
  final List<AiTeacherQuizItem> quiz;
  final List<String> suggestedQuestions;
  final String confidenceNote;

  const AiTeacherExplanation({
    required this.summary,
    required this.grammarNotes,
    required this.usageNotes,
    required this.examples,
    required this.quiz,
    required this.suggestedQuestions,
    required this.confidenceNote,
  });

  factory AiTeacherExplanation.fromJson(Map<String, dynamic> json) {
    return AiTeacherExplanation(
      summary: _asText(json['summary']),
      grammarNotes: _asStringList(json['grammarNotes']),
      usageNotes: _asStringList(json['usageNotes']),
      examples: _asMapList(
        json['examples'],
      ).map(AiTeacherExample.fromJson).toList(),
      quiz: _asMapList(json['quiz']).map(AiTeacherQuizItem.fromJson).toList(),
      suggestedQuestions: _asStringList(
        json['suggestedQuestions'] ?? json['hazirSorular'],
      ),
      confidenceNote: _asText(json['confidenceNote'] ?? json['safetyNote']),
    );
  }
}

class AiTeacherExample {
  final String arabic;
  final String turkish;

  const AiTeacherExample({required this.arabic, required this.turkish});

  factory AiTeacherExample.fromJson(Map<String, dynamic> json) {
    return AiTeacherExample(
      arabic: _asText(json['arabic'] ?? json['arapca']),
      turkish: _asText(json['turkish'] ?? json['turkce']),
    );
  }
}

class AiTeacherQuizItem {
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;

  const AiTeacherQuizItem({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory AiTeacherQuizItem.fromJson(Map<String, dynamic> json) {
    return AiTeacherQuizItem(
      question: _asText(json['question'] ?? json['soru']),
      options: _asStringList(json['options'] ?? json['secenekler']),
      answer: _asText(json['answer'] ?? json['cevap']),
      explanation: _asText(json['explanation'] ?? json['aciklama']),
    );
  }
}

String _asText(Object? value) => value?.toString().trim() ?? '';

List<String> _asStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  final text = _asText(value);
  return text.isEmpty ? const [] : [text];
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList();
}
