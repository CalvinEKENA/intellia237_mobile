import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/application/phone_auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';
import 'package:intellia237/features/student_registration/application/student_registration_controller.dart';
import 'package:intellia237/features/student_registration/data/establishment_catalog.dart';
import 'package:intellia237/features/student_registration/data/firebase_student_registration_repository.dart';
import 'package:intellia237/features/student_registration/data/student_registration_repository.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/domain/student_registration_payload.dart';
import 'package:intellia237/features/student_registration/domain/student_registration_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'fresh phone learner completes and restores the reachable journey',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final authRepository = _JourneyAuthRepository();
      final phoneRepository = _JourneyPhoneRepository(authRepository);
      final registrationRepository = _JourneyRegistrationRepository(
        authRepository,
      );
      var container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          studentRegistrationRepositoryProvider.overrideWithValue(
            registrationRepository,
          ),
        ],
      );

      final phone = PhoneAuthController(
        repository: phoneRepository,
        linkCurrentUser: false,
      );
      await phone.sendCode('699123456');
      phoneRepository.dispatchCode();
      await phone.confirmCode('123456');
      expect(phone.state.stage, PhoneAuthStage.success);
      expect(
        await container
            .read(authControllerProvider.notifier)
            .adoptCurrentFirebaseSession(),
        isFalse,
        reason: 'a verified number alone must not invent a Firestore profile',
      );

      final registration = container.read(
        studentRegistrationControllerProvider.notifier,
      );
      registration
        ..setFirstName('Amina')
        ..setLastName('Ndi')
        ..setInterfaceLanguage(InterfaceLanguage.english);
      expect(registration.validateStep(0), isNull);
      registration.goToNextStep();

      final leclerc = EstablishmentSearch.query('Lecl').first.establishment;
      registration
        ..setSchoolClass(SchoolClass.sixieme)
        ..selectEstablishment(leclerc);
      expect(registration.validateStep(1), isNull);
      expect(
        container
            .read(studentRegistrationControllerProvider)
            .establishment
            ?.grantsPrivateAccess,
        isFalse,
      );
      registration.goToNextStep();

      registration.setSelectedTutorId('leo');
      expect(registration.validateStep(2), isNull);
      registration.goToNextStep();
      registration
        ..setAcceptedTerms(true)
        ..setAcceptedPrivacy(true)
        ..setAcceptedDataPolicy(true);

      expect(await registration.submit(), isTrue);
      registration.completeRegistration();
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
      expect(container.read(authControllerProvider).userId, 'learner-237');
      expect(registrationRepository.payload?.selectedTutorId, 'leo');
      expect(
        registrationRepository.payload?.establishment?.candidateId,
        leclerc.id,
      );

      final reachableJourney = <String>[
        AppRoutes.studentHome,
        AppRoutes.learnHub,
        AppRoutes.subjectDetail('maths'),
        AppRoutes.chapterDetail('maths', 'algebra'),
        AppRoutes.lessonViewer('maths', 'algebra', 'equations'),
        AppRoutes.quizHub,
        AppRoutes.quizPlay('quiz-1'),
        AppRoutes.aiCompanion,
        AppRoutes.editProfile,
      ];
      expect(reachableJourney, everyElement(startsWith('/')));

      await container.read(authControllerProvider.notifier).signOut();
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
      container.dispose();
      phone.close();

      phoneRepository.signInExistingPhone();
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
      );
      await container.read(authControllerProvider.notifier).completeBootstrap();
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
      expect(container.read(authControllerProvider).userId, 'learner-237');
      container.dispose();
    },
  );
}

class _JourneyPhoneRepository implements PhoneAuthRepository {
  _JourneyPhoneRepository(this.authRepository);

  final _JourneyAuthRepository authRepository;
  void Function(PhoneCodeDispatch)? _onCodeSent;

  void dispatchCode() => _onCodeSent!(
    const PhoneCodeDispatch(verificationId: 'journey-verification'),
  );

  void signInExistingPhone() => authRepository.phoneSessionActive = true;

  @override
  Future<void> startVerification({
    required String phoneNumber,
    required bool linkCurrentUser,
    int? forceResendingToken,
    required void Function(PhoneAuthSession session) onVerified,
    required void Function(PhoneAuthFailure failure) onFailed,
    required void Function(PhoneCodeDispatch dispatch) onCodeSent,
    required void Function(String verificationId) onAutoRetrievalTimeout,
  }) async {
    expect(phoneNumber, '+237699123456');
    _onCodeSent = onCodeSent;
  }

  @override
  Future<PhoneAuthSession> confirmCode({
    required String verificationId,
    required String smsCode,
    required bool linkCurrentUser,
  }) async {
    authRepository.phoneSessionActive = true;
    return const PhoneAuthSession(
      uid: 'learner-237',
      phoneNumber: '+237699123456',
      isNewUser: true,
      linkedToExistingUser: false,
    );
  }
}

class _JourneyRegistrationRepository implements StudentRegistrationRepository {
  _JourneyRegistrationRepository(this.authRepository);

  final _JourneyAuthRepository authRepository;
  StudentRegistrationPayload? payload;

  @override
  Future<StudentRegistrationResult> registerStudent(
    StudentRegistrationPayload payload,
  ) async {
    this.payload = payload;
    authRepository.profile = const AuthUserData(
      uid: 'learner-237',
      email: '',
      role: AppRole.student,
      firstName: 'Amina',
      lastName: 'Ndi',
      profileCompleted: true,
    );
    return const StudentRegistrationResult(
      uid: 'learner-237',
      email: '',
      firstName: 'Amina',
      lastName: 'Ndi',
    );
  }
}

class _JourneyAuthRepository implements AuthRepository {
  bool phoneSessionActive = false;
  AuthUserData? profile;

  @override
  Future<AuthUserData?> getCurrentUser() async =>
      phoneSessionActive ? profile : null;

  @override
  Future<void> signOut() async => phoneSessionActive = false;

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) async => profile!;

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) async => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}
