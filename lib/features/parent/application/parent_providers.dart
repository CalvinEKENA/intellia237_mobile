import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_user_id.dart';
import '../data/firestore_parent_repository.dart';
import '../data/parent_repository.dart';
import '../domain/parent_child_profile.dart';
import '../domain/parent_dashboard.dart';

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return FirestoreParentRepository();
});

final parentDashboardProvider = FutureProvider<ParentDashboard>((ref) async {
  final uid = requireAuthenticatedUserId(ref.watch(authControllerProvider));
  return ref.read(parentRepositoryProvider).fetchDashboard(parentUid: uid);
});

final parentChildByIdProvider =
    FutureProvider.family<ParentChildProfile?, String>((ref, childId) async {
      final dashboard = await ref.watch(parentDashboardProvider.future);
      for (final child in dashboard.children) {
        if (child.id == childId) {
          return child;
        }
      }
      return null;
    });
