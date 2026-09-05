class StudentNotification {
  const StudentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.route,
    this.type = 'information',
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? route;
  final String type;
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}
