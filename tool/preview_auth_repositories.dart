// Local visual-preview adapters. Production entry points must never import tool/.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:intellia237/features/auth/data/repositories/firebase_phone_auth_repository.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';
import 'package:intellia237/features/role_registration/data/firebase_role_registration_repository.dart';
import 'package:intellia237/features/role_registration/data/role_registration_repository.dart';
import 'package:intellia237/features/role_registration/domain/admin_registration_payload.dart';
import 'package:intellia237/features/role_registration/domain/parent_registration_payload.dart';
import 'package:intellia237/features/role_registration/domain/registration_result.dart';
import 'package:intellia237/features/role_registration/domain/teacher_registration_payload.dart';
import 'package:intellia237/features/student_registration/data/firebase_student_registration_repository.dart';
import 'package:intellia237/features/student_registration/data/student_registration_repository.dart';
import 'package:intellia237/features/student_registration/domain/student_registration_payload.dart';
import 'package:intellia237/features/student_registration/domain/student_registration_result.dart';

const previewPhone = '699123456';
const previewOtp = '123456';
const previewEmail = 'demo@intellia.test';
const previewPassword = 'Intellia237!';

/// Session exists only in this process; no SDK, HTTP or persistent storage here.
class PreviewAuthMemory {
  AuthUserData? user;
  bool teacherPending = false;
  String? _phone;
  String? _verificationId;
  int _dispatch = 0;

  void clear() {
    user = null;
    teacherPending = false;
    _phone = null;
    _verificationId = null;
  }

  List<Override> get overrides => [
    authRepositoryProvider.overrideWithValue(_PreviewAuthRepository(this)),
    phoneAuthRepositoryProvider.overrideWithValue(
      _PreviewPhoneRepository(this),
    ),
    studentRegistrationRepositoryProvider.overrideWithValue(
      _PreviewStudentRepository(this),
    ),
    roleRegistrationRepositoryProvider.overrideWithValue(
      _PreviewRoleRepository(this),
    ),
  ];

  AuthUserData remember({
    required AppRole role,
    required String firstName,
    required String lastName,
    required String email,
  }) {
    final value = AuthUserData(
      uid: 'local-preview-${role.name}',
      email: email.isEmpty ? previewEmail : email,
      role: role,
      firstName: firstName,
      lastName: lastName,
      profileCompleted: true,
    );
    user = value;
    teacherPending = role == AppRole.teacher;
    return value;
  }
}

class _PreviewPhoneRepository implements PhoneAuthRepository {
  const _PreviewPhoneRepository(this.memory);
  final PreviewAuthMemory memory;

  @override
  Future<void> startVerification({
    required String phoneNumber,
    required bool linkCurrentUser,
    int? forceResendingToken,
    required void Function(PhoneAuthSession) onVerified,
    required void Function(PhoneAuthFailure) onFailed,
    required void Function(PhoneCodeDispatch) onCodeSent,
    required void Function(String) onAutoRetrievalTimeout,
  }) async {
    // This dispatch is visibly labelled a simulation by the preview shell.
    // No SMS is sent and no Firebase credential is created.
    memory._phone = phoneNumber;
    final verificationId = 'local-preview-code-${++memory._dispatch}';
    memory._verificationId = verificationId;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    onCodeSent(PhoneCodeDispatch(verificationId: verificationId));
  }

  @override
  Future<PhoneAuthSession> confirmCode({
    required String verificationId,
    required String smsCode,
    required bool linkCurrentUser,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (verificationId != memory._verificationId) {
      throw const PhoneAuthFailure('session-expired');
    }
    if (smsCode != previewOtp) {
      throw const PhoneAuthFailure('invalid-verification-code');
    }
    return PhoneAuthSession(
      uid: 'local-preview-phone',
      phoneNumber: memory._phone,
      isNewUser: memory.user == null,
      linkedToExistingUser: false,
    );
  }
}

class _PreviewAuthRepository implements AuthRepository {
  const _PreviewAuthRepository(this.memory);
  final PreviewAuthMemory memory;

  @override
  Future<AuthUserData?> getCurrentUser() async => memory.user;

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (email.trim().toLowerCase() != previewEmail ||
        password != previewPassword) {
      throw const AuthError(
        message:
            'Démo : utilise demo@intellia.test et Intellia237! '
            '/ Demo: use demo@intellia.test and Intellia237!',
        code: 'preview-credentials',
      );
    }
    return memory.remember(
      role: AppRole.teacher,
      firstName: 'Alex',
      lastName: 'Démo',
      email: previewEmail,
    );
  }

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) async {
    if (role == AppRole.admin) {
      throw const AuthError(
        message: 'L’accès administrateur ne fait pas partie de cet aperçu.',
        code: 'preview-unsupported-role',
      );
    }
    return memory.remember(
      role: role,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Exercise the real confirmation view with a labelled local simulation.
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Future<void> signOut() async => memory.clear();
}

class _PreviewStudentRepository implements StudentRegistrationRepository {
  const _PreviewStudentRepository(this.memory);
  final PreviewAuthMemory memory;

  @override
  Future<StudentRegistrationResult> registerStudent(
    StudentRegistrationPayload payload,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    final user = memory.remember(
      role: AppRole.student,
      firstName: payload.firstName,
      lastName: payload.lastName,
      email: payload.email,
    );
    return StudentRegistrationResult(
      uid: user.uid,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
    );
  }
}

class _PreviewRoleRepository implements RoleRegistrationRepository {
  const _PreviewRoleRepository(this.memory);
  final PreviewAuthMemory memory;

  @override
  Future<RoleRegistrationResult> registerParent(
    ParentRegistrationPayload payload,
  ) => _register(
    role: AppRole.parent,
    firstName: payload.firstName,
    lastName: payload.lastName,
    email: payload.email,
  );

  @override
  Future<RoleRegistrationResult> registerTeacher(
    TeacherRegistrationPayload payload,
  ) => _register(
    role: AppRole.teacher,
    firstName: payload.firstName,
    lastName: payload.lastName,
    email: payload.email,
  );

  Future<RoleRegistrationResult> _register({
    required AppRole role,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    final user = memory.remember(
      role: role,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
    return RoleRegistrationResult(
      uid: user.uid,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      accountStatus: role == AppRole.teacher ? 'pending_validation' : null,
    );
  }

  @override
  Future<RoleRegistrationResult> registerAdmin(
    AdminRegistrationPayload payload,
  ) async => throw const RoleRegistrationException(
    message: 'L’accès administrateur ne fait pas partie de cet aperçu.',
    code: 'preview-unsupported-role',
  );
}
