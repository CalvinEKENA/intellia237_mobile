/// Immutable audit log event for institutional operations.
///
/// Read-only in presentation. No deletion or mutation allowed.
library;

class CampusAuditEvent {
  final String id;
  final String establishmentId;
  final String actorDisplayName;
  final String action;
  final String targetType;
  final String targetDisplayName;
  final DateTime occurredAt;

  const CampusAuditEvent({
    required this.id,
    required this.establishmentId,
    required this.actorDisplayName,
    required this.action,
    required this.targetType,
    required this.targetDisplayName,
    required this.occurredAt,
  });
}
