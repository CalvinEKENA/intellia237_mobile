import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/domain/content_scope.dart';
import 'package:intellia237/features/admin/domain/course_page_import.dart';
import 'package:intellia237/features/flow/domain/flow_item.dart';
import 'package:intellia237/features/flow/domain/flow_item_mapper.dart';
import 'package:intellia237/features/quiz/domain/quiz_mode.dart';

/// Des pages de cours deviennent une leçon, des QCM, des exercices et des
/// cartes FLOW. La garantie qui compte : tout ce qui est créé depuis des pages
/// est réellement présentable à l'élève — rien ne disparaît en silence.
void main() {
  CoursePageImportDraft sample() => CoursePageImportDraft.fromCallable({
    'lesson': {
      'title': 'Dérivée d’une fonction',
      'summary': 'La dérivée mesure la variation instantanée.',
      'estimatedMinutes': 25,
      'sections': [
        {'title': 'Définition', 'body': 'f′(a) est la limite du taux.'},
        {'title': 'Vide', 'body': ''},
      ],
    },
    'quizQuestions': [
      {
        'prompt': 'Dérivée de x² ?',
        'options': ['2x', 'x', '2'],
        'correctOptionIndex': 0,
        'explanation': 'On abaisse l’exposant.',
      },
      {
        'prompt': 'Bonne réponse absente',
        'options': ['a', 'b'],
        'correctOptionIndex': 4,
      },
    ],
    'exercises': [
      {'statement': 'Dériver f(x) = 3x² + 2x.', 'solution': 'f′(x) = 6x + 2.'},
      {'statement': 'Sans corrigé', 'solution': ''},
    ],
    'flowCards': [
      {
        'type': 'notion',
        'title': 'Tangente',
        'insight': 'La dérivée est la pente de la tangente.',
        'points': ['Pente', 'Tangente'],
      },
      {
        'type': 'question',
        'title': 'Réflexe',
        'question': 'Dérivée d’une constante ?',
        'answer': '0',
      },
      {
        'type': 'quiz',
        'title': 'Mini-quiz',
        'question': 'Dérivée de 5x ?',
        'options': ['5', 'x', '5x'],
        'correctIndex': 0,
      },
      {'type': 'inconnu', 'title': 'Ignoré'},
    ],
    'warnings': ['Page 2 floue.'],
  });

  test('la relecture reprend fidèlement ce que Gemini a lu', () {
    final draft = sample();

    expect(draft.lessonTitle, 'Dérivée d’une fonction');
    expect(draft.estimatedMinutes, 25);
    expect(draft.sections, hasLength(1));
    expect(draft.quizQuestions, hasLength(2));
    expect(draft.flowCards, hasLength(3));
    expect(draft.warnings, ['Page 2 floue.']);
  });

  test('chaque exercice et chaque carte FLOW créés sont visibles pour '
      'l’élève', () {
    final items = CoursePageDraftPlanner.flowItems(
      draft: sample(),
      classLevel: 'Terminale',
      flowSubjectId: 'maths',
      scope: ContentScope.global,
      createdBy: 'root',
      lessonId: 'lecon-1',
    );

    // Un exercice sans corrigé n'est pas créé ; les autres le sont tous.
    expect(items, hasLength(4));
    for (final item in items) {
      expect(FlowItemMapper.toCard(item), isNotNull, reason: item.title);
      expect(item.status, 'draft');
      expect(item.classLevels, ['Terminale']);
      expect(item.ref.lessonId, 'lecon-1');
    }
    final exercise = items.first;
    expect(exercise.type, FlowItemType.question);
    expect(exercise.tags, contains('exercice'));
    expect(exercise.payload['answer'], 'f′(x) = 6x + 2.');
  });

  test('ce que l’auteur écarte n’est pas créé', () {
    final draft = sample();
    draft.exercises.first.include = false;
    for (final card in draft.flowCards) {
      card.include = false;
    }

    expect(
      CoursePageDraftPlanner.flowItems(
        draft: draft,
        classLevel: 'Terminale',
        flowSubjectId: 'maths',
        scope: ContentScope.global,
        createdBy: 'root',
      ),
      isEmpty,
    );
  });

  test('un QCM sans bonne réponse valide n’entre ni dans la leçon ni au hub', () {
    final draft = sample();
    final quiz = CoursePageDraftPlanner.quiz(
      draft: draft,
      classLevel: 'Terminale',
      subjectId: 'maths-terminale',
      subjectLabel: 'Mathématiques',
      lessonId: 'lecon-1',
    )!;

    expect(CoursePageDraftPlanner.miniQuiz(draft), hasLength(1));
    expect(quiz.questions, hasLength(1));
    expect(quiz.status, 'draft');
    expect(quiz.mode, QuizMode.training);
    expect(quiz.classLevels, ['Terminale']);
    // La bonne réponse reste dans la clé, jamais dans le document public.
    final publicQuestion =
        (quiz.toPublicFirestore()['questions'] as List).single as Map;
    expect(publicQuestion.containsKey('correctOptionIndex'), isFalse);
    final answer =
        (quiz.toAnswerKeyFirestore()['answers'] as List).single as Map;
    expect(answer['correctOptionIndex'], 0);
  });

  test('sans QCM valide, aucun quiz vide n’est créé', () {
    final draft = sample();
    for (final question in draft.quizQuestions) {
      question.include = false;
    }
    expect(
      CoursePageDraftPlanner.quiz(
        draft: draft,
        classLevel: 'Terminale',
        subjectId: 'maths-terminale',
        subjectLabel: 'Mathématiques',
      ),
      isNull,
    );
  });

  test('l’intitulé du catalogue retrouve sa matière FLOW', () {
    expect(CoursePageDraftPlanner.flowSubjectIdFor('Mathématiques'), 'maths');
    expect(
      CoursePageDraftPlanner.flowSubjectIdFor('Physique-Chimie'),
      'pc',
    );
    expect(
      CoursePageDraftPlanner.flowSubjectIdFor(
        'Sciences de la Vie et de la Terre',
      ),
      'svt',
    );
    expect(CoursePageDraftPlanner.flowSubjectIdFor('Français'), 'francais');
    expect(CoursePageDraftPlanner.flowSubjectIdFor('English'), 'anglais');
    expect(
      CoursePageDraftPlanner.flowSubjectIdFor('Histoire-Géographie'),
      'histoire_geo',
    );
    expect(CoursePageDraftPlanner.flowSubjectIdFor('Philosophie'), 'philo');
  });
}
