import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';

/// Redirections de la refonte Auth V2 : décision d'entrée après l'identité,
/// découverte étanche, choix d'espace pour les comptes à plusieurs espaces.
void main() {
  String? redirect(AuthState auth, String location) => resolveAppRedirect(
    auth: auth,
    hasSeenOnboarding: true,
    hasAuthenticatedBefore: true,
    location: location,
  );

  group('identity without profile', () {
    const noProfile = AuthState.needsOnboarding(userId: 'uid-new');

    test('opens the entry decision, never "profile not found"', () {
      expect(
        redirect(noProfile, AppRoutes.authGateway),
        AppRoutes.accountWelcome,
      );
      expect(
        redirect(noProfile, AppRoutes.studentHome),
        AppRoutes.accountWelcome,
      );
      expect(redirect(noProfile, AppRoutes.accountWelcome), isNull);
    });

    test('lets the chosen registration and the phone screen proceed', () {
      for (final location in [
        AppRoutes.parentRegistration,
        AppRoutes.studentRegistration,
        AppRoutes.phoneAuth,
        AppRoutes.studentAccessCode,
        AppRoutes.legalPrivacy,
      ]) {
        expect(redirect(noProfile, location), isNull, reason: location);
      }
    });

    test('a started registration keeps its own screen', () {
      const student = AuthState.needsOnboarding(
        userId: 'uid-s',
        recoveredRole: AppRole.student,
      );
      expect(
        redirect(student, AppRoutes.accountWelcome),
        AppRoutes.studentRegistration,
      );
    });
  });

  group('discovery', () {
    const discovery = AuthState.discovery(userId: 'google-uid');

    test(
      'can open only discovery, space creation, the student code and legal pages',
      () {
        for (final allowed in [
          AppRoutes.googleDiscovery,
          AppRoutes.parentRegistration,
          AppRoutes.studentRegistration,
          AppRoutes.studentAccessCode,
          AppRoutes.legalTerms,
        ]) {
          expect(redirect(discovery, allowed), isNull, reason: allowed);
        }
      },
    );

    test('can never reach a private route', () {
      for (final private in [
        AppRoutes.studentHome,
        AppRoutes.flow,
        AppRoutes.learnHub,
        AppRoutes.quizHub,
        AppRoutes.aiCompanion,
        AppRoutes.parentHome,
        AppRoutes.parentChild('child-1'),
        AppRoutes.parentChildProfile('child-1'),
        AppRoutes.teacherHome,
        AppRoutes.adminHome,
        AppRoutes.campus,
        AppRoutes.settings,
        AppRoutes.editProfile,
        AppRoutes.studentNotifications,
        AppRoutes.roleChooser,
        AppRoutes.accountLinking,
        AppRoutes.authGateway,
      ]) {
        expect(
          redirect(discovery, private),
          AppRoutes.googleDiscovery,
          reason: private,
        );
      }
    });
  });

  group('several spaces', () {
    const pending = AuthState.authenticated(
      role: AppRole.teacher,
      availableRoles: [AppRole.teacher, AppRole.parent],
      userId: 'dual',
      spaceChoicePending: true,
    );
    const remembered = AuthState.authenticated(
      role: AppRole.parent,
      availableRoles: [AppRole.teacher, AppRole.parent],
      userId: 'dual',
    );
    const single = AuthState.authenticated(role: AppRole.parent, userId: 'p');

    test('without a remembered space, the chooser comes before any home', () {
      expect(redirect(pending, AppRoutes.authGateway), AppRoutes.roleChooser);
      expect(redirect(pending, AppRoutes.teacherHome), AppRoutes.roleChooser);
      expect(redirect(pending, AppRoutes.roleChooser), isNull);
    });

    test('a remembered space opens directly, the chooser stays reachable', () {
      expect(redirect(remembered, AppRoutes.authGateway), AppRoutes.parentHome);
      expect(redirect(remembered, AppRoutes.parentHome), isNull);
      expect(redirect(remembered, AppRoutes.roleChooser), isNull);
    });

    test('a single-space account never sees the chooser', () {
      expect(redirect(single, AppRoutes.authGateway), AppRoutes.parentHome);
      expect(redirect(single, AppRoutes.roleChooser), AppRoutes.parentHome);
    });

    test('the active space decides the protected routes', () {
      expect(redirect(remembered, AppRoutes.teacherHome), AppRoutes.parentHome);
    });
  });

  test('session phases are derived from one state', () {
    expect(
      const AuthState.bootstrapping().sessionPhase,
      AuthSessionPhase.authenticating,
    );
    expect(
      const AuthState.unauthenticated().sessionPhase,
      AuthSessionPhase.unauthenticated,
    );
    expect(
      const AuthState.unauthenticated(suspended: true).sessionPhase,
      AuthSessionPhase.suspended,
    );
    expect(
      const AuthState.needsOnboarding(userId: 'u').sessionPhase,
      AuthSessionPhase.authenticatedNoProfile,
    );
    expect(
      const AuthState.discovery(userId: 'u').sessionPhase,
      AuthSessionPhase.discovery,
    );
    expect(
      const AuthState.authenticated(
        role: AppRole.parent,
        userId: 'u',
      ).sessionPhase,
      AuthSessionPhase.oneRole,
    );
    expect(
      const AuthState.authenticated(
        role: AppRole.parent,
        availableRoles: [AppRole.parent, AppRole.teacher],
        userId: 'u',
      ).sessionPhase,
      AuthSessionPhase.multiRole,
    );
    expect(
      const AuthState.authenticated(
        role: AppRole.teacher,
        userId: 'u',
        accountStatus: 'pending_validation',
      ).sessionPhase,
      AuthSessionPhase.pendingStaff,
    );
    expect(
      const AuthState.retryableProfileFailure(userId: 'u').sessionPhase,
      AuthSessionPhase.error,
    );
  });
}
