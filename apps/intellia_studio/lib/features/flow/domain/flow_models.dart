enum FlowCardType {
  notion,
  question,
  quiz,
  image,
  infographic,
  audio,
  shortVideo,
  interactiveNative,
}

enum FlowStatus { draft, inReview, approved, scheduled, published, archived }

class StudioFlowItem {
  final String id;
  final FlowCardType type;
  final String title;
  final String hook;
  final String subjectId;
  final List<String> classLevels;
  final FlowStatus status;
  final String scopeType; // 'global' | 'establishment'
  final String? establishmentId;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> ref;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final String? publishedAt;

  const StudioFlowItem({
    required this.id,
    required this.type,
    required this.title,
    required this.hook,
    required this.subjectId,
    required this.classLevels,
    required this.status,
    this.scopeType = 'global',
    this.establishmentId,
    this.payload = const {},
    this.ref = const {},
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  bool get isPublished => status == FlowStatus.published;

  /// Strict server-parity validator matching saveFlowPublicationCallable.ts
  static String? validateForPublication(StudioFlowItem item) {
    if (item.title.trim().isEmpty) return 'Le titre est obligatoire.';
    if (item.classLevels.isEmpty)
      return 'Au moins un niveau académique est requis.';
    if (item.subjectId.trim().isEmpty) return 'La matière est obligatoire.';

    final publishing =
        item.status == FlowStatus.published ||
        item.status == FlowStatus.scheduled;
    if (!publishing) return null; // Drafts don't require full payload

    final p = item.payload;
    switch (item.type) {
      case FlowCardType.quiz:
        final q = p['question'] as String?;
        final options = p['options'] as List?;
        final correctIndex = p['correctIndex'] as int?;
        if (q == null || q.trim().isEmpty)
          return 'La question du quiz est requise.';
        if (options == null || options.length < 2)
          return 'Le quiz doit avoir au moins 2 options.';
        if (correctIndex == null ||
            correctIndex < 0 ||
            correctIndex >= options.length) {
          return 'Index de réponse correcte invalide.';
        }
        break;
      case FlowCardType.question:
        final q = p['question'] as String?;
        final a = p['answer'] as String?;
        if (q == null || q.trim().isEmpty || a == null || a.trim().isEmpty) {
          return 'La question et la réponse sont requises.';
        }
        break;
      case FlowCardType.notion:
      case FlowCardType.infographic:
        final insight = p['insight'] as String?;
        final points = p['points'] as List?;
        if ((insight == null || insight.trim().isEmpty) &&
            (points == null || points.isEmpty)) {
          return 'Au moins un point-clé ou une synthèse est requise.';
        }
        break;
      case FlowCardType.shortVideo:
        final storagePath = item.ref['storagePath'] as String?;
        if (storagePath == null || storagePath.trim().isEmpty) {
          return 'Une vidéo courte nécessite une référence storagePath valide.';
        }
        break;
      case FlowCardType.interactiveNative:
        final comp = p['componentKey'] as String?;
        final summary = p['summary'] as String?;
        if (comp == null || summary == null)
          return 'Composant interactif incomplet.';
        break;
      default:
        final storage = item.ref['storagePath'] as String?;
        if (storage == null || storage.trim().isEmpty) {
          return 'Ce média requiert un chemin de fichier valide.';
        }
    }
    return null;
  }
}
