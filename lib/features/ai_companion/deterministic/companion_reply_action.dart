import 'package:flutter/foundation.dart';

/// Ce qu'une action ouvre ou envoie. Tout pointe vers un contenu réellement
/// présent sur l'appareil ; rien n'est généré.
enum CompanionActionKind {
  /// Un quiz de pack (séquence ou révision mixte), dans un mode donné.
  openQuiz,

  /// Une matière dans Apprendre.
  openSubject,

  /// Une séquence (et, si connue, une leçon).
  openChapter,

  /// Toutes les matières (Apprendre).
  showSubjects,

  /// Tous les quiz.
  showQuizzes,

  /// Un message envoyé au compagnon (ex. le nom d'une matière).
  reply,
}

/// Libellé de l'action, traduit par l'interface (fichiers ARB).
enum CompanionActionLabel {
  continueLearning,
  takeQuiz,
  seeSubjects,
  seeAllQuizzes,
  subject,
  subjectQuiz,
  learnSubject,
  training,
  evaluation,
  openCourse,
  topicQuiz,
  reviewSubject,
  diagnostic,
  progress,
  go,
  retryQuiz,
  trainTopic,
  continueCourse,
  resume,
  resumeLesson,
  practice,
}

@immutable
class CompanionReplyAction {
  const CompanionReplyAction({
    required this.kind,
    required this.label,
    this.subjectKey,
    this.subjectTitle,
    this.setId,
    this.mode,
    this.contentId,
    this.lesson,
    this.reply,
  });

  final CompanionActionKind kind;
  final CompanionActionLabel label;
  final String? subjectKey;

  /// Nom affiché de la matière (titre du catalogue).
  final String? subjectTitle;

  /// Quiz de pack visé et son mode (`training`, `evaluation`).
  final String? setId;
  final String? mode;
  final String? contentId;
  final int? lesson;

  /// Texte envoyé pour [CompanionActionKind.reply].
  final String? reply;

  Map<String, Object> toJson() => {
    'kind': kind.name,
    'label': label.name,
    'subjectKey': ?subjectKey,
    'subjectTitle': ?subjectTitle,
    'setId': ?setId,
    'mode': ?mode,
    'contentId': ?contentId,
    'lesson': ?lesson,
    'reply': ?reply,
  };

  static CompanionReplyAction? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = CompanionActionKind.values
        .where((k) => k.name == raw['kind'])
        .firstOrNull;
    final label = CompanionActionLabel.values
        .where((l) => l.name == raw['label'])
        .firstOrNull;
    if (kind == null || label == null) return null;
    String? text(String key) => raw[key] is String ? raw[key] as String : null;
    return CompanionReplyAction(
      kind: kind,
      label: label,
      subjectKey: text('subjectKey'),
      subjectTitle: text('subjectTitle'),
      setId: text('setId'),
      mode: text('mode'),
      contentId: text('contentId'),
      lesson: raw['lesson'] is int ? raw['lesson'] as int : null,
      reply: text('reply'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CompanionReplyAction &&
      other.kind == kind &&
      other.label == label &&
      other.subjectKey == subjectKey &&
      other.setId == setId &&
      other.mode == mode &&
      other.contentId == contentId &&
      other.lesson == lesson &&
      other.reply == reply;

  @override
  int get hashCode => Object.hash(
    kind,
    label,
    subjectKey,
    setId,
    mode,
    contentId,
    lesson,
    reply,
  );
}
