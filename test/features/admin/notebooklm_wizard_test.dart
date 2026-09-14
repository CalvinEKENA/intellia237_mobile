import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/application/admin_content_providers.dart';
import 'package:intellia237/features/admin/application/notebook_import_service.dart';
import 'package:intellia237/features/admin/data/educational_media_service.dart';
import 'package:intellia237/features/admin/domain/admin_content_models.dart';
import 'package:intellia237/features/admin/domain/content_block.dart';
import 'package:intellia237/features/admin/domain/educational_media.dart';
import 'package:intellia237/features/admin/presentation/notebooklm_import_wizard_screen.dart';

class _FakeMediaProvider implements EducationalMediaProvider {
  @override
  Future<MediaUploadResult> upload({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async => MediaUploadResult(
    storagePath: storagePath,
    sizeBytes: bytes.lengthInBytes,
    mimeType: mimeType,
  );

  @override
  Future<String> resolveUrl(String storagePath) async =>
      'https://x/$storagePath';

  @override
  Future<void> delete(String storagePath) async {}
}

/// Enregistre la leçon sauvegardée sans toucher à Firebase.
class _RecordingContentActions extends AdminContentActions {
  _RecordingContentActions(super.ref);
  AdminLessonModel? saved;
  @override
  Future<void> saveLesson(AdminLessonModel lesson) async {
    saved = lesson;
  }
}

AdminLessonModel _draftLesson() => const AdminLessonModel(
  id: 'lesson-1',
  subjectId: 'svt',
  chapterId: 'chap-1',
  classLevel: 'Terminale',
  title: 'Photosynthèse',
  summary: '',
  estimatedMinutes: 20,
  order: 0,
  status: 'draft',
  contentSections: [],
  miniQuiz: [],
);

Uint8List _bytes(int n) => Uint8List.fromList(List.filled(n, 1));

void main() {
  testWidgets('no target lesson shows honest guidance, never a fake success', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NotebookLmImportWizardScreen(classLevel: 'Terminale'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('notebook-no-lesson')), findsOneWidget);
    // Le faux message de la version précédente ne doit plus exister nulle part.
    expect(find.textContaining('Aucun fichier enregistré'), findsNothing);
  });

  testWidgets('real import uploads files, attaches blocks and saves a draft', (
    tester,
  ) async {
    late _RecordingContentActions actions;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          educationalMediaProviderProvider.overrideWithValue(
            _FakeMediaProvider(),
          ),
          adminContentActionsProvider.overrideWith((ref) {
            actions = _RecordingContentActions(ref);
            return actions;
          }),
        ],
        child: MaterialApp(
          home: NotebookLmImportWizardScreen(
            classLevel: 'Terminale',
            targetLesson: _draftLesson(),
            initialFiles: [
              PickedNotebookFile(
                name: 'audio.mp3',
                bytes: _bytes(1024),
                mimeType: 'audio/mpeg',
              ),
              PickedNotebookFile(
                name: 'schema.png',
                bytes: _bytes(2048),
                mimeType: 'image/png',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    // Les deux fichiers injectés sont acceptés et l'import est possible.
    expect(
      find.byKey(const ValueKey('notebook-accepted-audio.mp3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notebook-accepted-schema.png')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('notebook-import')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Persistance réelle : la leçon brouillon est sauvegardée avec 2 blocs.
    expect(actions.saved, isNotNull);
    expect(actions.saved!.effectiveBlocks.whereType<MediaBlock>().length, 2);
    expect(actions.saved!.isPublished, isFalse);
    // Vrai succès (jamais le faux message).
    expect(find.byKey(const ValueKey('notebook-outcome')), findsOneWidget);
    expect(find.byKey(const ValueKey('notebook-draft-notice')), findsOneWidget);
    expect(find.textContaining('Aucun fichier enregistré'), findsNothing);
  });

  testWidgets('an unsupported file is shown as rejected', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: NotebookLmImportWizardScreen(
            classLevel: 'Terminale',
            targetLesson: _draftLesson(),
            initialFiles: [
              PickedNotebookFile(
                name: 'slides.pptx',
                bytes: _bytes(64),
                mimeType: 'application/vnd.ms-ppt',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('notebook-rejected-slides.pptx')),
      findsOneWidget,
    );
    // Sans fichier accepté, l'import est désactivé.
    final importButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('notebook-import')),
    );
    expect(importButton.onPressed, isNull);
  });
}
