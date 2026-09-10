import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../../learn/application/learn_providers.dart';
import '../../learn/data/student_academic_profile_source.dart';
import '../../learn/domain/learn_subject.dart';
import '../../parent/application/parent_providers.dart';
import '../../student_registration/domain/academic_level_identity.dart';
import '../../tutor/application/tutor_preference_provider.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../data/mastery_repository.dart';
import '../domain/mastery_policy.dart';

final masteryRepositoryProvider = Provider<MasteryRepository>((ref) {
  return FirestoreMasteryRepository();
});

final masteryClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final profileCompanionProvider =
    Provider.autoDispose<AsyncValue<TutorPersona?>>((ref) {
      try {
        return AsyncData(ref.watch(selectedTutorProvider));
      } catch (error, stack) {
        return AsyncError(error, stack);
      }
    });

/// Both viewer and learner participate in the provider key. Comparisons are
/// kept only for this subscription and never shared between accounts.
typedef MasteryScope = ({String viewerId, String learnerId});

final learnerMasteryProvider = StreamProvider.autoDispose
    .family<MasteryProfile, MasteryScope>((ref, scope) {
      final session = MasterySession();
      final clock = ref.watch(masteryClockProvider);
      final repository = ref.watch(masteryRepositoryProvider);
      // Re-evaluate at expiry without requiring a network event or retaining
      // an estimate indefinitely while this screen stays open.
      final output = StreamController<MasteryProfile>();
      Timer? expiry;
      final subscription = repository
          .watchQuizEvidence(scope.learnerId)
          .listen(
            (records) {
              void emit() {
                expiry?.cancel();
                final now = clock();
                final profile = session.update(records, now: now);
                output.add(profile);
                if (profile.evidence.isNotEmpty) {
                  final oldest = profile.evidence.last.recordedAt;
                  final next = oldest
                      .add(MasteryCalibration.evidenceWindow)
                      .add(const Duration(milliseconds: 1));
                  expiry = Timer(next.difference(now), emit);
                }
              }

              emit();
            },
            onError: (Object error, StackTrace stack) {
              expiry?.cancel();
              output.addError(error, stack);
            },
          );
      ref.onDispose(() {
        expiry?.cancel();
        unawaited(subscription.cancel());
        unawaited(output.close());
      });
      return output.stream;
    });

void refreshMastery(WidgetRef ref, String learnerId) {
  final viewer = ref.read(authControllerProvider).userId;
  if (viewer != null) {
    ref.invalidate(
      learnerMasteryProvider((viewerId: viewer, learnerId: learnerId)),
    );
  }
}

final studentMasteryProvider = Provider.autoDispose<AsyncValue<MasteryProfile>>(
  (ref) {
    final auth = ref.watch(authControllerProvider);
    final id = auth.userId;
    if (!auth.isAuthenticated || auth.role != AppRole.student || id == null) {
      return const AsyncData(MasteryProfile());
    }
    return ref.watch(learnerMasteryProvider((viewerId: id, learnerId: id)));
  },
);

/// The existing approved-link dashboard is the entry gate. Firestore remains
/// the authority; this guard does not grant any new read permission.
final parentMasteryProvider = Provider.autoDispose
    .family<AsyncValue<MasteryProfile>, String>((ref, childId) {
      final auth = ref.watch(authControllerProvider);
      final dashboard = ref.watch(parentDashboardProvider);
      final viewer = auth.userId;
      if (!auth.isAuthenticated ||
          auth.role != AppRole.parent ||
          viewer == null) {
        return const AsyncData(MasteryProfile());
      }
      if (dashboard.hasError) {
        return AsyncError(dashboard.error!, dashboard.stackTrace!);
      }
      if (dashboard.isLoading || !dashboard.hasValue) {
        return const AsyncLoading();
      }
      if (!dashboard.requireValue.children.any(
        (child) => child.id == childId,
      )) {
        return const AsyncData(MasteryProfile());
      }
      return ref.watch(
        learnerMasteryProvider((viewerId: viewer, learnerId: childId)),
      );
    });

/// Names come from the real class catalog, never from fuzzy quiz-title or
/// subject-label matching. This optional provider fails independently.
final parentMasterySubjectsProvider = FutureProvider.autoDispose
    .family<List<LearnSubject>, String>((ref, childId) async {
      final auth = ref.watch(authControllerProvider);
      if (!auth.isAuthenticated || auth.role != AppRole.parent) return const [];
      final child = await ref.watch(parentChildByIdProvider(childId).future);
      if (child == null) return const [];
      final identity = AcademicLevelIdentity.resolve(
        storedClassLevel: child.classLevel,
      );
      if (identity == null) return const [];
      return ref
          .watch(learnRepositoryProvider)
          .fetchSubjects(
            userId: child.id,
            classLevel: identity.catalogKey,
            series: child.series,
          );
    });

/// Optional identity detail without altering the global academic bootstrap.
/// This is the learner-declared establishment, not verified affiliation.
final profileDeclaredEstablishmentProvider =
    FutureProvider.autoDispose<String?>((ref) async {
      final auth = ref.watch(authControllerProvider);
      final id = auth.userId;
      if (!auth.isAuthenticated || auth.role != AppRole.student || id == null) {
        return null;
      }
      final data = await ref
          .watch(studentAcademicProfileSourceProvider)
          .fetch(id);
      final preferences = data['preferences'];
      final candidate = preferences is Map
          ? preferences['establishmentCandidate']
          : null;
      final name = candidate is Map ? candidate['name'] : null;
      return name is String && name.trim().isNotEmpty ? name.trim() : null;
    });
