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

    // Refonte Auth V2 : premier lancement comme retour, la même porte neutre
    // — l'identité d'abord, jamais un écran de rôles.
    test('2. completed onboarding opens the neutral gateway', () {
      expect(
        _redirect(location: AppRoutes.onboarding, hasSeenOnboarding: true),
        AppRoutes.authGateway,
      );
    });

    test('3. skipped onboarding opens the neutral gateway', () {
      expect(
        _redirect(location: AppRoutes.bootstrap, hasSeenOnboarding: true),
        AppRoutes.authGateway,
      );
    });

    test('4. a first launch never shows role selection', () {
      for (final location in [AppRoutes.bootstrap, AppRoutes.onboarding]) {
        final destination = _redirect(
          location: location,
          hasSeenOnboarding: true,
        );
        expect(destination, AppRoutes.authGateway);
        expect(destination, isNot(AppRoutes.register));
        expect(destination, isNot(AppRoutes.parentEntry));
      }
    });

    test(
      '4b. legacy role-first and child-code-first links lead to the gateway',
      () {
        for (final hasAuthenticatedBefore in [false, true]) {
          for (final legacy in [AppRoutes.register, AppRoutes.parentEntry]) {
            expect(
              _redirect(
                location: legacy,
                hasSeenOnboarding: true,
                hasAuthenticatedBefore: hasAuthenticatedBefore,
              ),
              AppRoutes.authGateway,
            );
          }
        }
      },
    );

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
      expect(_returningRedirect(AppRoutes.studentAccessCode), isNull);
      expect(_returningRedirect(AppRoutes.register), AppRoutes.authGateway);
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

    test('10. login can explicitly navigate to staff registration', () {
      expect(
        _redirect(
          location: AppRoutes.teacherRegistration,
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
            location == AppRoutes.tutorSelection ||
            // Retirés (refonte Auth V2) ou réservés à une identité prouvée :
            // ils mènent à la porte neutre sans session.
            location == AppRoutes.register ||
            location == AppRoutes.parentEntry ||
            location == AppRoutes.accountWelcome ||
            location == AppRoutes.googleDiscovery ||
            location == AppRoutes.roleChooser) {
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

  group('super-admin Parent preview (routing)', () {
    const superAdmin = AuthState.authenticated(
      role: AppRole.admin,
      userId: 'super-admin-uid',
      email: 'calvinekena4@gmail.com',
      isSuperAdmin: true,
    );

    test(
      'super-admin on a Parent route goes to Admin when preview inactive',
      () {
        expect(
          _redirect(
            auth: superAdmin,
            location: AppRoutes.parentHome,
            hasSeenOnboarding: true,
            hasAuthenticatedBefore: true,
          ),
          AppRoutes.adminHome,
        );
      },
    );

    test('super-admin is allowed on Parent routes while preview is active', () {
      for (final location in [
        AppRoutes.parentHome,
        AppRoutes.childOverview('child-1'),
        AppRoutes.childProgress('child-1'),
      ]) {
        expect(
          _redirect(
            auth: superAdmin,
            location: location,
            hasSeenOnboarding: true,
            hasAuthenticatedBefore: true,
            parentPreviewActive: true,
          ),
          isNull,
          reason: '$location should be allowed during preview',
        );
      }
    });

    test('preview flag never lets a non-admin role reach Parent routes', () {
      expect(
        _redirect(
          auth: const AuthState.authenticated(
            role: AppRole.teacher,
            userId: 'teacher-uid',
          ),
          location: AppRoutes.parentHome,
          hasSeenOnboarding: true,
          hasAuthenticatedBefore: true,
          parentPreviewActive: true,
        ),
        AppRoutes.teacherHome,
      );
    });

    test('an ordinary parent still opens Parent home without any preview', () {
      expect(
        _redirect(
          auth: const AuthState.authenticated(
            role: AppRole.parent,
            userId: 'parent-uid',
          ),
          location: AppRoutes.parentHome,
          hasSeenOnboarding: true,
          hasAuthenticatedBefore: true,
        ),
        isNull,
      );
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
  bool parentPreviewActive = false,
  required String location,
}) {
  return resolveAppRedirect(
    auth: auth,
    hasSeenOnboarding: hasSeenOnboarding,
    hasAuthenticatedBefore: hasAuthenticatedBefore,
    location: location,
    parentPreviewActive: parentPreviewActive,
  );
}
