import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/auth_linking_state.dart';
import 'package:intellia237/features/auth/presentation/role_selector_screen.dart';
import '../../support/intellia_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);

  group('Multi-Role Domain & Model Tests', () {
    test('parseStoredAppRoles parses legacy single string role', () {
      final roles = parseStoredAppRoles(null, 'teacher');
      expect(roles, equals([AppRole.teacher]));
    });

    test(
      'parseStoredAppRoles parses modern roles array alongside legacy fallback',
      () {
        final roles = parseStoredAppRoles(['teacher', 'parent'], 'teacher');
        expect(roles, equals([AppRole.teacher, AppRole.parent]));
      },
    );

    test(
      'parseStoredAppRoles deduplicates and safely ignores unmapped roles',
      () {
        final roles = parseStoredAppRoles([
          'teacher',
          'unknown_role',
          'student',
          'teacher',
        ], 'teacher');
        expect(roles, equals([AppRole.teacher, AppRole.student]));
      },
    );

    test('AuthState resolves multi-role status accurately', () {
      const singleRoleState = AuthState.authenticated(
        role: AppRole.student,
        userId: 'student-123',
      );
      expect(singleRoleState.isMultiRole, isFalse);
      expect(singleRoleState.resolvedRoles, equals([AppRole.student]));

      const multiRoleState = AuthState.authenticated(
        role: AppRole.teacher,
        availableRoles: [AppRole.teacher, AppRole.parent],
        userId: 'dual-user-123',
      );
      expect(multiRoleState.isMultiRole, isTrue);
      expect(
        multiRoleState.resolvedRoles,
        equals([AppRole.teacher, AppRole.parent]),
      );
    });

    test(
      'AccountLinkingState types enforce explicit domain state invariants',
      () {
        const alreadyLinked = GoogleAlreadyLinkedState(
          uid: 'uid-old-123',
          roles: [AppRole.teacher],
        );
        expect(alreadyLinked.roles, equals([AppRole.teacher]));

        const collisionState = ProviderAlreadyInUseState(
          message: 'Compte déjà utilisé.',
        );
        expect(collisionState.message, 'Compte déjà utilisé.');
      },
    );
  });

  group('RoleSelectorScreen Presentation Tests', () {
    testWidgets('Displays only authorized roles for multi-role user', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeMultiRoleAuthController(
              const AuthState.authenticated(
                role: AppRole.teacher,
                availableRoles: [AppRole.teacher, AppRole.parent],
                userId: 'dual-123',
                firstName: 'Calvin',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: RoleSelectorScreen())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Bienvenue, Calvin'), findsOneWidget);
      expect(find.byKey(const ValueKey('role-select-teacher')), findsOneWidget);
      expect(find.byKey(const ValueKey('role-select-parent')), findsOneWidget);
      // Student is NOT authorized for this user, so it must not be rendered
      expect(find.byKey(const ValueKey('role-select-student')), findsNothing);
      expect(find.byKey(const ValueKey('role-select-admin')), findsNothing);
    });
  });
}

class _FakeMultiRoleAuthController extends AuthController {
  _FakeMultiRoleAuthController(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;

  @override
  Future<void> selectActiveRole(AppRole role) async {
    state = state.copyWith(role: role);
  }
}
