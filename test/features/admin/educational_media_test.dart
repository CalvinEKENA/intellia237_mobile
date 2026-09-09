import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/data/educational_media_service.dart';
import 'package:intellia237/features/admin/domain/content_block.dart';
import 'package:intellia237/features/admin/domain/content_scope.dart';
import 'package:intellia237/features/admin/domain/educational_media.dart';

/// Le chemin de stockage est la donnée canonique, et son premier segment est
/// le périmètre : c'est lui qui empêche un établissement de toucher aux
/// ressources d'un autre.
void main() {
  const global = ContentScope.global;
  const lycee = ContentScope(
    type: ContentScopeType.establishment,
    establishmentId: 'lycee-general-leclerc',
  );

  group('chemin canonique', () {
    test('le périmètre national ouvre le chemin', () {
      final path = EducationalAssetPath.build(
        scope: global,
        classLevel: 'terminale',
        subjectId: 'maths',
        lessonId: 'lesson-1',
        assetId: 'asset-1',
        fileName: 'schema.png',
      );

      expect(
        path,
        'educational_assets/global/terminale/maths/lesson-1/asset-1/schema.png',
      );
      expect(EducationalAssetPath.scopeIdOf(path), 'global');
    });

    test('un établissement porte son identifiant en tête', () {
      final path = EducationalAssetPath.build(
        scope: lycee,
        classLevel: 'terminale',
        subjectId: 'maths',
        lessonId: 'lesson-1',
        assetId: 'asset-1',
        fileName: 'cours.pdf',
      );

      expect(path, startsWith('educational_assets/lycee-general-leclerc/'));
      expect(EducationalAssetPath.scopeIdOf(path), 'lycee-general-leclerc');
    });

    test('un segment vide est refusé', () {
      expect(
        () => EducationalAssetPath.build(
          scope: global,
          classLevel: '',
          subjectId: 'maths',
          lessonId: 'l1',
          assetId: 'a1',
          fileName: 'f.png',
        ),
        throwsArgumentError,
      );
    });

    test('un segment ne peut pas s’échapper du périmètre', () {
      // Sans ce garde-fou, « ../autre-etablissement » sortirait du
      // cloisonnement que les règles Storage appliquent sur le premier segment.
      final hostiles = <String>['..', '.', 'a/b', 'a\\b'];
      for (final hostile in hostiles) {
        expect(
          () => EducationalAssetPath.build(
            scope: lycee,
            classLevel: 'terminale',
            subjectId: hostile,
            lessonId: 'l1',
            assetId: 'a1',
            fileName: 'f.png',
          ),
          throwsArgumentError,
          reason: 'segment hostile accepté : $hostile',
        );
      }
    });

    test('l’appartenance à un périmètre est vérifiable', () {
      final path = EducationalAssetPath.build(
        scope: lycee,
        classLevel: 'terminale',
        subjectId: 'maths',
        lessonId: 'l1',
        assetId: 'a1',
        fileName: 'f.png',
      );

      expect(EducationalAssetPath.belongsTo(path, lycee), isTrue);
      expect(EducationalAssetPath.belongsTo(path, global), isFalse);
    });

    test('un chemin hors racine n’a pas de périmètre', () {
      expect(EducationalAssetPath.scopeIdOf('avatars/uid/photo.png'), isNull);
    });
  });

  group('politique de format', () {
    test('les formats attendus sont acceptés', () {
      expect(
        EducationalMediaPolicy.acceptsMimeType(MediaType.image, 'image/png'),
        isTrue,
      );
      expect(
        EducationalMediaPolicy.acceptsMimeType(MediaType.audio, 'audio/mpeg'),
        isTrue,
      );
      expect(
        EducationalMediaPolicy.acceptsMimeType(
          MediaType.pdf,
          'application/pdf',
        ),
        isTrue,
      );
    });

    test('un format ne traverse pas sa catégorie', () {
      expect(
        EducationalMediaPolicy.acceptsMimeType(MediaType.image, 'video/mp4'),
        isFalse,
      );
    });

    test('un exécutable déguisé est refusé', () {
      expect(
        EducationalMediaPolicy.rejectionReason(
          type: MediaType.pdf,
          mimeType: 'application/x-msdownload',
          sizeBytes: 1024,
        ),
        isNotNull,
      );
    });

    test('le plafond de taille est appliqué', () {
      final reason = EducationalMediaPolicy.rejectionReason(
        type: MediaType.image,
        mimeType: 'image/png',
        sizeBytes: EducationalMediaPolicy.maxBytes(MediaType.image) + 1,
      );

      expect(reason, contains('volumineux'));
    });

    test('un fichier vide est refusé', () {
      expect(
        EducationalMediaPolicy.rejectionReason(
          type: MediaType.image,
          mimeType: 'image/png',
          sizeBytes: 0,
        ),
        isNotNull,
      );
    });
  });

  group('service de téléversement', () {
    late _RecordingProvider provider;
    late EducationalMediaService service;

    setUp(() {
      provider = _RecordingProvider();
      service = EducationalMediaService(provider);
    });

    test('un fichier valide part au bon chemin', () async {
      final result = await service.uploadAsset(
        scope: lycee,
        classLevel: 'terminale',
        subjectId: 'maths',
        lessonId: 'l1',
        assetId: 'a1',
        fileName: 'schema.png',
        mediaType: MediaType.image,
        bytes: Uint8List.fromList(List.filled(1024, 0)),
        mimeType: 'image/png',
      );

      expect(
        result.storagePath,
        'educational_assets/lycee-general-leclerc/terminale/maths/l1/a1/'
        'schema.png',
      );
      expect(provider.uploaded, hasLength(1));
    });

    test('un fichier refusé n’atteint jamais le réseau', () async {
      await expectLater(
        service.uploadAsset(
          scope: global,
          classLevel: 'terminale',
          subjectId: 'maths',
          lessonId: 'l1',
          assetId: 'a1',
          fileName: 'virus.exe',
          mediaType: MediaType.image,
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'application/x-msdownload',
        ),
        throwsA(isA<MediaRejectedException>()),
      );

      // Sur une connexion mesurée, un refus doit coûter zéro octet.
      expect(provider.uploaded, isEmpty);
    });

    test('effacer hors de son périmètre est refusé', () async {
      const foreign =
          'educational_assets/lycee-voisin/terminale/maths/l1/a1/f.png';

      await expectLater(
        service.deleteAsset(storagePath: foreign, scope: lycee),
        throwsA(isA<MediaRejectedException>()),
      );

      expect(provider.deleted, isEmpty);
    });

    test('effacer dans son périmètre est permis', () async {
      const own =
          'educational_assets/lycee-general-leclerc/terminale/maths/l1/a1/'
          'f.png';

      await service.deleteAsset(storagePath: own, scope: lycee);

      expect(provider.deleted, [own]);
    });
  });
}

class _RecordingProvider implements EducationalMediaProvider {
  final uploaded = <String>[];
  final deleted = <String>[];

  @override
  Future<String> resolveUrl(String storagePath) async =>
      'https://example.test/$storagePath';

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
  Future<void> delete(String storagePath) async => deleted.add(storagePath);
}
