import 'dart:math';
import 'dart:typed_data';

import '../data/educational_media_service.dart';
import '../domain/admin_content_models.dart';
import '../domain/content_block.dart';
import '../domain/educational_media.dart';

/// Un fichier réellement choisi pour l'import NotebookLM : nom, octets, type.
class PickedNotebookFile {
  const PickedNotebookFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;
}

/// Importe pour de vrai des productions NotebookLM (image / audio / MP4 / PDF)
/// dans une **leçon brouillon** : chaque fichier est téléversé vers son chemin
/// canonique dans Storage, puis rattaché comme bloc média. Aucune publication.
///
/// L'upload et la persistance restent séparés (l'auteur prévisualise avant de
/// sauvegarder) ; le serveur revérifie type et taille réels à chaque écriture.
class NotebookImportService {
  const NotebookImportService(this.media);

  final EducationalMediaService media;

  /// Type de média canonique pour un MIME donné, ou null si non pris en charge.
  static MediaType? mediaTypeFor(String mimeType) {
    final normalized = mimeType.trim().toLowerCase();
    if (normalized.startsWith('image/')) return MediaType.image;
    if (normalized.startsWith('audio/')) return MediaType.audio;
    if (normalized == 'video/mp4') return MediaType.video;
    if (normalized == 'application/pdf') return MediaType.pdf;
    return null;
  }

  /// Téléverse un fichier et renvoie le bloc média correspondant (non attaché).
  Future<MediaBlock> uploadFile({
    required AdminLessonModel lesson,
    required PickedNotebookFile file,
    required int order,
  }) async {
    final type = mediaTypeFor(file.mimeType);
    if (type == null) {
      throw MediaRejectedException(
        'Type de fichier non pris en charge : ${file.mimeType}.',
      );
    }
    final random = Random.secure();
    final id =
        'nb_${DateTime.now().microsecondsSinceEpoch}_'
        '${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    final result = await media.uploadAsset(
      scope: lesson.scope,
      classLevel: lesson.classLevel,
      subjectId: lesson.subjectId,
      lessonId: lesson.id,
      assetId: id,
      fileName: file.name,
      mediaType: type,
      bytes: file.bytes,
      mimeType: file.mimeType,
    );
    return MediaBlock(
      id: id,
      order: order,
      mediaType: type,
      storagePath: result.storagePath,
      mimeType: result.mimeType,
      fileSizeBytes: result.sizeBytes,
      caption: file.name,
    );
  }

  /// Téléverse tous les fichiers et renvoie la leçon **mise à jour** (blocs
  /// rattachés, schéma V2). L'appelant la sauvegarde ensuite en brouillon.
  Future<AdminLessonModel> importInto(
    AdminLessonModel lesson,
    List<PickedNotebookFile> files,
  ) async {
    final blocks = [...lesson.effectiveBlocks];
    for (final file in files) {
      blocks.add(
        await uploadFile(lesson: lesson, file: file, order: blocks.length),
      );
    }
    return lesson.copyWith(contentBlocks: blocks, schemaVersion: 2);
  }
}
