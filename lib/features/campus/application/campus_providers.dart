import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo/demo_campus_fixtures.dart';
import '../data/repositories/demo_campus_repository.dart';
import '../domain/models/campus_attention_item.dart';
import '../domain/models/campus_audit_event.dart';
import '../domain/models/campus_class.dart';
import '../domain/models/campus_communication.dart';
import '../domain/models/campus_context.dart';
import '../domain/models/campus_pagination.dart';
import '../domain/models/campus_permissions.dart';
import '../domain/models/campus_program.dart';
import '../domain/models/campus_quiz.dart';
import '../domain/models/campus_resource.dart';
import '../domain/models/campus_roles.dart';
import '../domain/models/campus_staff.dart';
import '../domain/models/campus_student.dart';
import '../domain/repositories/campus_repository_contracts.dart';

/// Navigation section identifiers for INTELLIA Campus.
enum CampusNavSection {
  overview,
  today, // Teacher home
  program,
  classes,
  students,
  staff,
  evaluations,
  studio,
  communications,
  reports,
  administration,
}

/// Active establishment context provider.
///
/// Can be switched or reset per session.
final campusContextProvider =
    StateNotifierProvider<CampusContextNotifier, CampusContext>((ref) {
      return CampusContextNotifier();
    });

class CampusContextNotifier extends StateNotifier<CampusContext> {
  CampusContextNotifier() : super(DemoCampusFixtures.defaultContext);

  void switchRole(CampusRole newRole) {
    final newMembership = EstablishmentMembership(
      membershipId: 'mem_${newRole.name}_01',
      userId: 'user_switch_${newRole.name}',
      establishmentId: state.establishmentId,
      role: newRole,
      status: MembershipStatus.active,
      grantedScopes: CampusScopes.defaultScopesForRole(newRole),
      assignedClassIds: newRole == CampusRole.teacher
          ? const ['class_tc1', 'class_pc']
          : const [],
      assignedSubjectIds: newRole == CampusRole.teacher
          ? const ['MATH']
          : const [],
    );

    state = state.copyWith(activeMembership: newMembership);
  }

  void switchSubsystem(SubsystemType subsystem) {
    state = state.copyWith(subsystems: [subsystem]);
  }
}

/// Active navigation tab provider within the Campus Shell.
final campusActiveNavProvider = StateProvider<CampusNavSection>((ref) {
  final context = ref.watch(campusContextProvider);
  return context.isTeacher ? CampusNavSection.today : CampusNavSection.overview;
});

/// Singleton demo repository instance for in-memory operations.
final campusRepositoryProvider = Provider<DemoCampusRepository>((ref) {
  return DemoCampusRepository();
});

/// Direction attention items provider.
final campusAttentionItemsProvider = FutureProvider<List<CampusAttentionItem>>((
  ref,
) async {
  final context = ref.watch(campusContextProvider);
  final repo = ref.watch(campusRepositoryProvider);
  return repo.getAttentionItems(context.establishmentId);
});

/// Direction KPI summary provider.
final campusDirectionKpisProvider = FutureProvider<DirectionKpiSummary>((
  ref,
) async {
  final context = ref.watch(campusContextProvider);
  final repo = ref.watch(campusRepositoryProvider);
  return repo.getDirectionKpis(context.establishmentId);
});

/// Classes list provider (filtered if current membership is a teacher).
final campusClassesProvider = FutureProvider<List<CampusClass>>((ref) async {
  final context = ref.watch(campusContextProvider);
  final repo = ref.watch(campusRepositoryProvider);
  final allClasses = await repo.getClasses(context.establishmentId);

  // If teacher, only display assigned classes
  if (context.isTeacher) {
    final assigned = context.activeMembership.assignedClassIds;
    if (assigned.isNotEmpty) {
      return allClasses.where((c) => assigned.contains(c.id)).toList();
    }
  }
  return allClasses;
});

/// Class detail provider family.
final campusClassDetailProvider =
    FutureProvider.family<CampusClassDetail?, String>((ref, classId) async {
      final context = ref.watch(campusContextProvider);
      final repo = ref.watch(campusRepositoryProvider);
      return repo.getClassDetail(context.establishmentId, classId);
    });

/// Students list state with pagination parameters.
class CampusStudentsFilterState {
  final String? classId;
  final String searchQuery;
  final LearnerEvidenceStatus? evidenceFilter;
  final int pageIndex;

  const CampusStudentsFilterState({
    this.classId,
    this.searchQuery = '',
    this.evidenceFilter,
    this.pageIndex = 1,
  });

  CampusStudentsFilterState copyWith({
    String? classId,
    String? searchQuery,
    LearnerEvidenceStatus? evidenceFilter,
    int? pageIndex,
  }) {
    return CampusStudentsFilterState(
      classId: classId ?? this.classId,
      searchQuery: searchQuery ?? this.searchQuery,
      evidenceFilter: evidenceFilter ?? this.evidenceFilter,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }
}

final campusStudentsFilterProvider = StateProvider<CampusStudentsFilterState>((
  ref,
) {
  return const CampusStudentsFilterState();
});

final campusStudentsProvider = FutureProvider<CampusPage<CampusStudent>>((
  ref,
) async {
  final context = ref.watch(campusContextProvider);
  final repo = ref.watch(campusRepositoryProvider);
  final filter = ref.watch(campusStudentsFilterProvider);

  return repo.getStudents(
    establishmentId: context.establishmentId,
    classId: filter.classId,
    searchQuery: filter.searchQuery,
    evidenceFilter: filter.evidenceFilter,
    pageIndex: filter.pageIndex,
  );
});

final campusStudentDetailProvider =
    FutureProvider.family<CampusStudentDetail?, String>((ref, studentId) async {
      final context = ref.watch(campusContextProvider);
      final repo = ref.watch(campusRepositoryProvider);
      return repo.getStudentDetail(
        establishmentId: context.establishmentId,
        studentId: studentId,
      );
    });

/// Staff list provider.
final campusStaffProvider = FutureProvider<List<CampusStaffMember>>((
  ref,
) async {
  final context = ref.watch(campusContextProvider);
  final repo = ref.watch(campusRepositoryProvider);
  return repo.getStaff(context.establishmentId);
});

/// Teaching plan provider.
final campusTeachingPlanProvider =
    FutureProvider.family<List<EstablishmentTeachingPlanItem>, String?>((
      ref,
      classId,
    ) async {
      final context = ref.watch(campusContextProvider);
      final repo = ref.watch(campusRepositoryProvider);
      return repo.getTeachingPlan(
        establishmentId: context.establishmentId,
        classId: classId,
      );
    });

/// Studio resources provider.
final campusStudioResourcesProvider = FutureProvider<List<CampusResource>>((
  ref,
) async {
  final context = ref.watch(campusContextProvider);
  final repo = ref.watch(campusRepositoryProvider);
  return repo.getResources(context.establishmentId);
});

/// Quiz drafts provider.
final campusQuizDraftsProvider = FutureProvider<List<CampusQuizDraft>>((
  ref,
) async {
  final context = ref.watch(campusContextProvider);
  final repo = ref.watch(campusRepositoryProvider);
  return repo.getQuizDrafts(context.establishmentId);
});

/// Announcements provider.
final campusAnnouncementsProvider = FutureProvider<List<CampusAnnouncement>>((
  ref,
) async {
  final context = ref.watch(campusContextProvider);
  final repo = ref.watch(campusRepositoryProvider);
  return repo.getAnnouncements(context.establishmentId);
});

/// Audit events provider.
final campusAuditEventsProvider = FutureProvider<List<CampusAuditEvent>>((
  ref,
) async {
  final context = ref.watch(campusContextProvider);
  final repo = ref.watch(campusRepositoryProvider);
  return repo.getAuditEvents(context.establishmentId);
});
