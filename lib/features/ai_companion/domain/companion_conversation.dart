import 'ai_message.dart';

/// Un fil de discussion avec le compagnon.
///
/// Registre de décisions : la persistance et l'horodatage sont contractuels.
/// La **présentation** de la liste — regroupements par date, génération
/// automatique de titre — n'a en revanche jamais été arrêtée comme canon : le
/// titre retenu ici est simplement la première question de l'élève, tronquée.
/// C'est un choix d'implémentation nouveau, pas une décision historique.
class CompanionConversation {
  const CompanionConversation({
    required this.id,
    required this.learnerId,
    required this.createdAt,
    required this.lastActivityAt,
    this.title = '',
    this.preview = '',
    this.companionId,
  });

  final String id;

  /// Propriétaire du fil. Une conversation n'existe que pour son élève.
  final String learnerId;

  final DateTime createdAt;
  final DateTime lastActivityAt;

  /// Titre lisible, dérivé de la première question.
  final String title;

  /// Dernier message, tronqué pour l'aperçu.
  final String preview;

  /// Dernier compagnon ayant répondu dans ce fil.
  final String? companionId;

  CompanionConversation copyWith({
    DateTime? lastActivityAt,
    String? title,
    String? preview,
    String? companionId,
  }) => CompanionConversation(
    id: id,
    learnerId: learnerId,
    createdAt: createdAt,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    title: title ?? this.title,
    preview: preview ?? this.preview,
    companionId: companionId ?? this.companionId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'learnerId': learnerId,
    'createdAt': createdAt.toIso8601String(),
    'lastActivityAt': lastActivityAt.toIso8601String(),
    'title': title,
    'preview': preview,
    if (companionId != null) 'companionId': companionId,
  };

  static CompanionConversation? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final learnerId = json['learnerId'];
    if (id is! String || learnerId is! String) return null;
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    if (createdAt == null) return null;
    return CompanionConversation(
      id: id,
      learnerId: learnerId,
      createdAt: createdAt,
      lastActivityAt:
          DateTime.tryParse(json['lastActivityAt'] as String? ?? '') ??
          createdAt,
      title: json['title'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      companionId: json['companionId'] as String?,
    );
  }

  /// Résume un fil à partir de ses messages.
  static CompanionConversation summarize({
    required CompanionConversation base,
    required List<AIMessage> messages,
  }) {
    final real = messages.where((m) => m.id != 'welcome').toList();
    if (real.isEmpty) return base;
    final firstQuestion = real.firstWhere(
      (m) => m.role == AIMessageRole.user,
      orElse: () => real.first,
    );
    final last = real.last;
    return base.copyWith(
      lastActivityAt: last.createdAt,
      title: _truncate(firstQuestion.text, 60),
      preview: _truncate(last.text, 90),
      companionId: real
          .lastWhere(
            (m) => m.role == AIMessageRole.assistant && m.companionId != null,
            orElse: () => last,
          )
          .companionId,
    );
  }

  static String _truncate(String value, int max) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= max) return cleaned;
    return '${cleaned.substring(0, max - 1).trimRight()}…';
  }
}
