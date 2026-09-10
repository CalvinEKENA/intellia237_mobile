import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/content_block.dart';
import '../domain/content_scope.dart';
import '../domain/educational_media.dart';

/// Implémentation Firebase Storage de [EducationalMediaProvider].
///
/// Elle reste volontairement mince : toute la connaissance métier — chemins
/// canoniques, formats acceptés, plafonds — vit dans le domaine, de sorte
/// qu'un autre hébergeur puisse la remplacer sans rien réécrire d'autre.
class FirebaseEducationalMediaProvider implements EducationalMediaProvider {
  FirebaseEducationalMediaProvider([FirebaseStorage? storage])
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> resolveUrl(String storagePath) =>
      _storage.ref(storagePath).getDownloadURL();

  @override
  Future<MediaUploadResult> upload({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(storagePath);
    final task = ref.putData(bytes, SettableMetadata(contentType: mimeType));

    if (onProgress != null) {
      task.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        if (total > 0) onProgress(snapshot.bytesTransferred / total);
      });
    }

    await task;
    return MediaUploadResult(
      storagePath: storagePath,
      sizeBytes: bytes.lengthInBytes,
      mimeType: mimeType,
    );
  }

  @override
  Future<void> delete(String storagePath) => _storage.ref(storagePath).delete();
}

/// Téléversement d'une ressource pédagogique, périmètre et format contrôlés.
///
/// Le contrôle local n'est pas un substitut aux règles Storage — celles-ci
/// restent l'autorité — mais il évite d'envoyer sur le réseau un fichier qui
/// serait refusé, ce qui compte sur une connexion mesurée.
class EducationalMediaService {
  const EducationalMediaService(this._provider);

  final EducationalMediaProvider _provider;

  Future<MediaUploadResult> uploadAsset({
    required ContentScope scope,
    required String classLevel,
    required String subjectId,
    required String lessonId,
    required String assetId,
    required String fileName,
    required MediaType mediaType,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final refusal = EducationalMediaPolicy.rejectionReason(
      type: mediaType,
      mimeType: mimeType,
      sizeBytes: bytes.lengthInBytes,
    );
    if (refusal != null) throw MediaRejectedException(refusal);

    final storagePath = EducationalAssetPath.build(
      scope: scope,
      classLevel: classLevel,
      subjectId: subjectId,
      lessonId: lessonId,
      assetId: assetId,
      fileName: fileName,
    );

    return _provider.upload(
      storagePath: storagePath,
      bytes: bytes,
      mimeType: mimeType,
      onProgress: onProgress,
    );
  }

  /// Supprime une ressource après avoir vérifié qu'elle relève bien du
  /// périmètre de l'auteur : un chemin reçu d'ailleurs ne doit pas permettre
  /// d'effacer la ressource d'un autre établissement.
  Future<void> deleteAsset({
    required String storagePath,
    required ContentScope scope,
  }) async {
    if (!EducationalAssetPath.belongsTo(storagePath, scope)) {
      throw MediaRejectedException(
        'Cette ressource appartient à un autre périmètre.',
      );
    }
    await _provider.delete(storagePath);
  }

  Future<String> resolveUrl(String storagePath) =>
      _provider.resolveUrl(storagePath);
}

final educationalMediaProviderProvider = Provider<EducationalMediaProvider>(
  (ref) => FirebaseEducationalMediaProvider(),
);

final educationalMediaServiceProvider = Provider<EducationalMediaService>(
  (ref) => EducationalMediaService(ref.watch(educationalMediaProviderProvider)),
);
