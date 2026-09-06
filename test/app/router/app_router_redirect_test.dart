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

    // Une déconnexion ne présuppose aucun rôle : l'appareil est souvent
    // partagé, et renvoyer vers l'authentification élève enfermait le parent
    // ou l'enseignant dans l'espace de quelqu'un d'autre.
    test('6. signed-out student opens the neutral gateway', () {
      expect(_returningRedirect(AppRoutes.studentHome), AppRoutes.authGateway);
    });

    test('7. signed-out parent opens the neutral gateway', () {
      expect(_returningRedirect(AppRoutes.parentHome), AppRoutes.authGateway);
    });

    test('8. expired returning session opens the neutral gateway', () {
      expect(_returningRedirect(AppRoutes.bootstrap), AppRoutes.authGateway);
    });

    test('9. the gateway itself is reachable while signed out', () {
      expect(_returningRedirect(AppRoutes.authGateway), isNull);
    });

    test('10. each role entry stays reachable from the gateway', () {
      // Aucun nouveau mécanisme d'authentification : chaque rôle rejoint le
      // parcours qui existait déjà.
      expect(_returningRedirect(AppRoutes.login), isNull);
      expect(_returningRedirect(AppRoutes.phoneAuth), isNull);
      expect(_returningRedirect(AppRoutes.emailLogin), isNull);
      expect(_returningRedirect(AppRoutes.register), isNull);
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

    test('incomplete student profile is forced through academic setup', () {
      const incomplete = AuthState.authenticated(
        role: AppRole.student,
        userId: 'student-without-profile',
        profileCompleted: false,
      );
      expect(
        _redirect(
          auth: incomplete,
          location: AppRoutes.studentHome,
          hasSeenOnboarding: true,
          hasAuthenticatedBefore: true,
        ),
        AppRoutes.studentRegistration,
      );
      expect(
        _redirect(
          auth: incomplete,
          location: AppRoutes.studentRegistration,
          hasSeenOnboarding: true,
          hasAuthenticatedBefore: true,
        ),
        isNull,
      );
    });

    test(
      'profile resolution failures never bounce an Auth session to login',
      () {
        const retryable = AuthState.retryableProfileFailure(
          userId: 'firebase-uid',
          error: 'offline',
        );
        const unknownLegacy = AuthState.legacyProfileRecovery(
          userId: 'legacy-uid',
          error: 'unknown-role',
        );
        for (final auth in [retryable, unknownLegacy]) {
          expect(
            _redirect(
              auth: auth,
              location: AppRoutes.bootstrap,
              hasSeenOnboarding: true,
              hasAuthenticatedBefore: true,
            ),
            AppRoutes.authProfileRecovery,
          );
        }
      },
    );

    test(
      'the durable notification inbox is available to every signed-in role',
      () {
        for (final role in AppRole.values) {
          expect(
            _redirect(
              auth: AuthState.authenticated(
                role: role,
                userId: '${role.name}-uid',
              ),
              location: AppRoutes.studentNotifications,
              hasSeenOnboarding: true,
              hasAuthenticatedBefore: true,
            ),
            isNull,
            reason: role.name,
          );
        }
        expect(
          AppRoutes.isSafeNotificationRoute(AppRoutes.studentNotifications),
          isTrue,
        );
      },
    );
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
