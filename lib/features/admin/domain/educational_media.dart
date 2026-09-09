import 'dart:typed_data';

import 'content_block.dart';
import 'content_scope.dart';

/// Emplacement canonique d'une ressource pédagogique.
///
/// Registre de décisions : le chemin de stockage est la donnée canonique, pas
/// l'URL. Une URL de téléchargement est dérivée à la lecture et reste
/// jetable — c'est ce qui permettra de passer plus tard à un CDN, à des URLs
/// signées ou à un autre hébergeur sans migrer un seul document Firestore.
///
/// Le premier segment est le périmètre ([ContentScope.scopeId]) : c'est lui
/// que les règles de sécurité comparent à l'établissement de l'utilisateur,
/// de sorte qu'un enseignant d'un établissement ne puisse pas écraser les
/// ressources d'un autre.
abstract final class EducationalAssetPath {
  static const root = 'educational_assets';

  /// Construit le chemin canonique d'une ressource.
  ///
  /// Lève [ArgumentError] si un segment est vide ou contient un séparateur :
  /// un identifiant mal formé pourrait sinon faire sortir la ressource de son
  /// périmètre et contourner le cloisonnement.
  static String build({
    required ContentScope scope,
    required String classLevel,
    required String subjectId,
    required String lessonId,
    required String assetId,
    required String fileName,
  }) {
    final segments = <String, String>{
      'scopeId': scope.scopeId,
      'classLevel': classLevel,
      'subjectId': subjectId,
      'lessonId': lessonId,
      'assetId': assetId,
      'fileName': fileName,
    };
    for (final entry in segments.entries) {
      _assertSafeSegment(entry.key, entry.value);
    }
    return '$root/${segments.values.join('/')}';
  }

  /// Périmètre auquel appartient un chemin, ou null s'il est hors racine.
  static String? scopeIdOf(String storagePath) {
    final parts = storagePath.split('/');
    if (parts.length < 2 || parts.first != root) return null;
    final scopeId = parts[1];
    return scopeId.isEmpty ? null : scopeId;
  }

  /// Vrai quand le chemin appartient au périmètre donné.
  static bool belongsTo(String storagePath, ContentScope scope) =>
      scopeIdOf(storagePath) == scope.scopeId;

  static void _assertSafeSegment(String name, String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'segment vide');
    }
    if (value.contains('/') || value.contains(r'\')) {
      throw ArgumentError.value(value, name, 'séparateur interdit');
    }
    if (value == '.' || value == '..') {
      throw ArgumentError.value(value, name, 'segment relatif interdit');
    }
  }
}

/// Formats acceptés et plafonds de taille, par nature de média.
///
/// Le contrôle vit ici plutôt que dans l'écran d'import : les règles Storage
/// appliquent les mêmes plafonds côté serveur, et une vérification locale
/// évite à l'élève comme à l'enseignant un téléversement voué à l'échec.
abstract final class EducationalMediaPolicy {
  static const maxBytesByType = <MediaType, int>{
    MediaType.image: 8 * 1024 * 1024,
    MediaType.audio: 60 * 1024 * 1024,
    MediaType.video: 300 * 1024 * 1024,
    MediaType.pdf: 40 * 1024 * 1024,
  };

  static const mimeTypesByType = <MediaType, Set<String>>{
    MediaType.image: {'image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'},
    MediaType.audio: {'audio/mpeg', 'audio/mp4', 'audio/m4a', 'audio/aac'},
    MediaType.video: {'video/mp4', 'video/webm'},
    MediaType.pdf: {'application/pdf'},
  };

  static bool acceptsMimeType(MediaType type, String mimeType) =>
      mimeTypesByType[type]?.contains(mimeType.toLowerCase()) ?? false;

  static int maxBytes(MediaType type) => maxBytesByType[type] ?? 0;

  /// Décrit pourquoi un fichier est refusé, ou null s'il est acceptable.
  static String? rejectionReason({
    required MediaType type,
    required String mimeType,
    required int sizeBytes,
  }) {
    if (!acceptsMimeType(type, mimeType)) {
      return 'Format $mimeType non accepté pour ${type.name}.';
    }
    if (sizeBytes <= 0) return 'Fichier vide.';
    final limit = maxBytes(type);
    if (sizeBytes > limit) {
      final mb = (limit / (1024 * 1024)).round();
      return 'Fichier trop volumineux : $mb Mo au maximum.';
    }
    return null;
  }
}

/// Résultat d'un téléversement.
class MediaUploadResult {
  const MediaUploadResult({
    required this.storagePath,
    required this.sizeBytes,
    required this.mimeType,
    this.downloadUrl,
  });

  /// Donnée canonique à écrire dans Firestore.
  final String storagePath;
  final int sizeBytes;
  final String mimeType;

  /// Commodité de l'instant : ne jamais la traiter comme durable.
  final String? downloadUrl;
}

/// Accès aux ressources pédagogiques, indépendamment de l'hébergeur.
///
/// Le domaine ne connaît que cette interface. Firebase Storage en est
/// l'implémentation de départ ; un CDN, un service de streaming ou un cache
/// hors ligne pourront s'y substituer sans toucher aux modèles.
abstract interface class EducationalMediaProvider {
  /// Résout une URL lisible pour un chemin canonique.
  Future<String> resolveUrl(String storagePath);

  Future<MediaUploadResult> upload({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  });

  Future<void> delete(String storagePath);
}

/// Refus d'un téléversement, exposé tel quel à l'auteur.
class MediaRejectedException implements Exception {
  const MediaRejectedException(this.reason);

  final String reason;

  @override
  String toString() => reason;
}
