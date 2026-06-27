import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';

void main() {
  test('first launch redirects from bootstrap to onboarding', () {
    expect(
      resolveAppRedirect(
        auth: const AuthState.unauthenticated(),
        hasSeenOnboarding: false,
        location: AppRoutes.bootstrap,
      ),
      AppRoutes.onboarding,
    );
    expect(
      resolveAppRedirect(
        auth: const AuthState.unauthenticated(),
        hasSeenOnboarding: false,
        location: AppRoutes.onboarding,
      ),
      isNull,
    );
  });

  test('authenticated role redirects home and protects student-only Flow', () {
    const student = AuthState.authenticated(
      role: AppRole.student,
      userId: 'student-uid',
    );
    const parent = AuthState.authenticated(
      role: AppRole.parent,
      userId: 'parent-uid',
    );

    expect(
      resolveAppRedirect(
        auth: student,
        hasSeenOnboarding: true,
        location: AppRoutes.login,
      ),
      AppRoutes.studentHome,
    );
    expect(
      resolveAppRedirect(
        auth: student,
        hasSeenOnboarding: true,
        location: AppRoutes.flow,
      ),
      isNull,
    );
    expect(
      resolveAppRedirect(
        auth: parent,
        hasSeenOnboarding: true,
        location: AppRoutes.flow,
      ),
      AppRoutes.parentHome,
    );
  });
}
