import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/onboarding/data/onboarding_preferences.dart';
import 'package:intellia237/features/parent_registration/application/parent_registration_controller.dart';
import 'package:intellia237/features/role_registration/data/firebase_role_registration_repository.dart';
import 'package:intellia237/features/role_registration/data/role_registration_repository.dart';
import 'package:intellia237/features/role_registration/domain/admin_registration_payload.dart';
import 'package:intellia237/features/role_registration/domain/parent_registration_payload.dart';
import 'package:intellia237/features/role_registration/domain/registration_result.dart';
import 'package:intellia237/features/role_registration/domain/teacher_registration_payload.dart';
import 'package:intellia237/features/student_registration/application/student_registration_controller.dart';
import 'package:intellia237/features/student_registration/data/firebase_student_registration_repository.dart';
import 'package:intellia237/features/student_registration/data/student_registration_repository.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/domain/student_registration_payload.dart';
import 'package:intellia237/features/student_registration/domain/student_registration_result.dart';

void main() {
  test(
    'student registration persists its payload and authenticates the student',
    () async {
      final repository = _StudentRegistrationRepository();
      final container = _container(
        studentRepository: repository,
        roleRepository: _RoleRegistrationRepository(),
      );
      addTearDown(container.dispose);

      final controller = container.read(
        studentRegistrationControllerProvider.notifier,
      );
      controller
        ..setFirstName('Amina')
        ..setLastName('Ndi')
        ..setSchoolClass(SchoolClass.terminale)
        ..setSchoolSeries(SchoolSeries.d)
        ..setSelectedTutorId('kira')
        ..setEmail('amina@example.com')
        ..setPassword('password8')
        ..setConfirmPassword('password8')
        ..setAcceptedTerms(true)
        ..setAcceptedPrivacy(true)
        ..setAcceptedDataPolicy(true);

      expect(await controller.submit(), isTrue);
      expect(repository.payload, isNotNull);
      expect(repository.payload!.schoolClass, SchoolClass.terminale);
      expect(repository.payload!.schoolSeries, SchoolSeries.d);
      expect(repository.payload!.selectedTutorId, 'kira');
      final now = DateTime.utc(2026, 6, 27);
      final userDocument = repository.payload!.toUserDocument(
        uid: 'student-uid',
        now: now,
      );
      final profileDocument = repository.payload!.toStudentProfileDocument(
        uid: 'student-uid',
        now: now,
      );
      expect(userDocument.containsKey('establishmentId'), isFalse);
      expect(profileDocument.containsKey('establishmentId'), isFalse);
      expect(profileDocument.containsKey('establishmentName'), isFalse);
      expect(
        container.read(studentRegistrationControllerProvider).isCompleted,
        isTrue,
      );
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.bootstrapping,
      );

      controller.completeRegistration();
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
      expect(container.read(authControllerProvider).role, AppRole.student);
    },
  );

  test(
    'student success remains hidden when profile persistence fails',
    () async {
      final repository = _StudentRegistrationRepository(
        error: const StudentRegistrationException(
          message: 'Le profil n’a pas pu être finalisé.',
          code: 'permission-denied',
        ),
      );
      final container = _container(
        studentRepository: repository,
        roleRepository: _RoleRegistrationRepository(),
      );
      addTearDown(container.dispose);
      final controller = container.read(
        studentRegistrationControllerProvider.notifier,
      );
      controller
        ..setFirstName('Amina')
        ..setLastName('Ndi')
        ..setSchoolClass(SchoolClass.sixieme)
        ..setSelectedTutorId('kira')
        ..setEmail('amina@example.com')
        ..setPassword('password8')
        ..setConfirmPassword('password8')
        ..setAcceptedTerms(true)
        ..setAcceptedPrivacy(true)
        ..setAcceptedDataPolicy(true);

      expect(await controller.submit(), isFalse);
      expect(
        container.read(studentRegistrationControllerProvider).isCompleted,
        isFalse,
      );
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.bootstrapping,
      );
    },
  );

  test(
    'parent registration accepts no child link and authenticates the parent',
    () async {
      final repository = _RoleRegistrationRepository();
      final container = _container(
        studentRepository: _StudentRegistrationRepository(),
        roleRepository: repository,
      );
      addTearDown(container.dispose);

      final controller = container.read(
        parentRegistrationControllerProvider.notifier,
      );
      controller
        ..setFirstName('Nadine')
        ..setLastName('Meka')
        ..setEmail('nadine@example.com')
        ..setPassword('password8')
        ..setConfirmPassword('password8')
        ..setAcceptedTerms(true)
        ..setAcceptedPrivacy(true);

      expect(await controller.submit(), isTrue);
      expect(repository.parentPayload, isNotNull);
      expect(repository.parentPayload!.childIdentifiers, isEmpty);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
      expect(container.read(authControllerProvider).role, AppRole.parent);
    },
  );
}

ProviderContainer _container({
  required StudentRegistrationRepository studentRepository,
  required RoleRegistrationRepository roleRepository,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_AuthRepository()),
      hasSeenOnboardingProvider.overrideWith((ref) => true),
      studentRegistrationRepositoryProvider.overrideWithValue(
        studentRepository,
      ),
      roleRegistrationRepositoryProvider.overrideWithValue(roleRepository),
    ],
  );
}

class _StudentRegistrationRepository implements StudentRegistrationRepository {
  _StudentRegistrationRepository({this.error});

  final StudentRegistrationException? error;
  StudentRegistrationPayload? payload;

  @override
  Future<StudentRegistrationResult> registerStudent(
    StudentRegistrationPayload payload,
  ) async {
    if (error != null) throw error!;
    this.payload = payload;
    return StudentRegistrationResult(
      uid: 'student-uid',
      email: payload.email,
      firstName: payload.firstName,
      lastName: payload.lastName,
    );
  }
}

class _RoleRegistrationRepository implements RoleRegistrationRepository {
  ParentRegistrationPayload? parentPayload;

  @override
  Future<RoleRegistrationResult> registerParent(
    ParentRegistrationPayload payload,
  ) async {
    parentPayload = payload;
    return RoleRegistrationResult(
      uid: 'parent-uid',
      email: payload.email,
      firstName: payload.firstName,
      lastName: payload.lastName,
    );
  }

  @override
  Future<RoleRegistrationResult> registerAdmin(
    AdminRegistrationPayload payload,
  ) => throw UnimplementedError();

  @override
  Future<RoleRegistrationResult> registerTeacher(
    TeacherRegistrationPayload payload,
  ) => throw UnimplementedError();
}

class _AuthRepository implements AuthRepository {
  @override
  Future<AuthUserData?> getCurrentUser() async => null;

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();
}
