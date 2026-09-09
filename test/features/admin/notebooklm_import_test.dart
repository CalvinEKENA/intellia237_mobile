import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/domain/content_origin.dart';
import 'package:intellia237/features/admin/domain/educational_media.dart';
import 'package:intellia237/features/admin/domain/notebooklm_import.dart';
import 'package:intellia237/features/learn/domain/content_block.dart';

/// NotebookLM est un atelier de production externe : INTELLIA reste le système
/// de validation, de provenance et de publication. On n'importe donc que des
/// formats dont la nature est vérifiable, et rien n'entre publié.
void main() {
  NotebookArtifact artifact({
    String fileName = 'capsule.mp3',
    String mimeType = 'audio/mpeg',
    int sizeBytes = 4 * 1024 * 1024,
    int? durationSeconds,
  }) => NotebookArtifact(
    fileName: fileName,
    mimeType: mimeType,
    sizeBytes: sizeBytes,
    durationSeconds: durationSeconds,
  );

  group('formats acceptés', () {
    test('un Audio Overview entre', () {
      final verdict = NotebookImportPolicy.inspect(artifact());

      expect(verdict.isAccepted, isTrue);
      expect(verdict.kind, NotebookArtifactKind.audioOverview);
    });

    test('une infographie entre', () {
      final verdict = NotebookImportPolicy.inspect(
        artifact(fileName: 'schema.png', mimeType: 'image/png'),
      );

      expect(verdict.kind, NotebookArtifactKind.image);
    });

    test('un PDF entre comme document', () {
      final verdict = NotebookImportPolicy.inspect(
        artifact(fileName: 'fiche.pdf', mimeType: 'application/pdf'),
      );

      expect(verdict.kind, NotebookArtifactKind.document);
    });

    test('une fiche Markdown entre comme texte', () {
      final verdict = NotebookImportPolicy.inspect(
        artifact(
          fileName: 'synthese.md',
          mimeType: 'text/markdown',
          sizeBytes: 4096,
        ),
      );

      expect(verdict.kind, NotebookArtifactKind.markdown);
    });

    test('un format inconnu est refusé, pas deviné', () {
      final verdict = NotebookImportPolicy.inspect(
        artifact(fileName: 'export.pptx', mimeType: 'application/vnd.ms-ppt'),
      );

      expect(verdict.isAccepted, isFalse);
      expect(verdict.rejection, contains('non pris en charge'));
    });

    test('un fichier trop lourd est refusé', () {
      final verdict = NotebookImportPolicy.inspect(
        artifact(
          sizeBytes: EducationalMediaPolicy.maxBytes(MediaType.audio) + 1,
        ),
      );

      expect(verdict.isAccepted, isFalse);
      expect(verdict.rejection, contains('volumineux'));
    });

    test('un fichier vide est refusé', () {
      final verdict = NotebookImportPolicy.inspect(
        artifact(fileName: 'vide.md', mimeType: 'text/markdown', sizeBytes: 0),
      );

      expect(verdict.isAccepted, isFalse);
    });
  });

  group('blocs prévisualisés', () {
    String pathFor(NotebookArtifact a) =>
        'educational_assets/global/terminale/svt/l1/a1/${a.fileName}';

    test('un audio devient un bloc média référencé', () {
      final blocks = NotebookImportPolicy.plannedBlocks(
        artifacts: [artifact(durationSeconds: 245)],
        storagePathFor: pathFor,
      );

      expect(blocks, hasLength(1));
      final media = blocks.single as MediaBlock;
      expect(media.mediaType, MediaType.audio);
      expect(media.durationSeconds, 245);
      // La ressource est référencée, pas recopiée dans le bloc.
      expect(media.storagePath, endsWith('capsule.mp3'));
    });

    test('un artefact refusé ne produit aucun bloc', () {
      final blocks = NotebookImportPolicy.plannedBlocks(
        artifacts: [
          artifact(fileName: 'x.pptx', mimeType: 'application/vnd.ms-ppt'),
        ],
        storagePathFor: pathFor,
      );

      expect(blocks, isEmpty);
    });

    test('un import partiel garde ce qui est valide', () {
      // Un artefact refusé n'annule pas les autres.
      final blocks = NotebookImportPolicy.plannedBlocks(
        artifacts: [
          artifact(),
          artifact(fileName: 'x.pptx', mimeType: 'application/vnd.ms-ppt'),
          artifact(fileName: 'schema.png', mimeType: 'image/png'),
        ],
        storagePathFor: pathFor,
      );

      expect(blocks, hasLength(2));
      expect(blocks.map((b) => b.order).toList(), [0, 1]);
    });

    test('un JSON sans schéma validé ne fabrique aucun bloc', () {
      // Tant qu'aucun schéma INTELLIA ne le valide, on refuse d'interpréter.
      final blocks = NotebookImportPolicy.plannedBlocks(
        artifacts: [
          artifact(
            fileName: 'quiz.json',
            mimeType: 'application/json',
            sizeBytes: 2048,
          ),
        ],
        storagePathFor: pathFor,
      );

      expect(blocks, isEmpty);
    });
  });

  group('provenance', () {
    test('elle voyage avec l’artefact', () {
      final provenance = NotebookImportProvenance(
        importedByUid: 'admin-1',
        importedAt: DateTime(2026, 9, 9, 10),
        notebookId: 'nb-svt-terminale',
        sourceTitle: 'La photosynthèse',
        model: 'gemini-notebook',
      );

      final origin = provenance.toOrigin(artifact());

      expect(origin.source, ContentSourceType.notebooklm);
      expect(origin.sourceDocumentName, 'capsule.mp3');
      expect(origin.notebookId, 'nb-svt-terminale');
      expect(origin.importedByUid, 'admin-1');
    });

    test('un champ inconnu reste vide plutôt qu’inventé', () {
      final provenance = NotebookImportProvenance(
        importedByUid: 'admin-1',
        importedAt: DateTime(2026, 9, 9),
      );

      final origin = provenance.toOrigin(artifact());

      expect(origin.notebookId, isNull);
      expect(provenance.model, isNull);
      expect(provenance.generatedAt, isNull);
    });

    test('la provenance traverse Firestore', () {
      final provenance = NotebookImportProvenance(
        importedByUid: 'admin-1',
        importedAt: DateTime(2026, 9, 9, 10),
        notebookId: 'nb-1',
      );

      final restored = ContentOrigin.fromFirestore(
        provenance.toOrigin(artifact()).toFirestore(),
      );

      expect(restored.isNotebookLm, isTrue);
      expect(restored.notebookId, 'nb-1');
      expect(restored.sourceDocumentName, 'capsule.mp3');
    });
  });
}
