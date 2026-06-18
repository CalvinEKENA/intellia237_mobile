enum AIMessageRole { user, assistant }

class AIMessage {
  const AIMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final AIMessageRole role;
  final String text;
  final DateTime createdAt;
}
