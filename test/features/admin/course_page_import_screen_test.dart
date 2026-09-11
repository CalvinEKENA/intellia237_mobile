import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/application/admin_content_providers.dart';
import 'package:intellia237/features/admin/application/flow_composer_providers.dart';
import 'package:intellia237/features/admin/data/course_page_import_service.dart';
import 'package:intellia237/features/admin/domain/admin_content_models.dart';
import 'package:intellia237/features/admin/domain/content_permissions.dart';
import 'package:intellia237/features/admin/domain/content_scope.dart';
import 'package:intellia237/features/admin/domain/course_page_import.dart';
import 'package:intellia237/features/admin/presentation/course_page_import_screen.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/flow/domain/flow_item.dart';

/// Des pages de cours photographiées deviennent des brouillons après
/// relecture : rien n'est lu sans droits déclarés, rien n'est publié.
void main() {
  const chapter = AdminChapterModel(
    id: 'derivees',
    subjectId: 'maths-terminale',
    classLevel: 'Terminale',
    title: 'Dérivées',
    description: '',
    order: 0,
    lessonsCount: 0,
  );

  Future<_FakeImportService> pumpWizard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _FakeImportService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coursePageImportServiceProvider.overrideWithValue(service),
          contentActorProvider.overrideWithValue(
            const ContentActor(
              uid: 'root',
              role: AppRole.admin,
              unrestricted: true,
            ),
          ),
          adminFlowRepositoryProvider.overrideWithValue(_NoFlowRepository()),
          adminSubjectsProvider.overrideWith(
            (ref, classLevel) async => const [
              AdminSubjectModel(
                id: 'maths-terminale',
                classLevel: 'Terminale',
                title: 'Mathématiques',
                description: '',
                colorHex: 0xFF1E3A8A,
                iconKey: 'calculate',
                order: 0,
                status: 'published',
                chapterCount: 1,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: CoursePageImportScreen(
            chapter: chapter,
            initialPages: [
              CoursePageFile(
                name: 'cours.pdf',
                bytes: Uint8List(2048),
                mimeType: 'application/pdf',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return service;
  }

  testWidgets('aucune page n’est lue sans droits déclarés', (tester) async {
    final service = await pumpWizard(tester);

    final read = find.byKey(const ValueKey('page-import-read'));
    expect(tester.widget<FilledButton>(read).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('page-import-rights')));
    await tester.pump();
    expect(tester.widget<FilledButton>(read).onPressed, isNotNull);
    expect(service.readPages, isEmpty);
  });

  testWidgets('les pages relues deviennent des brouillons, sans rien publier', (
    tester,
  ) async {
    final service = await pumpWizard(tester);

    await tester.tap(find.byKey(const ValueKey('page-import-rights')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('page-import-read')));
    await tester.pumpAndSettle();

    expect(service.readPages, hasLength(1));
    expect(
      find.byKey(const ValueKey('page-import-lesson-title')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('page-import-warnings')), findsOneWidget);

    // L'auteur écarte le premier exercice avant de créer.
    final exercise = find.byKey(
      const ValueKey('page-import-exercise-0-include'),
    );
    await tester.scrollUntilVisible(
      exercise,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(exercise);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('page-import-create')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('page-import-done')), findsOneWidget);
    expect(service.created!.exercises.first.include, isFalse);
    expect(service.created!.exercises.last.include, isTrue);
    // La matière FLOW se déduit de l'intitulé du catalogue.
    expect(service.flowSubject, 'maths');
  });
}

class _FakeImportService implements CoursePageImportService {
  List<CoursePageFile> readPages = const [];
  CoursePageImportDraft? created;
  String? flowSubject;

  @override
  Future<CoursePageImportDraft> read({
    required ContentScope scope,
    required String classLevel,
    required String subjectId,
    required String subjectLabel,
    required String chapterTitle,
    required List<CoursePageFile> pages,
    String language = 'fr',
    void Function(int uploaded, int total)? onUploaded,
  }) async {
    readPages = pages;
    onUploaded?.call(pages.length, pages.length);
    return CoursePageImportDraft.fromCallable({
      'lesson': {
        'title': 'Dérivée d’une fonction',
        'summary': 'La dérivée mesure une variation instantanée.',
        'estimatedMinutes': 20,
        'sections': [
          {'title': 'Définition', 'body': 'f′(a) est la limite du taux.'},
        ],
      },
      'quizQuestions': [
        {
          'prompt': 'Dérivée de x² ?',
          'options': ['2x', 'x'],
          'correctOptionIndex': 0,
        },
      ],
      'exercises': [
        {'statement': 'Dériver 3x².', 'solution': '6x'},
        {'statement': 'Dériver 5x.', 'solution': '5'},
      ],
      'flowCards': [
        {'type': 'notion', 'title': 'Tangente', 'insight': 'Pente.'},
      ],
      'warnings': ['Page 1 un peu floue.'],
    });
  }

  @override
  Future<CoursePageImportOutcome> createDrafts({
    required CoursePageImportDraft draft,
    required AdminChapterModel chapter,
    required String subjectLabel,
    required String flowSubjectId,
    required ContentScope scope,
    required String authorUid,
    required int pageCount,
    required AdminContentActions contentActions,
    required AdminFlowRepository flowRepository,
  }) async {
    created = draft;
    flowSubject = flowSubjectId;
    return const CoursePageImportOutcome(
      lessonId: 'lecon-1',
      quizCreated: true,
      flowItemsCreated: 2,
    );
  }
}

class _NoFlowRepository implements AdminFlowRepository {
  @override
  Future<List<FlowItem>> listForClass(String classLevel) async => const [];

  @override
  Future<String> save(FlowItem item) async => 'flow-item';

  @override
  Future<void> delete(String id) async {}
}
