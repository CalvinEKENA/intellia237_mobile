import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/domain/notebooklm_import.dart';
import 'package:intellia237/features/admin/presentation/notebooklm_import_wizard_screen.dart';

/// L'assistant conduit l'auteur des fichiers à l'import, sans jamais publier.
void main() {
  const audio = NotebookArtifact(
    fileName: 'photosynthese.mp3',
    mimeType: 'audio/mpeg',
    sizeBytes: 4 * 1024 * 1024,
    durationSeconds: 240,
  );
  const infographie = NotebookArtifact(
    fileName: 'schema.png',
    mimeType: 'image/png',
    sizeBytes: 512 * 1024,
  );
  const diaporama = NotebookArtifact(
    fileName: 'slides.pptx',
    mimeType: 'application/vnd.ms-ppt',
    sizeBytes: 2 * 1024 * 1024,
  );

  Future<void> pumpWizard(
    WidgetTester tester,
    List<NotebookArtifact> artifacts,
  ) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: NotebookLmImportWizardScreen(
            classLevel: 'terminale',
            artifacts: artifacts,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('sans fichier, on ne peut pas avancer', (tester) async {
    await pumpWizard(tester, const []);

    expect(find.byKey(const ValueKey('notebook-files-empty')), findsOneWidget);
    final next = tester.widget<FilledButton>(
      find.byKey(const ValueKey('notebook-next')),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('les fichiers acceptés et refusés sont distingués', (
    tester,
  ) async {
    await pumpWizard(tester, const [audio, diaporama]);

    expect(
      find.byKey(const ValueKey('notebook-accepted-photosynthese.mp3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notebook-rejected-slides.pptx')),
      findsOneWidget,
    );
  });

  testWidgets('un fichier refusé n’empêche pas d’avancer', (tester) async {
    await pumpWizard(tester, const [audio, diaporama]);

    final next = tester.widget<FilledButton>(
      find.byKey(const ValueKey('notebook-next')),
    );
    expect(next.onPressed, isNotNull);
  });

  testWidgets('la matière est requise pour classer', (tester) async {
    await pumpWizard(tester, const [audio]);

    await tester.tap(find.byKey(const ValueKey('notebook-next')));
    await tester.pumpAndSettle();

    // Étape de classement : sans matière, on ne continue pas.
    final next = tester.widget<FilledButton>(
      find.byKey(const ValueKey('notebook-next')),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('le parcours complet aboutit à un brouillon', (tester) async {
    await pumpWizard(tester, const [audio, infographie]);

    // 1 — fichiers
    await tester.tap(find.byKey(const ValueKey('notebook-next')));
    await tester.pumpAndSettle();

    // 2 — classement
    await tester.enterText(
      find.byKey(const ValueKey('notebook-subject')),
      'svt',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('notebook-next')));
    await tester.pumpAndSettle();

    // 3 — provenance
    await tester.enterText(
      find.byKey(const ValueKey('notebook-id')),
      'nb-photosynthese',
    );
    await tester.tap(find.byKey(const ValueKey('notebook-next')));
    await tester.pumpAndSettle();

    // 4 — aperçu : deux blocs annoncés
    expect(
      find.byKey(const ValueKey('notebook-preview-count')),
      findsOneWidget,
    );
    expect(find.textContaining('2 bloc'), findsOneWidget);

    // 5 — import
    await tester.tap(find.byKey(const ValueKey('notebook-import')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notebook-outcome')), findsOneWidget);
    // Rien n'est publié : le brouillon est dit explicitement.
    expect(find.byKey(const ValueKey('notebook-draft-notice')), findsOneWidget);
  });

  testWidgets('retirer un fichier met l’aperçu à jour', (tester) async {
    await pumpWizard(tester, const [audio, infographie]);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('notebook-accepted-schema.png')),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('notebook-accepted-schema.png')),
      findsNothing,
    );
  });
}
