import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../domain/student_notification.dart';

abstract interface class NotificationRepository {
  Stream<List<StudentNotification>> watchForUser(String userId);

  Future<void> markRead({required String userId, required String id});

  Future<void> markAllRead(String userId);
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository(FirebaseFirestore.instance);
});

final studentNotificationsProvider =
    StreamProvider.autoDispose<List<StudentNotification>>((ref) {
      final userId = ref.watch(authControllerProvider).userId;
      if (userId == null || userId.isEmpty) {
        return Stream.value(const <StudentNotification>[]);
      }
      return ref.watch(notificationRepositoryProvider).watchForUser(userId);
    });

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref
          .watch(studentNotificationsProvider)
          .valueOrNull
          ?.where((item) => item.isUnread)
          .length ??
      0;
});

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  @override
  Stream<List<StudentNotification>> watchForUser(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(_fromDocument)
              .whereType<StudentNotification>()
              .toList(growable: false),
        );
  }

  @override
  Future<void> markRead({required String userId, required String id}) async {
    final reference = _notifications.doc(id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists || snapshot.data()?['userId'] != userId) return;
      if (snapshot.data()?['readAt'] != null) return;
      transaction.update(reference, {'readAt': FieldValue.serverTimestamp()});
    });
  }

  @override
  Future<void> markAllRead(String userId) async {
    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .limit(400)
        .get();
    final unread = snapshot.docs
        .where((doc) => doc.data()['readAt'] == null)
        .toList(growable: false);
    if (unread.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  StudentNotification? _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final type = _optionalString(data['type']) ?? 'information';
    final title = data['title']?.toString().trim() ?? '';
    final body = data['body']?.toString().trim() ?? '';

    // Les notifications localisées côté client (titre/corps composés à partir
    // d'un code de type + données) n'ont pas de texte stocké : on ne les rejette
    // pas pour cause de titre/corps vides.
    int? thresholdPercent;
    if (type == 'study_reserve_threshold') {
      final payload = data['data'];
      if (payload is Map) {
        final raw = payload['threshold'];
        if (raw is num) thresholdPercent = raw.round();
      }
    } else if (title.isEmpty || body.isEmpty) {
      return null;
    }

    return StudentNotification(
      id: document.id,
      title: title,
      body: body,
      route: _optionalString(data['route']),
      type: type,
      thresholdPercent: thresholdPercent,
      createdAt:
          _date(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      readAt: _date(data['readAt']),
    );
  }

  String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  DateTime? _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    String text => DateTime.tryParse(text),
    _ => null,
  };
}
