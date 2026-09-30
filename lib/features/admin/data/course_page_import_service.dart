import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learn/domain/content_block.dart';
import '../application/admin_content_providers.dart';
import '../application/flow_composer_providers.dart';
import '../domain/admin_content_models.dart';
import '../domain/content_origin.dart';
import '../domain/content_scope.dart';
import '../domain/course_page_import.dart';
import '../domain/educational_media.dart';
import 'educational_media_service.dart';

/// Ce que l'import a réellement créé, pour le dire à l'auteur sans arrondi.
class CoursePageImportOutcome {
  const CoursePageImportOutcome({
    this.lessonId,
    this.quizCreated = false,
    this.flowItemsCreated = 0,
    this.failures = const [],
  });

  final String? lessonId;
  final bool quizCreated;
  final int flowItemsCreated;
  final List<String> failures;
}

/// Pages de cours → lecture par Gemini → brouillons du Studio.
///
/// Registre de décisions : les pages sont d'abord déposées dans l'arbre des
/// ressources pédagogiques, sous le périmètre de l'auteur — les règles de
/// stockage font donc la même garde qu'ailleurs. La fonction serveur lit et
/// propose ; elle n'écrit rien. Les brouillons naissent ici, après relecture.
class CoursePageImportService {
  CoursePageImportService({
    required EducationalMediaService media,
    FirebaseFunctions? functions,
  }) : _media = media,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final EducationalMediaService _media;
  final FirebaseFunctions _functions;

  static const maxPages = 12;

  /// Au-delà, la requête dépasserait la limite de lecture en une fois.
  static const maxTotalBytes = 14 * 1024 * 1024;

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
    if (pages.isEmpty || pages.length > maxPages) {
      throw MediaRejectedException(
        'Choisissez de 1 à $maxPages pages à la fois.',
      );
    }
    final totalBytes = pages.fold<int>(
      0,
      (sum, page) => sum + page.bytes.lengthInBytes,
    );
    if (totalBytes > maxTotalBytes) {
      throw MediaRejectedException(
        'Ces pages dépassent 14 Mo ensemble : retirez-en quelques-unes, ou '
        'importez-les en deux fois.',
      );
    }

    final importId = 'pages-${DateTime.now().millisecondsSinceEpoch}';
    final storagePaths = <String>[];
    for (var index = 0; index < pages.length; index++) {
      final page = pages[index];
      final number = (index + 1).toString().padLeft(2, '0');
      final uploaded = await _media.uploadAsset(
        scope: scope,
        classLevel: classLevel,
        subjectId: subjectId,
        lessonId: importId,
        assetId: 'page-$number',
        fileName: 'page-$number.${_extensionFor(page.mimeType)}',
        mediaType: page.isPdf ? MediaType.pdf : MediaType.image,
        bytes: page.bytes,
        mimeType: page.mimeType,
      );
      storagePaths.add(uploaded.storagePath);
      onUploaded?.call(index + 1, pages.length);
    }

    final response = await _functions
        .httpsCallable(
          'importCoursePages',
          options: HttpsCallableOptions(timeout: const Duration(minutes: 3)),
        )
        .call<Object?>({
          'classLevel': classLevel,
          'subjectLabel': subjectLabel.trim().isEmpty
              ? 'Matière'
              : subjectLabel.trim(),
          if (chapterTitle.trim().isNotEmpty)
            'chapterTitle': chapterTitle.trim(),
          'language': language,
          'storagePaths': storagePaths,
          'rightsConfirmed': true,
        });
    return CoursePageImportDraft.fromCallable(_deepMap(response.data));
  }

  /// Crée les brouillons retenus. Chaque échec est rapporté, aucun n'est tu.
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
    final failures = <String>[];

    String? lessonId;
    if (draft.includeLesson) {
      try {
        lessonId = await contentActions.createLesson(
          classLevel: chapter.classLevel,
          subjectId: chapter.subjectId,
          chapterId: chapter.id,
          title: draft.lessonTitle.trim(),
          summary: draft.lessonSummary.trim(),
          estimatedMinutes: draft.estimatedMinutes,
          contentSections: CoursePageDraftPlanner.lessonSections(draft),
          miniQuiz: draft.attachQuizToLesson
              ? CoursePageDraftPlanner.miniQuiz(draft)
              : const [],
          origin: ContentOrigin(
            source: ContentSourceType.pageImport,
            sourceDocumentName: '$pageCount page(s) de cours',
            importedAt: DateTime.now(),
            importedByUid: authorUid,
          ),
        );
      } catch (error) {
        failures.add('Leçon : $error');
      }
    }

    var quizCreated = false;
    if (draft.addQuizToHub) {
      final quiz = CoursePageDraftPlanner.quiz(
        draft: draft,
        classLevel: chapter.classLevel,
        subjectId: chapter.subjectId,
        subjectLabel: subjectLabel,
        lessonId: lessonId,
      );
      if (quiz != null) {
        try {
          await contentActions.saveQuiz(quiz);
          quizCreated = true;
        } catch (error) {
          failures.add('QCM : $error');
        }
      }
    }

    var flowItemsCreated = 0;
    for (final item in CoursePageDraftPlanner.flowItems(
      draft: draft,
      classLevel: chapter.classLevel,
      flowSubjectId: flowSubjectId,
      scope: scope,
      createdBy: authorUid,
      lessonId: lessonId,
    )) {
      try {
        await flowRepository.save(item);
        flowItemsCreated += 1;
      } catch (error) {
        failures.add('Carte de parcours « ${item.title} » : $error');
      }
    }

    return CoursePageImportOutcome(
      lessonId: lessonId,
      quizCreated: quizCreated,
      flowItemsCreated: flowItemsCreated,
      failures: failures,
    );
  }

  static String _extensionFor(String mimeType) => switch (mimeType) {
    'application/pdf' => 'pdf',
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => 'jpg',
  };

  static Map<String, dynamic> _deepMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map<String, dynamic>(
      (key, entry) => MapEntry('$key', _deepValue(entry)),
    );
  }

  static Object? _deepValue(Object? value) => switch (value) {
    Map() => _deepMap(value),
    List() => [for (final entry in value) _deepValue(entry)],
    _ => value,
  };
}

final coursePageImportServiceProvider = Provider<CoursePageImportService>(
  (ref) => CoursePageImportService(
    media: ref.watch(educationalMediaServiceProvider),
  ),
);
