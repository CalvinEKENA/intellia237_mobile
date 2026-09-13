import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/application/admin_account_management_service.dart';
import 'package:intellia237/features/admin/presentation/account_management_controls.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

void main() {
  for (final root in [false, true]) {
    testWidgets('management controls are available only to root ($root)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final calls = <Map<String, Object>>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(root)),
            adminAccountManagementProvider.overrideWith(
              (ref) => _Service(ref, calls),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: const Scaffold(
              body: Column(
                children: [
                  CreateStudentButton(),
                  AccountManagementMenu(
                    accountId: 'head',
                    name: 'Direction de l’établissement',
                    status: 'active',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('admin-create-student')),
        root ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('manage-account-head')),
        root ? findsOneWidget : findsNothing,
      );
      if (root) {
        await tester.tap(find.byKey(const ValueKey('manage-account-head')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Suspendre le profil'));
        await tester.pumpAndSettle();
        expect(calls, isEmpty);
        await tester.enterText(
          find.byType(TextField),
          'Vérification administrative',
        );
        await tester.pump();
        final confirm = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        );
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(calls.single, {
          'action': 'suspend',
          'accountId': 'head',
          'reason': 'Vérification administrative',
        });
      }
      expect(tester.takeException(), isNull);
    });
  }
}

class _Auth extends AuthController {
  _Auth(this.root);
  final bool root;
  @override
  AuthState build() => AuthState.authenticated(
    role: AppRole.admin,
    userId: root ? 'owner' : 'head',
    isSuperAdmin: root,
    establishmentId: root ? null : 'school',
  );
}

class _Service extends AdminAccountManagementService {
  _Service(super.ref, this.calls);
  final List<Map<String, Object>> calls;
  @override
  Future<void> execute(Map<String, Object> data) async {
    calls.add(data);
  }
}
