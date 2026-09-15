class QuizOption {
  final String id;
  final String label;
  final bool isCorrect;

  const QuizOption({required this.id, required this.label, required this.isCorrect});

  factory QuizOption.fromMap(Map<String, dynamic> map) {
    return QuizOption(
      id: map['id'] as String,
      label: map['label'] as String,
      isCorrect: map['is_correct'] as bool? ?? false,
    );
  }
}

class QuizQuestion {
  final String id;
  final String statement;
  final List<QuizOption> options;

  const QuizQuestion({required this.id, required this.statement, required this.options});

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    final options = (map['quiz_options'] as List<dynamic>? ?? [])
        .map((o) => QuizOption.fromMap(o as Map<String, dynamic>))
        .toList();
    return QuizQuestion(
      id: map['id'] as String,
      statement: map['statement'] as String,
      options: options,
    );
  }
}

/// Un quiz de la banque, avec ses questions (chargées à la demande
/// quand une session live démarre — la liste pour le picker n'a pas
/// besoin des questions).
class Quiz {
  final String id;
  final String title;
  final String? description;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.id,
    required this.title,
    this.description,
    this.questions = const [],
  });

  factory Quiz.fromMap(Map<String, dynamic> map) {
    final questions = (map['quiz_questions'] as List<dynamic>? ?? [])
        .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => 0); // l'ordre vient déjà du .order('position') côté requête
    return Quiz(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      questions: questions,
    );
  }
}

class LiveQuizSession {
  final String id;
  final String quizId;
  final String status;
  final DateTime startedAt;

  const LiveQuizSession({
    required this.id,
    required this.quizId,
    required this.status,
    required this.startedAt,
  });

  factory LiveQuizSession.fromMap(Map<String, dynamic> map) {
    return LiveQuizSession(
      id: map['id'] as String,
      quizId: map['quiz_id'] as String,
      status: map['status'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
    );
  }
}
