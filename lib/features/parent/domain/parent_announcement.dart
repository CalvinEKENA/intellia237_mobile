class ParentAnnouncement {
  const ParentAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
    this.establishmentId,
    this.establishmentName,
  });

  final String id;
  final String title;
  final String body;
  final DateTime publishedAt;

  /// École qui publie : un parent suit l'école de chacun de ses enfants.
  final String? establishmentId;
  final String? establishmentName;
}
