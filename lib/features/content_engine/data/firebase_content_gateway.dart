import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'content_delivery.dart';

/// Catalogue et bundles dans Firebase Storage.
///
/// Emplacement : `content/catalog.json` et
/// `content/packs/<id>/v<version>/bundle.json`. Lecture réservée aux comptes
/// connectés (règle `storage.rules`) ; aucune écriture depuis l'application.
class FirebaseStorageContentGateway implements RemoteContentGateway {
  FirebaseStorageContentGateway({FirebaseStorage? storage})
    : _storage = storage;

  final FirebaseStorage? _storage;

  static const catalogPath = 'content/catalog.json';

  /// Un catalogue reste petit ; un bundle de chapitre aussi.
  static const _maxCatalogBytes = 2 * 1024 * 1024;
  static const _maxBundleBytes = 8 * 1024 * 1024;

  FirebaseStorage get _instance => _storage ?? FirebaseStorage.instance;

  @override
  Future<Uint8List?> fetchCatalog() async {
    try {
      return await _instance
          .ref(catalogPath)
          .getData(_maxCatalogBytes)
          .timeout(const Duration(seconds: 12));
    } on FirebaseException catch (error) {
      // Aucun catalogue publié : ce n'est pas une panne.
      if (error.code == 'object-not-found') return null;
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List> fetchBundle(String path) async {
    final data = await _instance
        .ref(path)
        .getData(_maxBundleBytes)
        .timeout(const Duration(seconds: 30));
    if (data == null) throw StateError('Bundle vide : $path');
    return data;
  }
}
