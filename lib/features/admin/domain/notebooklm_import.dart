import 'package:flutter/foundation.dart';

import '../../learn/domain/content_block.dart';
import 'content_origin.dart';
import 'educational_media.dart';

/// Un artefact exporté depuis NotebookLM, prêt à être importé.
@immutable
class NotebookArtifact {
  const NotebookArtifact({
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.checksum,
    this.durationSeconds,
  });

  final String fileName;
  final String mimeType;
  final int sizeBytes;

  /// Empreinte du fichier source, quand elle est connue. Elle permettra de
  /// reconnaître un artefact déjà importé.
  final String? checksum;

  final int? durationSeconds;
}

/// Ce que le Studio sait réellement importer.
///
/// Registre de décisions : NotebookLM n'expose aucune API stable, et ses
/// exports n'ont pas de structure garantie. On n'importe donc que des formats
/// dont la nature est vérifiable — un fichier audio est un fichier audio. Le
/// JSON n'est accepté que lorsqu'il satisfait un schéma INTELLIA explicite ;
/// à défaut, il est refusé plutôt qu'interprété au jugé.
enum NotebookArtifactKind {
  audioOverview,
  video,
  image,
  document,
  markdown,
  structuredQuiz;

  static const _byMime = <String, NotebookArtifactKind>{
    'audio/mpeg': NotebookArtifactKind.audioOverview,
    'audio/mp4': NotebookArtifactKind.audioOverview,
    'audio/m4a': NotebookArtifactKind.audioOverview,
    'audio/aac': NotebookArtifactKind.audioOverview,
    'video/mp4': NotebookArtifactKind.video,
    'video/webm': NotebookArtifactKind.video,
    'image/png': NotebookArtifactKind.image,
    'image/jpeg': NotebookArtifactKind.image,
    'image/webp': NotebookArtifactKind.image,
    'application/pdf': NotebookArtifactKind.document,
    'text/markdown': NotebookArtifactKind.markdown,
    'text/plain': NotebookArtifactKind.markdown,
    'application/json': NotebookArtifactKind.structuredQuiz,
  };

  static NotebookArtifactKind? forMimeType(String mimeType) =>
      _byMime[mimeType.toLowerCase()];
}

/// Verdict d'acceptation d'un artefact.
@immutable
class ArtifactVerdict {
  const ArtifactVerdict.accepted(this.kind) : rejection = null;
  const ArtifactVerdict.rejected(this.rejection) : kind = null;

  final NotebookArtifactKind? kind;
  final String? rejection;

  bool get isAccepted => rejection == null;
}

abstract final class NotebookImportPolicy {
  /// Décide si un artefact peut entrer dans le Studio.
  static ArtifactVerdict inspect(NotebookArtifact artifact) {
    final kind = NotebookArtifactKind.forMimeType(artifact.mimeType);
    if (kind == null) {
      return ArtifactVerdict.rejected(
        'Format ${artifact.mimeType} non pris en charge à l’import.',
      );
    }

    final mediaType = mediaTypeFor(kind);
    if (mediaType != null) {
      final refusal = EducationalMediaPolicy.rejectionReason(
        type: mediaType,
        mimeType: artifact.mimeType,
        sizeBytes: artifact.sizeBytes,
      );
      if (refusal != null) return ArtifactVerdict.rejected(refusal);
    } else if (artifact.sizeBytes <= 0) {
      return const ArtifactVerdict.rejected('Fichier vide.');
    }

    return ArtifactVerdict.accepted(kind);
  }

  /// Nature de stockage correspondante, ou null pour un artefact textuel.
  static MediaType? mediaTypeFor(NotebookArtifactKind kind) => switch (kind) {
    NotebookArtifactKind.audioOverview => MediaType.audio,
    NotebookArtifactKind.video => MediaType.video,
    NotebookArtifactKind.image => MediaType.image,
    NotebookArtifactKind.document => MediaType.pdf,
    NotebookArtifactKind.markdown => null,
    NotebookArtifactKind.structuredQuiz => null,
  };

  /// Les blocs qui seront créés, tels qu'ils seront prévisualisés.
  ///
  /// Aucun artefact n'est transformé : un enregistrement reste un
  /// enregistrement, et sa provenance voyage avec lui. Une production
  /// retravaillée en composant natif deviendra un artefact dérivé distinct.
  static List<ContentBlock> plannedBlocks({
    required List<NotebookArtifact> artifacts,
    required String Function(NotebookArtifact) storagePathFor,
    int startOrder = 0,
  }) {
    final blocks = <ContentBlock>[];
    var order = startOrder;
    for (final artifact in artifacts) {
      final verdict = inspect(artifact);
      if (!verdict.isAccepted) continue;
      final kind = verdict.kind!;
      final mediaType = mediaTypeFor(kind);

      if (mediaType != null) {
        blocks.add(
          MediaBlock(
            id: 'nb_${order}_${artifact.fileName.hashCode.abs()}',
            order: order,
            mediaType: mediaType,
            storagePath: storagePathFor(artifact),
            caption: artifact.fileName,
            durationSeconds: artifact.durationSeconds,
            mimeType: artifact.mimeType,
          ),
        );
      } else if (kind == NotebookArtifactKind.markdown) {
        blocks.add(
          TextBlock(
            id: 'nb_${order}_${artifact.fileName.hashCode.abs()}',
            order: order,
            title: artifact.fileName,
            markdown: '',
          ),
        );
      } else {
        // Le JSON n'entre que validé par un schéma explicite ; tant qu'il
        // n'existe pas, aucun bloc n'est fabriqué à l'aveugle.
        continue;
      }
      order++;
    }
    return blocks;
  }
}

/// Provenance enregistrée avec chaque import.
///
/// Rien n'est inventé : un champ inconnu reste vide plutôt que rempli d'une
/// approximation.
@immutable
class NotebookImportProvenance {
  const NotebookImportProvenance({
    required this.importedByUid,
    required this.importedAt,
    this.notebookId,
    this.sourceTitle,
    this.model,
    this.generatedAt,
    this.notes,
  });

  final String importedByUid;
  final DateTime importedAt;
  final String? notebookId;
  final String? sourceTitle;
  final String? model;
  final DateTime? generatedAt;
  final String? notes;

  ContentOrigin toOrigin(NotebookArtifact artifact) => ContentOrigin(
    source: ContentSourceType.notebooklm,
    sourceDocumentName: artifact.fileName,
    importedAt: importedAt,
    importedByUid: importedByUid,
    notebookId: notebookId,
  );
}
