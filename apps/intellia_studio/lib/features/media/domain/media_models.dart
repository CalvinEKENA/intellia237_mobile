enum StudioMediaType { image, audio, video, document }

class StudioMediaAsset {
  final String id;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final String storagePath;
  final String downloadUrl;
  final String scopeType; // 'global' | 'establishment'
  final String? establishmentId;
  final String uploadedAt;
  final String uploaderUid;

  const StudioMediaAsset({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.storagePath,
    required this.downloadUrl,
    this.scopeType = 'global',
    this.establishmentId,
    required this.uploadedAt,
    required this.uploaderUid,
  });

  StudioMediaType get type {
    if (mimeType.startsWith('image/')) return StudioMediaType.image;
    if (mimeType.startsWith('audio/')) return StudioMediaType.audio;
    if (mimeType.startsWith('video/')) return StudioMediaType.video;
    return StudioMediaType.document;
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
