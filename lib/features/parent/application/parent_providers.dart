import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/mock_parent_repository.dart';
import '../data/parent_repository.dart';
import '../domain/parent_child_profile.dart';
import '../domain/parent_dashboard.dart';

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return MockParentRepository();
});

final parentDashboardProvider = FutureProvider<ParentDashboard>((ref) async {
  final uid = ref.watch(authControllerProvider).userId ?? 'demo-parent';
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
