import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_parent_repository.dart';
import '../data/parent_repository.dart';
import '../domain/parent_child_profile.dart';
import '../domain/parent_dashboard.dart';
import 'parent_preview.dart';

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return FirestoreParentRepository();
});

final parentDashboardProvider = FutureProvider<ParentDashboard>((ref) async {
  // UID effectif : celui du parent prévisualisé quand le super-admin est en
  // mode prévisualisation, sinon l'utilisateur authentifié lui-même.
  final uid = ref.watch(effectiveParentUidProvider);
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
