/// Quiz studio domain models for teacher quiz creation and drafts.
library;

enum QuizPurpose { revision, diagnostic, homework }

enum QuizDifficulty { accessible, standard, challenging }

class CampusQuizQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const CampusQuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  CampusQuizQuestion copyWith({
    String? id,
    String? prompt,
    List<String>? options,
    int? correctOptionIndex,
    String? explanation,
  }) {
    return CampusQuizQuestion(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      explanation: explanation ?? this.explanation,
    );
  }
}

class CampusQuizDraft {
  final String id;
  final String establishmentId;
  final String classId;
  final String className;
  final String subjectName;
  final String chapterTitle;
  final QuizPurpose purpose;
  final QuizDifficulty difficulty;
  final List<CampusQuizQuestion> questions;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? publishedAt;

  const CampusQuizDraft({
    required this.id,
    required this.establishmentId,
    required this.classId,
    required this.className,
    required this.subjectName,
    required this.chapterTitle,
    required this.purpose,
    required this.difficulty,
    required this.questions,
    this.isPublished = false,
    required this.createdAt,
    this.publishedAt,
  });

  bool get isDraft => !isPublished;

  CampusQuizDraft copyWith({
    String? id,
    String? establishmentId,
    String? classId,
    String? className,
    String? subjectName,
    String? chapterTitle,
    QuizPurpose? purpose,
    QuizDifficulty? difficulty,
    List<CampusQuizQuestion>? questions,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? publishedAt,
  }) {
    return CampusQuizDraft(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectName: subjectName ?? this.subjectName,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      purpose: purpose ?? this.purpose,
      difficulty: difficulty ?? this.difficulty,
      questions: questions ?? this.questions,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
