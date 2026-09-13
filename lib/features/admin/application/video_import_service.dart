import 'dart:math';
import 'dart:typed_data';

import '../data/educational_media_service.dart';
import '../domain/admin_content_models.dart';
import '../domain/content_block.dart';
import '../domain/educational_media.dart';

/// Upload and draft persistence are separate: the author previews before saving.
/// The server rechecks actual object metadata and codecs on every save.
class VideoImportService {
  const VideoImportService(this.media);
  final EducationalMediaService media;

  Future<MediaBlock> upload({
    required AdminLessonModel lesson,
    required String name,
    required Uint8List bytes,
    required MediaUploadCancellation cancellation,
    void Function(double)? onProgress,
  }) async {
    if (!name.toLowerCase().endsWith('.mp4') ||
        bytes.length < 12 ||
        String.fromCharCodes(bytes.sublist(4, 8)) != 'ftyp') {
      throw const MediaRejectedException(
        'Sélectionnez un fichier MP4 H.264 avec audio AAC.',
      );
    }
    final random = Random.secure();
    final id =
        'video_${DateTime.now().microsecondsSinceEpoch}_${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    final result = await media.uploadAsset(
      scope: lesson.scope,
      classLevel: lesson.classLevel,
      subjectId: lesson.subjectId,
      lessonId: lesson.id,
      assetId: id,
      fileName: 'video.mp4',
      mediaType: MediaType.video,
      bytes: bytes,
      mimeType: 'video/mp4',
      cancellation: cancellation,
      onProgress: onProgress,
    );
    return MediaBlock(
      id: id,
      order: lesson.effectiveBlocks.length,
      mediaType: MediaType.video,
      storagePath: result.storagePath,
      mimeType: result.mimeType,
      fileSizeBytes: result.sizeBytes,
      caption: name,
    );
  }

  AdminLessonModel attach(
    AdminLessonModel lesson,
    MediaBlock video, {
    String? replacingId,
  }) {
    final blocks = [...lesson.effectiveBlocks];
    final index = replacingId == null
        ? -1
        : blocks.indexWhere((b) => b.id == replacingId);
    if (index < 0) {
      blocks.add(video);
    } else {
      blocks[index] = video;
    }
    return lesson.copyWith(contentBlocks: blocks, schemaVersion: 2);
  }
}
