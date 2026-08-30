import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_registration/data/firebase_student_registration_repository.dart';
import 'package:intellia237/features/student_registration/data/student_registration_gateways.dart';
import 'package:intellia237/features/student_registration/data/student_registration_repository.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/domain/learning_goal.dart';
import 'package:intellia237/features/student_registration/domain/registration_diagnostic.dart';
import 'package:intellia237/features/student_registration/domain/student_registration_payload.dart';

void main() {
  test('registration diagnostics expose every neutral operation category', () {
    expect(RegistrationOperation.values.map((item) => item.code), [
      'AUTH_CREATE',
      'USER_DOC_CREATE',
      'USER_DOC_UPDATE',
      'PROFILE_CREATE',
      'PROFILE_UPDATE',
      'APP_CHECK',
      'NETWORK',
      'UNKNOWN',
    ]);
  });

  test('payload exposes exact create fields and protected retry fields', () {
    final payload = _payload();
    final now = DateTime.utc(2026, 8, 30, 8);

    expect(payload.toUserDocument(uid: 'student', now: now).keys, {
      'uid',
      'firstName',
      'lastName',
      'email',
      'role',
      'classLevel',
      'series',
      'tutorId',
      'profileCompleted',
      'tourGuideSeen',
      'createdAt',
      'updatedAt',
    });
    final profile = payload.toStudentProfileDocument(uid: 'student', now: now);
    expect(profile.keys, {
      'uid',
      'firstName',
      'lastName',
      'email',
      'classLevel',
      'series',
      'points',
      'level',
      'streak',
      'tutorId',
      'preferences',
      'consents',
      'profileCompleted',
      'createdAt',
      'updatedAt',
    });
    expect(profile['points'], 0);
    expect(profile['level'], 1);
    expect(
      (profile['preferences'] as Map<String, dynamic>).keys,
      containsAll({
        'interfaceLanguage',
        'educationalSubsystem',
        'educationType',
        'streamOrSpeciality',
        'accountLinkage',
        'establishmentCandidate',
      }),
    );

    final userUpdate = payload.toUserUpdateDocument(now: now);
    final profileUpdate = payload.toStudentProfileUpdateDocument(now: now);
    expect(
      userUpdate.keys,
      isNot(containsAll({'role', 'createdAt', 'establishmentId'})),
    );
    expect(
      profileUpdate.keys,
      isNot(containsAll({'points', 'level', 'createdAt', 'establishmentId'})),
    );
  });

  test(
    'new Auth user and absent documents create a complete registration',
    () async {
      final auth = _FakeAuthGateway();
      final store = _FakeDocumentStore();
      final repository = FirebaseStudentRegistrationRepository(
        authGateway: auth,
        documentStore: store,
      );

      final result = await repository.registerStudent(_payload());

      expect(result.uid, 'student-uid');
      expect(auth.createCalls, 1);
      expect(store.userOperations, [RegistrationOperation.userDocumentCreate]);
      expect(store.profileOperations, [RegistrationOperation.profileCreate]);
    },
  );

  test(
    'existing Auth user with absent documents resumes without Auth create',
    () async {
      final auth = _FakeAuthGateway(currentUser: _FakeAuthUser());
      final store = _FakeDocumentStore();
      final repository = FirebaseStudentRegistrationRepository(
        authGateway: auth,
        documentStore: store,
      );

      await repository.registerStudent(_payload());

      expect(auth.createCalls, 0);
      expect(
        store.userOperations.single,
        RegistrationOperation.userDocumentCreate,
      );
      expect(
        store.profileOperations.single,
        RegistrationOperation.profileCreate,
      );
    },
  );

  test('Auth record without a current session signs in and resumes', () async {
    final auth = _FakeAuthGateway(emailAlreadyInUse: true);
    final store = _FakeDocumentStore();
    final repository = FirebaseStudentRegistrationRepository(
      authGateway: auth,
      documentStore: store,
    );

    await repository.registerStudent(_payload());

    expect(auth.createCalls, 1);
    expect(auth.signInCalls, 1);
    expect(store.profileOperations.single, RegistrationOperation.profileCreate);
  });

  test(
    'existing user/profile and double-submit use update-only payloads',
    () async {
      final auth = _FakeAuthGateway(currentUser: _FakeAuthUser());
      final store = _FakeDocumentStore(userExists: true, profileExists: true);
      final repository = FirebaseStudentRegistrationRepository(
        authGateway: auth,
        documentStore: store,
      );

      await repository.registerStudent(_payload());
      await repository.registerStudent(_payload());

      expect(store.userOperations, [
        RegistrationOperation.userDocumentUpdate,
        RegistrationOperation.userDocumentUpdate,
      ]);
      expect(store.profileOperations, [
        RegistrationOperation.profileUpdate,
        RegistrationOperation.profileUpdate,
      ]);
      expect(store.lastUserUpdate, isNot(contains('role')));
      expect(store.lastProfileUpdate, isNot(contains('points')));
      expect(store.lastProfileUpdate, isNot(contains('level')));
    },
  );

  test('partial profile after a failed first submit is recoverable', () async {
    final auth = _FakeAuthGateway(currentUser: _FakeAuthUser());
    final store = _FakeDocumentStore(userExists: true, profileExists: false);
    final repository = FirebaseStudentRegistrationRepository(
      authGateway: auth,
      documentStore: store,
    );

    await repository.registerStudent(_payload());
    expect(
      store.userOperations.single,
      RegistrationOperation.userDocumentUpdate,
    );
    expect(store.profileOperations.single, RegistrationOperation.profileCreate);
  });

  test(
    'neutral diagnostic identifies the failing write without personal data',
    () async {
      final auth = _FakeAuthGateway(currentUser: _FakeAuthUser());
      final store = _FakeDocumentStore(
        userExists: true,
        profileExists: true,
        profileFailure: const RegistrationWriteFailure(
          operation: RegistrationOperation.profileUpdate,
          code: 'permission-denied',
        ),
      );
      final repository = FirebaseStudentRegistrationRepository(
        authGateway: auth,
        documentStore: store,
        projectId: 'edunova-aabd1',
      );

      await expectLater(
        repository.registerStudent(_payload()),
        throwsA(
          isA<StudentRegistrationException>()
              .having(
                (error) => error.registrationOperation,
                'registrationOperation',
                'PROFILE_UPDATE',
              )
              .having(
                (error) => error.diagnosticId,
                'diagnosticId',
                'DATA-PERM-101',
              )
              .having(
                (error) => error.message,
                'no email',
                isNot(contains('amina.ndi@example.com')),
              ),
        ),
      );
    },
  );

  test('network and App Check failures have distinct operations', () async {
    final auth = _FakeAuthGateway(currentUser: _FakeAuthUser());

    Future<StudentRegistrationException> failureFor(
      RegistrationWriteFailure failure,
    ) async {
      final repository = FirebaseStudentRegistrationRepository(
        authGateway: auth,
        documentStore: _FakeDocumentStore(
          userExists: true,
          profileExists: true,
          profileFailure: failure,
        ),
      );
      try {
        await repository.registerStudent(_payload());
      } on StudentRegistrationException catch (error) {
        return error;
      }
      throw StateError('Expected registration failure.');
    }

    final network = await failureFor(
      const RegistrationWriteFailure(
        operation: RegistrationOperation.profileUpdate,
        code: 'unavailable',
      ),
    );
    expect(network.registrationOperation, 'NETWORK');

    final appCheck = await failureFor(
      const RegistrationWriteFailure(
        operation: RegistrationOperation.profileUpdate,
        code: 'failed-precondition',
        technicalMessage: 'App Check token rejected',
      ),
    );
    expect(appCheck.registrationOperation, 'APP_CHECK');
  });
}

StudentRegistrationPayload _payload() => const StudentRegistrationPayload(
  firstName: 'Amina',
  lastName: 'Ndi',
  schoolClass: SchoolClass.terminale,
  schoolSeries: SchoolSeries.d,
  interfaceLanguage: InterfaceLanguage.french,
  educationalSubsystem: EducationalSubsystem.francophone,
  educationType: EducationType.general,
  establishment: EstablishmentAffiliation(name: 'Lycée de la Réunification'),
  accountLinkage: LearnerAccountLinkage.individual,
  selectedTutorId: 'leo',
  preferredSubjects: ['Mathématiques', 'Sciences'],
  difficultSubjects: ['Anglais'],
  learningGoal: LearningGoal.examMastery,
  dailyStudyMinutes: 45,
  email: 'amina.ndi@example.com',
  password: 'MotDePasse!237',
  acceptedTerms: true,
  acceptedPrivacy: true,
  acceptedDataPolicy: true,
);

class _FakeAuthGateway implements RegistrationAuthGateway {
  _FakeAuthGateway({this.currentUser, this.emailAlreadyInUse = false});

  @override
  _FakeAuthUser? currentUser;
  final bool emailAlreadyInUse;
  int createCalls = 0;
  int signInCalls = 0;

  @override
  Future<RegistrationAuthUser?> createUser({
    required String email,
    required String password,
  }) async {
    createCalls += 1;
    if (emailAlreadyInUse) {
      throw const RegistrationAuthFailure(code: 'email-already-in-use');
    }
    return currentUser = _FakeAuthUser(email: email);
  }

  @override
  Future<RegistrationAuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    return currentUser = _FakeAuthUser(email: email);
  }
}

class _FakeAuthUser implements RegistrationAuthUser {
  _FakeAuthUser({this.email = 'amina.ndi@example.com'});

  @override
  final String? email;

  @override
  bool get emailVerified => true;

  @override
  String get uid => 'student-uid';

  @override
  Future<void> delete() async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> updateDisplayName(String displayName) async {}
}

class _FakeDocumentStore implements RegistrationDocumentStore {
  _FakeDocumentStore({
    this.userExists = false,
    this.profileExists = false,
    this.profileFailure,
  });

  bool userExists;
  bool profileExists;
  final RegistrationWriteFailure? profileFailure;
  final userOperations = <RegistrationOperation>[];
  final profileOperations = <RegistrationOperation>[];
  Map<String, dynamic>? lastUserUpdate;
  Map<String, dynamic>? lastProfileUpdate;

  @override
  Future<RegistrationOperation> upsertUser({
    required String uid,
    required Map<String, dynamic> createData,
    required Map<String, dynamic> updateData,
  }) async {
    lastUserUpdate = updateData;
    final operation = userExists
        ? RegistrationOperation.userDocumentUpdate
        : RegistrationOperation.userDocumentCreate;
    userExists = true;
    userOperations.add(operation);
    return operation;
  }

  @override
  Future<RegistrationOperation> upsertProfile({
    required String uid,
    required Map<String, dynamic> createData,
    required Map<String, dynamic> updateData,
  }) async {
    if (profileFailure != null) throw profileFailure!;
    lastProfileUpdate = updateData;
    final operation = profileExists
        ? RegistrationOperation.profileUpdate
        : RegistrationOperation.profileCreate;
    profileExists = true;
    profileOperations.add(operation);
    return operation;
  }
}
