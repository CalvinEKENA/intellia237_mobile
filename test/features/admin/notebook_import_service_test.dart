import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/application/notebook_import_service.dart';
import 'package:intellia237/features/admin/data/educational_media_service.dart';
import 'package:intellia237/features/admin/domain/admin_content_models.dart';
import 'package:intellia237/features/admin/domain/content_block.dart';
import 'package:intellia237/features/admin/domain/educational_media.dart';

class _RecordingMediaProvider implements EducationalMediaProvider {
  final List<String> uploaded = [];

  @override
  Future<MediaUploadResult> upload({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    uploaded.add(storagePath);
    return MediaUploadResult(
      storagePath: storagePath,
      sizeBytes: bytes.lengthInBytes,
      mimeType: mimeType,
    );
  }

  @override
  Future<String> resolveUrl(String storagePath) async =>
      'https://x/$storagePath';

  @override
  Future<void> delete(String storagePath) async {}
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
  group('NotebookImportService.mediaTypeFor', () {
    test('maps supported MIME types and rejects the rest', () {
      expect(NotebookImportService.mediaTypeFor('image/png'), MediaType.image);
      expect(NotebookImportService.mediaTypeFor('audio/mpeg'), MediaType.audio);
      expect(NotebookImportService.mediaTypeFor('video/mp4'), MediaType.video);
      expect(
        NotebookImportService.mediaTypeFor('application/pdf'),
        MediaType.pdf,
      );
      expect(
        NotebookImportService.mediaTypeFor('application/vnd.ms-ppt'),
        isNull,
      );
    });
  });

  test('importInto uploads each file and attaches real media blocks', () async {
    final provider = _RecordingMediaProvider();
    final service = NotebookImportService(EducationalMediaService(provider));

    final updated = await service.importInto(_draftLesson(), [
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
    ]);

    // Deux uploads réels vers des chemins canoniques, deux blocs média attachés.
    expect(provider.uploaded, hasLength(2));
    expect(
      provider.uploaded.every((p) => p.contains('/svt/lesson-1/')),
      isTrue,
    );
    final media = updated.effectiveBlocks.whereType<MediaBlock>().toList();
    expect(media, hasLength(2));
    expect(
      media.map((b) => b.mediaType),
      containsAll(<MediaType>[MediaType.audio, MediaType.image]),
    );
    // La leçon reste un brouillon (V2), jamais publiée par l'import.
    expect(updated.isPublished, isFalse);
    expect(updated.schemaVersion, 2);
    for (final block in media) {
      expect(block.storagePath, isNotEmpty);
    }
  });

  test('a rejected MIME type stops the import with a clear reason', () async {
    final service = NotebookImportService(
      EducationalMediaService(_RecordingMediaProvider()),
    );
    expect(
      () => service.importInto(_draftLesson(), [
        PickedNotebookFile(
          name: 'slides.pptx',
          bytes: _bytes(64),
          mimeType: 'application/vnd.ms-ppt',
        ),
      ]),
      throwsA(isA<MediaRejectedException>()),
    );
  });
}
