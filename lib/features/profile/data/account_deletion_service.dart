import 'package:cloud_functions/cloud_functions.dart';

class AccountDeletionService {
  AccountDeletionService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  Future<void> requestDeletion() async {
    await _functions.httpsCallable('requestAccountDeletion').call<void>();
  }
}
