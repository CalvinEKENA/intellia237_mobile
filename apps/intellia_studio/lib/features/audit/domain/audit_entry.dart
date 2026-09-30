class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.actorId,
    required this.targetId,
    required this.action,
    required this.previousStatus,
    required this.status,
    required this.reason,
    required this.createdAt,
    this.metadata = const {},
  });

  final String id;
  final String actorId;
  final String targetId;
  final String action;
  final String previousStatus;
  final String status;
  final String reason;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  factory AuditEntry.fromFirestore(String id, Map<String, dynamic> data) {
    return AuditEntry(
      id: id,
      actorId: data['actorId'] as String? ?? 'system',
      targetId: data['targetId'] as String? ?? '',
      action: data['action'] as String? ?? '',
      previousStatus: data['previousStatus'] as String? ?? '',
      status: data['status'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }
}
