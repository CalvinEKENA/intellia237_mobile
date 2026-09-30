import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';

/// État d'une demande de suppression vu par son titulaire.
///
/// Politique : `docs/architecture/ACCOUNT_DELETION.md`. La demande ouvre un
/// délai de grâce de 7 jours pendant lequel le compte reste utilisable et la
/// demande annulable ; rien n'est effacé avant l'échéance.
class AccountDeletionState {
  const AccountDeletionState({required this.status, this.dueAt});

  static const none = AccountDeletionState(status: 'none');

  final String status;
  final DateTime? dueAt;

  bool get isScheduled => status == 'scheduled';

  /// Traitement commencé : il n'est plus annulable.
  bool get isInProgress =>
      status == 'processing' ||
      status == 'failed' ||
      status == 'needs_attention';

  static AccountDeletionState fromMap(Map<String, dynamic>? data) {
    if (data == null) return none;
    final status = data['status'];
    final dueAt = data['dueAt'];
    return AccountDeletionState(
      status: status is String ? status : 'none',
      dueAt: dueAt is Timestamp ? dueAt.toDate() : null,
    );
  }
}

class AccountDeletionService {
  AccountDeletionService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _firestore = firestore;

  final FirebaseFunctions _functions;
  final FirebaseFirestore? _firestore;

  /// Programme la suppression et renvoie son échéance.
  Future<DateTime?> requestDeletion() async {
    final result = await _functions
        .httpsCallable('requestAccountDeletion')
        .call<Object?>();
    final data = result.data;
    if (data is Map && data['dueAt'] is String) {
      return DateTime.tryParse(data['dueAt'] as String)?.toLocal();
    }
    return null;
  }

  Future<void> cancelDeletion() async {
    await _functions.httpsCallable('cancelAccountDeletion').call<Object?>();
  }

  Stream<AccountDeletionState> watch(String uid) {
    final firestore = _firestore ?? FirebaseFirestore.instance;
    return firestore
        .collection('account_deletion_requests')
        .doc(uid)
        .snapshots()
        .map((snapshot) => AccountDeletionState.fromMap(snapshot.data()));
  }
}

final accountDeletionServiceProvider = Provider<AccountDeletionService>(
  (ref) => AccountDeletionService(),
);

/// Demande de suppression du compte connecté, suivie en direct.
final accountDeletionStateProvider =
    StreamProvider.autoDispose<AccountDeletionState>((ref) {
      final uid = ref.watch(authControllerProvider.select((a) => a.userId));
      if (uid == null || uid.isEmpty) {
        return Stream.value(AccountDeletionState.none);
      }
      return ref
          .watch(accountDeletionServiceProvider)
          .watch(uid)
          .handleError((Object _) {});
    });
