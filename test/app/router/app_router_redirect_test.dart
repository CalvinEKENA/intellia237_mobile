import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';

void main() {
  group('first authentication entry', () {
    test('1. first installation opens onboarding', () {
      expect(_redirect(location: AppRoutes.bootstrap), AppRoutes.onboarding);
    });

    test('2. completed onboarding opens registration', () {
      expect(
        _redirect(location: AppRoutes.onboarding, hasSeenOnboarding: true),
        AppRoutes.register,
      );
    });

    test('3. skipped onboarding opens registration', () {
      expect(
        _redirect(location: AppRoutes.bootstrap, hasSeenOnboarding: true),
        AppRoutes.register,
      );
    });

    test('4. onboarding seen without prior authentication opens register', () {
      expect(
        _redirect(location: AppRoutes.bootstrap, hasSeenOnboarding: true),
        AppRoutes.register,
      );
    });

    test('15. a first authentication flow never redirects to login', () {
      for (final location in [AppRoutes.bootstrap, AppRoutes.onboarding]) {
        expect(
          _redirect(
            location: location,
            hasSeenOnboarding: location != AppRoutes.bootstrap,
          ),
          isNot(AppRoutes.login),
        );
      }
    });
  });

  group('authenticated and returning users', () {
    test('5. authenticated users open their role home', () {
      expect(
        _redirect(
          auth: const AuthState.authenticated(
            role: AppRole.student,
            userId: 'student-uid',
          ),
          location: AppRoutes.login,
          hasSeenOnboarding: true,
          hasAuthenticatedBefore: true,
        ),
        AppRoutes.studentHome,
      );
    });

    test('6. signed-out student opens login', () {
      expect(_returningRedirect(AppRoutes.studentHome), AppRoutes.login);
    });

    test('7. signed-out parent opens login', () {
      expect(_returningRedirect(AppRoutes.parentHome), AppRoutes.login);
    });

    test('8. expired returning session opens login', () {
      expect(_returningRedirect(AppRoutes.bootstrap), AppRoutes.login);
    });

    test('keeps student Flow and protects it from other roles', () {
      const student = AuthState.authenticated(
        role: AppRole.student,
        userId: 'student-uid',
      );
      const parent = AuthState.authenticated(
        role: AppRole.parent,
        userId: 'parent-uid',
      );
      expect(
        _redirect(
          auth: student,
          location: AppRoutes.flow,
          hasSeenOnboarding: true,
          hasAuthenticatedBefore: true,
        ),
        isNull,
      );
      expect(
        _redirect(
          auth: parent,
          location: AppRoutes.flow,
          hasSeenOnboarding: true,
          hasAuthenticatedBefore: true,
        ),
        AppRoutes.parentHome,
      );
    });
  });

  group('pre-auth routes remain stable', () {
    test('9. register can explicitly navigate to login', () {
      expect(
        _redirect(location: AppRoutes.login, hasSeenOnboarding: true),
        isNull,
      );
    });

    test('10. login can explicitly navigate to register', () {
      expect(
        _redirect(
          location: AppRoutes.register,
          hasSeenOnboarding: true,
          hasAuthenticatedBefore: true,
        ),
        isNull,
      );
    });

    test('11. student registration is not interrupted', () {
      expect(_registrationRedirect(AppRoutes.studentRegistration), isNull);
    });

    test('12. parent registration is not interrupted', () {
      expect(_registrationRedirect(AppRoutes.parentRegistration), isNull);
    });

    test('13. restart location during staff registration remains stable', () {
      expect(_registrationRedirect(AppRoutes.teacherRegistration), isNull);
      expect(_registrationRedirect(AppRoutes.adminRegistration), isNull);
    });

    test('14. stable pre-auth locations do not create redirect loops', () {
      for (final location in AppRoutes.preAuthRoutes) {
        if (location == AppRoutes.bootstrap ||
            location == AppRoutes.onboarding ||
            location == AppRoutes.tutorSelection) {
          continue;
        }
        expect(
          _redirect(
            location: location,
            hasSeenOnboarding: true,
            hasAuthenticatedBefore: false,
          ),
          isNull,
          reason: '$location should remain stable',
        );
      }
    });
  });
}

String? _returningRedirect(String location) => _redirect(
  location: location,
  hasSeenOnboarding: true,
  hasAuthenticatedBefore: true,
);

String? _registrationRedirect(String location) => _redirect(
  location: location,
  hasSeenOnboarding: true,
  hasAuthenticatedBefore: false,
);

String? _redirect({
  AuthState auth = const AuthState.unauthenticated(),
  bool hasSeenOnboarding = false,
  bool hasAuthenticatedBefore = false,
  required String location,
}) {
  return resolveAppRedirect(
    auth: auth,
    hasSeenOnboarding: hasSeenOnboarding,
    hasAuthenticatedBefore: hasAuthenticatedBefore,
    location: location,
  );
}
