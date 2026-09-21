import '../../interactive_learning/domain/interactive_block.dart';

enum AIMessageRole { user, assistant }

class AIMessage {
  const AIMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.companionId,
    this.block,
  });

  final String id;
  final AIMessageRole role;
  final String text;

  /// Horodatage fiable, conservé tel quel par l'historique.
  final DateTime createdAt;

  /// Compagnon ayant réellement écrit ce message, pour un message d'assistant.
  ///
  /// Registre de décisions : changer de compagnon ne réécrit pas le passé.
  /// Une réponse de Kira reste attribuée à Kira après un passage à Léo ;
  /// seuls les messages suivants prennent la nouvelle persona. Null pour les
  /// messages de l'élève et pour l'historique antérieur à ce champ.
  final String? companionId;

  /// Activité interactive proposée avec cette réponse, déjà validée par le
  /// serveur puis relue strictement par l'application.
  final InteractiveLearningBlock? block;

  AIMessage copyWith({String? text, String? companionId}) => AIMessage(
    id: id,
    role: role,
    text: text ?? this.text,
    createdAt: createdAt,
    companionId: companionId ?? this.companionId,
    block: block,
  );
}
