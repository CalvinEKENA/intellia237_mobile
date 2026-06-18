import 'package:flutter/material.dart';

import '../../learn/domain/learn_lesson.dart';
import '../../quiz/domain/quiz_question.dart';
import '../../quiz/domain/quiz_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constantes globales
// ─────────────────────────────────────────────────────────────────────────────

const kAllClassLevels = <String>[
  '6eme',
  '5eme',
  '4eme',
  '3eme',
  'Seconde',
  'Premiere',
  'Terminale',
];

const kSeriesByClass = <String, List<String>>{
  'Premiere': ['A', 'C', 'D', 'TI'],
  'Terminale': ['A', 'C', 'D', 'TI'],
};

/// Icônes disponibles pour les matières (clé → IconData)
const kSubjectIconOptions = <String, IconData>{
  'math': Icons.calculate_rounded,
  'french': Icons.menu_book_rounded,
  'physic': Icons.science_rounded,
  'english': Icons.language_rounded,
  'history': Icons.public_rounded,
  'biology': Icons.biotech_rounded,
  'philosophy': Icons.lightbulb_rounded,
  'economics': Icons.bar_chart_rounded,
  'computer': Icons.computer_rounded,
  'book': Icons.book_rounded,
};

/// Couleurs disponibles pour les matières (in colorHex)
const kSubjectColorOptions = <int>[
  0xFF1451E1,
  0xFF7C3AED,
  0xFF0F766E,
  0xFF0EA5E9,
  0xFFB45309,
  0xFF059669,
  0xFFDC2626,
  0xFFD97706,
  0xFF6366F1,
  0xFFEC4899,
];

// ─────────────────────────────────────────────────────────────────────────────
// AdminSubjectModel
// ─────────────────────────────────────────────────────────────────────────────

class AdminSubjectModel {
  const AdminSubjectModel({
    required this.id,
    required this.classLevel,
    required this.title,
    required this.description,
    required this.colorHex,
    required this.iconKey,
    required this.order,
    required this.status,
    required this.chapterCount,
    this.allowedSeries = const [],
  });

  final String id;
  final String classLevel;
  final String title;
  final String description;
  final int colorHex;
  final String iconKey;
  final int order;
  final String status; // 'draft' | 'published'
  final int chapterCount;
  final List<String> allowedSeries;

  bool get isPublished => status == 'published';

  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'title': title,
    'description': description,
    'colorHex': colorHex,
    'iconKey': iconKey,
    'order': order,
    'status': status,
    'allowedSeries': allowedSeries,
  };

  factory AdminSubjectModel.fromFirestore(
    String id,
    String classLevel,
    Map<String, dynamic> data,
    int chapterCount,
  ) => AdminSubjectModel(
    id: id,
    classLevel: classLevel,
    title: data['title'] as String? ?? '',
    description: data['description'] as String? ?? '',
    colorHex: (data['colorHex'] as int?) ?? 0xFF1451E1,
    iconKey: data['iconKey'] as String? ?? 'book',
    order: (data['order'] as int?) ?? 0,
    status: data['status'] as String? ?? 'draft',
    chapterCount: chapterCount,
    allowedSeries: List<String>.from(data['allowedSeries'] as List? ?? []),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminChapterModel
// ─────────────────────────────────────────────────────────────────────────────

class AdminChapterModel {
  const AdminChapterModel({
    required this.id,
    required this.subjectId,
    required this.classLevel,
    required this.title,
    required this.description,
    required this.order,
    required this.lessonsCount,
  });

  final String id;
  final String subjectId;
  final String classLevel;
  final String title;
  final String description;
  final int order;
  final int lessonsCount;

  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'title': title,
    'description': description,
    'order': order,
    'lessonsCount': lessonsCount,
  };

  factory AdminChapterModel.fromFirestore(
    String id,
    String subjectId,
    String classLevel,
    Map<String, dynamic> data,
  ) => AdminChapterModel(
    id: id,
    subjectId: subjectId,
    classLevel: classLevel,
    title: data['title'] as String? ?? '',
    description: data['description'] as String? ?? '',
    order: (data['order'] as int?) ?? 0,
    lessonsCount: (data['lessonsCount'] as int?) ?? 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminLessonModel
// ─────────────────────────────────────────────────────────────────────────────

class AdminLessonModel {
  const AdminLessonModel({
    required this.id,
    required this.subjectId,
    required this.chapterId,
    required this.classLevel,
    required this.title,
    required this.summary,
    required this.estimatedMinutes,
    required this.order,
    required this.status,
    required this.contentSections,
    required this.miniQuiz,
    this.aiGenerated = false,
  });

  final String id;
  final String subjectId;
  final String chapterId;
  final String classLevel;
  final String title;
  final String summary;
  final int estimatedMinutes;
  final int order;
  final String status; // 'draft' | 'published' | 'ai_generated'
  final List<LessonContentSection> contentSections;
  final List<LessonMiniQuizQuestion> miniQuiz;
  final bool aiGenerated;

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isAiGenerated => status == 'ai_generated' || aiGenerated;

  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'title': title,
    'summary': summary,
    'estimatedMinutes': estimatedMinutes,
    'order': order,
    'status': status,
    'aiGenerated': aiGenerated,
    'contentSections': contentSections
        .map((s) => {'title': s.title, 'body': s.body})
        .toList(),
    'miniQuiz': miniQuiz
        .map(
          (q) => {
            'id': q.id,
            'prompt': q.prompt,
            'options': q.options,
            'correctIndex': q.correctIndex,
            'explanation': q.explanation,
          },
        )
        .toList(),
  };

  factory AdminLessonModel.fromFirestore(
    String id,
    String subjectId,
    String chapterId,
    String classLevel,
    Map<String, dynamic> data,
  ) {
    final sections = (data['contentSections'] as List<dynamic>? ?? []).map((s) {
      final m = s as Map<String, dynamic>;
      return LessonContentSection(
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
      );
    }).toList();

    final miniQuiz = (data['miniQuiz'] as List<dynamic>? ?? []).map((q) {
      final m = q as Map<String, dynamic>;
      return LessonMiniQuizQuestion(
        id: m['id'] as String? ?? '',
        prompt: m['prompt'] as String? ?? '',
        options: List<String>.from(m['options'] as List? ?? []),
        correctIndex: (m['correctIndex'] as int?) ?? 0,
        explanation: m['explanation'] as String? ?? '',
      );
    }).toList();

    return AdminLessonModel(
      id: id,
      subjectId: subjectId,
      chapterId: chapterId,
      classLevel: classLevel,
      title: data['title'] as String? ?? '',
      summary: data['summary'] as String? ?? '',
      estimatedMinutes: (data['estimatedMinutes'] as int?) ?? 20,
      order: (data['order'] as int?) ?? 0,
      status: data['status'] as String? ?? 'draft',
      contentSections: sections,
      miniQuiz: miniQuiz,
      aiGenerated: data['aiGenerated'] as bool? ?? false,
    );
  }

  AdminLessonModel copyWith({
    String? title,
    String? summary,
    int? estimatedMinutes,
    String? status,
    List<LessonContentSection>? contentSections,
    List<LessonMiniQuizQuestion>? miniQuiz,
    bool? aiGenerated,
  }) => AdminLessonModel(
    id: id,
    subjectId: subjectId,
    chapterId: chapterId,
    classLevel: classLevel,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    order: order,
    status: status ?? this.status,
    contentSections: contentSections ?? this.contentSections,
    miniQuiz: miniQuiz ?? this.miniQuiz,
    aiGenerated: aiGenerated ?? this.aiGenerated,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminQuizModel
// ─────────────────────────────────────────────────────────────────────────────

class AdminQuizModel {
  const AdminQuizModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectLabel,
    required this.description,
    required this.difficultyLabel,
    required this.classLevels,
    required this.status,
    required this.questions,
    this.series = const [],
    this.timerSeconds,
    this.sourceLessonId,
    this.aiGenerated = false,
  });

  final String id;
  final String title;
  final String subjectId;
  final String subjectLabel;
  final String description;
  final String difficultyLabel;
  final List<String> classLevels;
  final List<String> series;
  final String status; // 'draft' | 'published' | 'ai_generated'
  final List<QuizQuestion> questions;
  final int? timerSeconds;
  final String? sourceLessonId;
  final bool aiGenerated;

  bool get isPublished => status == 'published';

  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'title': title,
    'subjectId': subjectId,
    'subjectLabel': subjectLabel,
    'description': description,
    'difficultyLabel': difficultyLabel,
    'classLevels': classLevels,
    'series': series,
    'timerSeconds': timerSeconds,
    'status': status,
    'aiGenerated': aiGenerated,
    'sourceLessonId': sourceLessonId,
    'questions': questions
        .map(
          (q) => {
            'id': q.id,
            'type': q.type.name,
            'prompt': q.prompt,
            'options': q.options,
            'correctOptionIndex': q.correctOptionIndex,
            'correctBooleanValue': q.correctBooleanValue,
            'acceptedAnswers': q.acceptedAnswers,
            'explanation': q.explanation,
            'xpReward': q.xpReward,
          },
        )
        .toList(),
  };

  factory AdminQuizModel.fromFirestore(String id, Map<String, dynamic> data) {
    final rawQ = data['questions'] as List<dynamic>? ?? [];
    final questions = rawQ.map((q) {
      final m = q as Map<String, dynamic>;
      final typeStr = m['type'] as String?;
      final type = switch (typeStr) {
        'trueFalse' => QuizQuestionType.trueFalse,
        'shortAnswer' => QuizQuestionType.shortAnswer,
        _ => QuizQuestionType.qcm,
      };
      return QuizQuestion(
        id: m['id'] as String? ?? '',
        type: type,
        prompt: m['prompt'] as String? ?? '',
        options: List<String>.from(m['options'] as List? ?? []),
        correctOptionIndex: m['correctOptionIndex'] as int?,
        correctBooleanValue: m['correctBooleanValue'] as bool?,
        acceptedAnswers: List<String>.from(m['acceptedAnswers'] as List? ?? []),
        explanation: m['explanation'] as String? ?? '',
        xpReward: (m['xpReward'] as int?) ?? 10,
      );
    }).toList();

    return AdminQuizModel(
      id: id,
      title: data['title'] as String? ?? '',
      subjectId: data['subjectId'] as String? ?? '',
      subjectLabel: data['subjectLabel'] as String? ?? '',
      description: data['description'] as String? ?? '',
      difficultyLabel: data['difficultyLabel'] as String? ?? 'Intermédiaire',
      classLevels: List<String>.from(data['classLevels'] as List? ?? []),
      series: List<String>.from(data['series'] as List? ?? []),
      timerSeconds: data['timerSeconds'] as int?,
      status: data['status'] as String? ?? 'draft',
      aiGenerated: data['aiGenerated'] as bool? ?? false,
      sourceLessonId: data['sourceLessonId'] as String?,
      questions: questions,
    );
  }
}
