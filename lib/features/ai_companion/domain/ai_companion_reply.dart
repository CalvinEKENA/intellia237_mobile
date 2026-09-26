import 'ai_message.dart';

class AICompanionQuota {
  const AICompanionQuota({
    required this.limit,
    required this.remaining,
    this.resetsAt,
  });

  factory AICompanionQuota.fromMap(Map<String, dynamic> data) {
    final parsedLimit = (data['limit'] as num?)?.toInt() ?? 0;
    final limit = parsedLimit < 0 ? 0 : parsedLimit;
    final parsedRemaining = (data['remaining'] as num?)?.toInt() ?? 0;
    return AICompanionQuota(
      limit: limit,
      remaining: parsedRemaining.clamp(0, limit),
      resetsAt: DateTime.tryParse(data['resetsAt'] as String? ?? ''),
    );
  }

  final int limit;
  final int remaining;
  final DateTime? resetsAt;
}

class AICompanionReply {
  const AICompanionReply({required this.message, required this.quota});

  final AIMessage message;
  final AICompanionQuota quota;
}

enum AICompanionFailureKind {
  quotaExhausted,

  /// Réserve d'étude vide pour le cycle : distinct du quota quotidien.
  studyReserveExhausted,
  network,
  serviceUnavailable,
  authorizationProfile,
  invalidRequest,
  appCheck,
  invalidResponse,
  unknown,
}

class AICompanionException implements Exception {
  const AICompanionException({
    required this.message,
    required this.kind,
    required this.normalizedErrorCode,
    required this.diagnosticId,
    this.retryable = true,
    this.quota,
  });

  final String message;
  final AICompanionFailureKind kind;
  final String normalizedErrorCode;
  final String diagnosticId;
  final bool retryable;
  final AICompanionQuota? quota;

  @override
  String toString() => message;
}
