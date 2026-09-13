import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_providers.dart';

final adminAccountManagementProvider = Provider(
  (ref) => AdminAccountManagementService(ref),
);

class AdminAccountManagementService {
  AdminAccountManagementService(this._ref);
  final Ref _ref;

  Future<void> execute(Map<String, Object> data) async {
    await FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    ).httpsCallable('manageAccount').call<void>(data);
    _ref.invalidate(adminDashboardProvider);
    _ref.invalidate(adminPendingReviewsProvider);
    _ref.invalidate(adminUnattachedStaffProvider);
    _ref.invalidate(schoolDirectoryProvider);
  }
}
