import 'dart:typed_data';

import '../../flow/domain/flow_item.dart';
import '../../flow/domain/flow_subject.dart';
import '../../learn/domain/learn_lesson.dart';
import '../../quiz/domain/quiz_mode.dart';
import '../../quiz/domain/quiz_question.dart';
import '../../quiz/domain/quiz_type.dart';
import 'admin_content_models.dart';
import 'content_scope.dart';

/// Une page de cours à lire : photo ou document, dans l'ordre du cours.
class CoursePageFile {
  const CoursePageFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;

  bool get isPdf => mimeType == 'application/pdf';
}

class PageLessonSectionDraft {
  PageLessonSectionDraft({required this.title, required this.body});

  String title;
  String body;
}

class PageQuizQuestionDraft {
  PageQuizQuestionDraft({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  String prompt;
  final List<String> options;
  int correctIndex;
  String explanation;
  bool include = true;
}

class PageExerciseDraft {
  PageExerciseDraft({
    required this.statement,
    required this.solution,
    required this.difficulty,
  });

  String statement;
  String solution;
  int difficulty;
  bool include = true;
}

enum PageFlowCardKind { notion, question, quiz }

class PageFlowCardDraft {
  PageFlowCardDraft({
    required this.kind,
    required this.title,
    this.hook = '',
    this.insight = '',
    List<String>? points,
    this.question = '',
    this.answer = '',
    List<String>? options,
    this.correctIndex = 0,
    this.explanation = '',
  }) : points = points ?? <String>[],
       options = options ?? <String>[];

  final PageFlowCardKind kind;
  String title;
  String hook;
  String insight;
  final List<String> points;
  String question;
  String answer;
  final List<String> options;
  int correctIndex;
  String explanation;
  bool include = true;
}

/// Ce que Gemini a lu dans les pages, tel que l'auteur le relit.
///
/// Registre de décisions : rien n'existe encore dans le Studio à ce stade.
/// L'auteur corrige, écarte, puis crée des brouillons ; aucun contenu n'atteint
/// un élève sans son geste de publication.
class CoursePageImportDraft {
  CoursePageImportDraft({
    required this.lessonTitle,
    required this.lessonSummary,
    required this.estimatedMinutes,
    required this.sections,
    required this.quizQuestions,
    required this.exercises,
    required this.flowCards,
    required this.warnings,
  });

  String lessonTitle;
  String lessonSummary;
  int estimatedMinutes;
  final List<PageLessonSectionDraft> sections;
  final List<PageQuizQuestionDraft> quizQuestions;
  final List<PageExerciseDraft> exercises;
  final List<PageFlowCardDraft> flowCards;
  final List<String> warnings;

  bool includeLesson = true;

  /// Les QCM rejoignent la leçon (mini-quiz de fin de cours)…
  bool attachQuizToLesson = true;

  /// … et le hub Quiz, en mode entraînement.
  bool addQuizToHub = true;

  factory CoursePageImportDraft.fromCallable(Map<String, dynamic> data) {
    String text(Object? value) => value is String ? value.trim() : '';
    int integer(Object? value, int fallback) =>
        value is num ? value.toInt() : fallback;
    List<String> strings(Object? value) => [
      if (value is List)
        for (final entry in value)
          if (entry is String && entry.trim().isNotEmpty) entry.trim(),
    ];
    List<Map<String, dynamic>> maps(Object? value) => [
      if (value is List)
        for (final entry in value)
          if (entry is Map) Map<String, dynamic>.from(entry),
    ];
    final lesson = data['lesson'] is Map
        ? Map<String, dynamic>.from(data['lesson'] as Map)
        : const <String, dynamic>{};

    return CoursePageImportDraft(
      lessonTitle: text(lesson['title']),
      lessonSummary: text(lesson['summary']),
      estimatedMinutes: integer(lesson['estimatedMinutes'], 20).clamp(5, 120),
      sections: [
        for (final section in maps(lesson['sections']))
          if (text(section['body']).isNotEmpty)
            PageLessonSectionDraft(
              title: text(section['title']),
              body: text(section['body']),
            ),
      ],
      quizQuestions: [
        for (final question in maps(data['quizQuestions']))
          PageQuizQuestionDraft(
            prompt: text(question['prompt']),
            options: strings(question['options']),
            correctIndex: integer(question['correctOptionIndex'], -1),
            explanation: text(question['explanation']),
          ),
      ],
      exercises: [
        for (final exercise in maps(data['exercises']))
          PageExerciseDraft(
            statement: text(exercise['statement']),
            solution: text(exercise['solution']),
            difficulty: integer(exercise['difficulty'], 3).clamp(1, 5),
          ),
      ],
      flowCards: [
        for (final card in maps(data['flowCards']))
          if (PageFlowCardKind.values.any((kind) => kind.name == card['type']))
            PageFlowCardDraft(
              kind: PageFlowCardKind.values.byName(card['type'] as String),
              title: text(card['title']),
              hook: text(card['hook']),
              insight: text(card['insight']),
              points: strings(card['points']),
              question: text(card['question']),
              answer: text(card['answer']),
              options: strings(card['options']),
              correctIndex: integer(card['correctIndex'], -1),
              explanation: text(card['explanation']),
            ),
      ],
      warnings: strings(data['warnings']),
    );
  }
}

/// Transforme une relecture en objets du Studio, sans rien écrire.
///
/// Pur et testable : c'est ici que se garantit que chaque exercice et chaque
/// carte FLOW créés depuis des pages sont réellement présentables à l'élève.
abstract final class CoursePageDraftPlanner {
  static List<LessonContentSection> lessonSections(
    CoursePageImportDraft draft,
  ) => [
    for (final section in draft.sections)
      if (section.body.trim().isNotEmpty)
        LessonContentSection(
          title: section.title.trim(),
          body: section.body.trim(),
        ),
  ];

  static List<PageQuizQuestionDraft> _validQuestions(
    CoursePageImportDraft draft,
  ) => [
    for (final question in draft.quizQuestions)
      if (question.include &&
          question.prompt.trim().isNotEmpty &&
          question.options.length >= 2 &&
          question.correctIndex >= 0 &&
          question.correctIndex < question.options.length)
        question,
  ];

  static List<LessonMiniQuizQuestion> miniQuiz(CoursePageImportDraft draft) {
    final questions = _validQuestions(draft);
    return [
      for (var index = 0; index < questions.length; index++)
        LessonMiniQuizQuestion(
          id: 'q${index + 1}',
          prompt: questions[index].prompt.trim(),
          options: List.unmodifiable(questions[index].options),
          correctIndex: questions[index].correctIndex,
          explanation: questions[index].explanation.trim(),
        ),
    ];
  }

  static AdminQuizModel? quiz({
    required CoursePageImportDraft draft,
    required String classLevel,
    required String subjectId,
    required String subjectLabel,
    String? lessonId,
  }) {
    final questions = _validQuestions(draft);
    if (questions.isEmpty) return null;
    return AdminQuizModel(
      id: '',
      title: _clip('QCM — ${draft.lessonTitle.trim()}', 120),
      subjectId: subjectId,
      subjectLabel: subjectLabel,
      description: draft.lessonSummary.trim(),
      difficultyLabel: adminDifficultyIntermediate,
      classLevels: [classLevel],
      status: 'draft',
      // L'entraînement corrige chaque réponse aussitôt : c'est l'usage d'un
      // QCM tiré d'un cours.
      mode: QuizMode.training,
      sourceLessonId: lessonId,
      aiGenerated: true,
      questions: [
        for (var index = 0; index < questions.length; index++)
          QuizQuestion(
            id: 'q${index + 1}',
            type: QuizQuestionType.qcm,
            prompt: questions[index].prompt.trim(),
            options: List.unmodifiable(questions[index].options),
            correctOptionIndex: questions[index].correctIndex,
            explanation: questions[index].explanation.trim(),
            pointsReward: 10,
          ),
      ],
    );
  }

  /// Exercices et cartes FLOW, en brouillon, pour la classe choisie.
  ///
  /// Un exercice devient une carte « question » : l'élève cherche, puis
  /// découvre le corrigé.
  static List<FlowItem> flowItems({
    required CoursePageImportDraft draft,
    required String classLevel,
    required String flowSubjectId,
    required ContentScope scope,
    required String createdBy,
    String? lessonId,
  }) {
    final lessonTitle = draft.lessonTitle.trim();
    final items = <FlowItem>[];
    var exerciseNumber = 0;

    FlowItem item({
      required FlowItemType type,
      required String title,
      required Map<String, Object?> payload,
      required List<String> tags,
      String hook = '',
      int difficulty = 2,
      int durationSeconds = 45,
    }) => FlowItem(
      id: '',
      type: type,
      title: _clip(title, 120),
      hook: _clip(hook, 200),
      subjectId: flowSubjectId,
      classLevels: [classLevel],
      scope: scope,
      ref: FlowItemRef(lessonId: lessonId),
      payload: payload,
      difficulty: difficulty,
      durationSeconds: durationSeconds,
      origin: 'page_import',
      tags: tags,
      status: 'draft',
      createdBy: createdBy,
    );

    for (final exercise in draft.exercises) {
      if (!exercise.include ||
          exercise.statement.trim().isEmpty ||
          exercise.solution.trim().isEmpty) {
        continue;
      }
      exerciseNumber += 1;
      items.add(
        item(
          type: FlowItemType.question,
          title: 'Exercice $exerciseNumber — $lessonTitle',
          payload: {
            'question': exercise.statement.trim(),
            'answer': exercise.solution.trim(),
          },
          tags: const ['exercice', 'import-pages'],
          difficulty: exercise.difficulty,
          durationSeconds: 120,
        ),
      );
    }

    for (final card in draft.flowCards) {
      if (!card.include || card.title.trim().isEmpty) continue;
      switch (card.kind) {
        case PageFlowCardKind.notion:
          final points = [
            for (final point in card.points)
              if (point.trim().isNotEmpty) point.trim(),
          ];
          if (card.insight.trim().isEmpty && points.isEmpty) continue;
          items.add(
            item(
              type: FlowItemType.notion,
              title: card.title,
              hook: card.hook,
              payload: {
                if (card.insight.trim().isNotEmpty)
                  'insight': card.insight.trim(),
                if (points.isNotEmpty) 'points': points,
              },
              tags: const ['import-pages'],
              durationSeconds: 30,
            ),
          );
        case PageFlowCardKind.question:
          if (card.question.trim().isEmpty || card.answer.trim().isEmpty) {
            continue;
          }
          items.add(
            item(
              type: FlowItemType.question,
              title: card.title,
              payload: {
                'question': card.question.trim(),
                'answer': card.answer.trim(),
              },
              tags: const ['import-pages'],
            ),
          );
        case PageFlowCardKind.quiz:
          if (card.question.trim().isEmpty ||
              card.options.length < 2 ||
              card.correctIndex < 0 ||
              card.correctIndex >= card.options.length) {
            continue;
          }
          items.add(
            item(
              type: FlowItemType.quiz,
              title: card.title,
              payload: {
                'question': card.question.trim(),
                'options': List<String>.unmodifiable(card.options),
                'correctIndex': card.correctIndex,
                if (card.explanation.trim().isNotEmpty)
                  'explanation': card.explanation.trim(),
              },
              tags: const ['import-pages'],
            ),
          );
      }
    }
    return items;
  }

  /// La matière FLOW la plus proche d'un intitulé du catalogue.
  static String flowSubjectIdFor(String subjectTitle) {
    const accents = {
      'à': 'a', 'â': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'î': 'i',
      'ï': 'i', 'ô': 'o', 'ù': 'u', 'û': 'u', 'ç': 'c',
    };
    final folded = [
      for (final char in subjectTitle.toLowerCase().split(''))
        accents[char] ?? char,
    ].join();
    final tokens = folded
        .split(RegExp('[^a-z]+'))
        .where((token) => token.isNotEmpty)
        .toSet();
    bool has(String prefix) => tokens.any((token) => token.startsWith(prefix));

    if (has('math')) return FlowSubjects.maths.id;
    if (has('physi') || has('chimi') || tokens.contains('pc') ||
        tokens.contains('pct')) {
      return FlowSubjects.pc.id;
    }
    if (tokens.contains('svt') || has('biolog') || has('geolog') ||
        (has('vie') && has('terre'))) {
      return FlowSubjects.svt.id;
    }
    if (has('franc')) return FlowSubjects.francais.id;
    if (has('angl') || has('english')) return FlowSubjects.anglais.id;
    if (has('hist') || has('geograph')) return 'histoire_geo';
    if (has('philo')) return FlowSubjects.philo.id;
    return FlowSubjects.all.first.id;
  }

  static String _clip(String value, int max) {
    final trimmed = value.trim();
    return trimmed.length <= max ? trimmed : '${trimmed.substring(0, max - 1)}…';
  }
}
