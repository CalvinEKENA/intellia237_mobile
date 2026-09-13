import '../../learn/domain/content_audience.dart';
import 'package:flutter/material.dart';

import '../../learn/domain/content_block.dart';
import '../../learn/domain/learn_lesson.dart';
import '../../quiz/domain/quiz_question.dart';
import '../../quiz/domain/quiz_mode.dart';
import '../../quiz/domain/quiz_type.dart';
import 'content_origin.dart';
import 'content_scope.dart';
import 'editorial_workflow.dart';

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
  'Form1',
  'Form2',
  'Form3',
  'Form4',
  'Form5',
  'LowerSixth',
  'UpperSixth',
];

const kSeriesByClass = <String, List<String>>{
  'Premiere': ['A', 'C', 'D', 'TI'],
  'Terminale': ['A', 'C', 'D', 'TI'],
};

/// Valeurs historiques persistées. L’interface les traduit avant affichage.
const adminDifficultyBeginner = 'Débutant';
const adminDifficultyIntermediate = 'Intermédiaire';
const adminDifficultyAdvanced = 'Avancé';
const adminDifficultyExpert = 'Expert';
const kAdminQuizDifficultyOptions = <String>[
  adminDifficultyBeginner,
  adminDifficultyIntermediate,
  adminDifficultyAdvanced,
  adminDifficultyExpert,
];

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
    this.audience,
    this.contentBlocks = const [],
    this.schemaVersion = 1,
    this.scope = ContentScope.global,
    this.origin = ContentOrigin.manual,
    this.editorialWorkflow = EditorialWorkflowMetadata.draft,
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
  final ContentAudience? audience;

  // ── V2 Content Studio fields ──────────────────────────────
  final List<ContentBlock> contentBlocks;
  final int schemaVersion;
  final ContentScope scope;
  final ContentOrigin origin;
  final EditorialWorkflowMetadata editorialWorkflow;

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isAiGenerated => status == 'ai_generated' || aiGenerated;
  bool get isV2 => schemaVersion >= 2;

  /// Returns effective content blocks:
  /// Uses [contentBlocks] if populated; otherwise dynamically projects legacy
  /// [contentSections] into [TextBlock]s.
  List<ContentBlock> get effectiveBlocks {
    if (contentBlocks.isNotEmpty) return contentBlocks;
    return ContentBlockAdapter.sectionsToBlocks(contentSections);
  }

  /// Dual-write Firestore serialization.
  /// Always writes both `contentBlocks` (V2) and `contentSections` (V1 projection
  /// of text-only blocks) so older clients never crash or see fake media text.
  Map<String, dynamic> toFirestore() {
    final effectiveContentBlocks = effectiveBlocks;
    final projectedSections = ContentBlockAdapter.blocksToSections(
      effectiveContentBlocks,
    );

    return <String, dynamic>{
      if (audience != null) 'audience': audience!.toFirestore(),
      'title': title,
      'summary': summary,
      'estimatedMinutes': estimatedMinutes,
      'order': order,
      'status': status,
      'aiGenerated': aiGenerated,
      'schemaVersion': effectiveContentBlocks.isNotEmpty ? 2 : schemaVersion,
      // V2 blocks
      'contentBlocks': effectiveContentBlocks
          .map((b) => b.toFirestore())
          .toList(),
      // V1 legacy dual-write (text-only projection)
      'contentSections': projectedSections
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
      'scope': scope.toFirestore(),
      'origin': origin.toFirestore(),
      'editorialWorkflow': editorialWorkflow.toFirestore(),
    };
  }

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

    // V2 content blocks
    final rawBlocks = data['contentBlocks'] as List<dynamic>? ?? [];
    final contentBlocks = rawBlocks.map((b) {
      return ContentBlock.fromFirestore(Map<String, dynamic>.from(b as Map));
    }).toList();

    final schemaVersion = (data['schemaVersion'] as num?)?.toInt() ?? 1;

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
      audience: data['audience'] is Map
          ? ContentAudience.fromFirestore(data['audience'] as Map)
          : null,
      aiGenerated: data['aiGenerated'] as bool? ?? false,
      contentBlocks: contentBlocks,
      schemaVersion: schemaVersion,
      scope: ContentScope.fromFirestore(data['scope']),
      origin: ContentOrigin.fromFirestore(data['origin']),
      editorialWorkflow: EditorialWorkflowMetadata.fromFirestore(
        data['editorialWorkflow'],
        legacyStatus: data['status'] as String?,
      ),
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
    ContentAudience? audience,
    List<ContentBlock>? contentBlocks,
    int? schemaVersion,
    ContentScope? scope,
    ContentOrigin? origin,
    EditorialWorkflowMetadata? editorialWorkflow,
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
    audience: audience ?? this.audience,
    contentBlocks: contentBlocks ?? this.contentBlocks,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    scope: scope ?? this.scope,
    origin: origin ?? this.origin,
    editorialWorkflow: editorialWorkflow ?? this.editorialWorkflow,
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
    this.mode = QuizMode.exam,
    this.series = const [],
    this.audience,
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
  final ContentAudience? audience;
  final String status; // 'draft' | 'published' | 'ai_generated'
  final List<QuizQuestion> questions;
  final QuizMode mode;
  final int? timerSeconds;
  final String? sourceLessonId;
  final bool aiGenerated;

  bool get isPublished => status == 'published';

  Map<String, dynamic> toPublicFirestore() => <String, dynamic>{
    'title': title,
    'subjectId': subjectId,
    'subjectLabel': subjectLabel,
    'description': description,
    'difficultyLabel': difficultyLabel,
    'classLevels': classLevels,
    'series': series,
    if (audience != null) 'audience': audience!.toFirestore(),
    'timerSeconds': timerSeconds,
    'status': status,
    'mode': mode.wireValue,
    'aiGenerated': aiGenerated,
    'sourceLessonId': sourceLessonId,
    'questions': questions
        .map(
          (q) => {
            'id': q.id,
            'type': q.type.name,
            'prompt': q.prompt,
            'options': q.options,
            'pointsReward': q.pointsReward,
          },
        )
        .toList(),
  };

  Map<String, dynamic> toAnswerKeyFirestore() => <String, dynamic>{
    'answers': questions
        .map(
          (q) => <String, dynamic>{
            'id': q.id,
            'correctOptionIndex': q.correctOptionIndex,
            'correctBooleanValue': q.correctBooleanValue,
            'acceptedAnswers': q.acceptedAnswers,
            'explanation': q.explanation,
            'pointsReward': q.pointsReward,
          },
        )
        .toList(),
  };

  factory AdminQuizModel.fromFirestore(
    String id,
    Map<String, dynamic> data, {
    Map<String, dynamic>? answerKeyData,
  }) {
    final answerEntries =
        answerKeyData?['answers'] as List<dynamic>? ?? const [];
    final answerById = <String, Map<String, dynamic>>{
      for (final raw in answerEntries.whereType<Map>())
        if (raw['id'] is String)
          raw['id'] as String: Map<String, dynamic>.from(raw),
    };
    final rawQ = data['questions'] as List<dynamic>? ?? [];
    final questions = rawQ.map((q) {
      final m = q as Map<String, dynamic>;
      final answer = answerById[m['id']] ?? const <String, dynamic>{};
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
        correctOptionIndex:
            (answer['correctOptionIndex'] ?? m['correctOptionIndex']) as int?,
        correctBooleanValue:
            (answer['correctBooleanValue'] ?? m['correctBooleanValue'])
                as bool?,
        acceptedAnswers: List<String>.from(
          (answer['acceptedAnswers'] ?? m['acceptedAnswers']) as List? ?? [],
        ),
        explanation:
            (answer['explanation'] ?? m['explanation']) as String? ?? '',
        pointsReward:
            ((answer['pointsReward'] ??
                        answer['xpReward'] ??
                        m['pointsReward'] ??
                        m['xpReward'])
                    as num?)
                ?.toInt() ??
            10,
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
      audience: data['audience'] is Map
          ? ContentAudience.fromFirestore(data['audience'] as Map)
          : null,
      timerSeconds: data['timerSeconds'] as int?,
      status: data['status'] as String? ?? 'draft',
      aiGenerated: data['aiGenerated'] as bool? ?? false,
      sourceLessonId: data['sourceLessonId'] as String?,
      mode: QuizModeX.fromWireValue(data['mode']),
      questions: questions,
    );
  }
}
