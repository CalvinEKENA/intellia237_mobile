import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/data/admin_repository.dart';
import 'package:intellia237/features/admin/domain/admin_models.dart';
import 'package:intellia237/features/admin/application/admin_providers.dart';
import 'package:intellia237/features/admin/presentation/school_directory_section.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

class _AdminAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    role: AppRole.admin,
    userId: 'admin-1',
    email: 'admin@example.com',
    isSuperAdmin: true,
    establishmentId: 'school-1',
  );
}

class _FakeAdminRepository extends Fake implements AdminRepository {
  final List<SchoolClassSummary> classes;
  final List<(String, String, String?, String?)> created = [];
  final List<String> deleted = [];

  _FakeAdminRepository(this.classes);

  @override
  Future<List<SchoolClassSummary>> fetchSchoolClasses({
    required String adminUid,
    String? establishmentId,
  }) async => classes;

  @override
  Future<String> createSchoolClass({
    required String adminUid,
    required String name,
    required String classLevel,
    String? series,
    String? track,
    String? establishmentId,
  }) async {
    created.add((name, classLevel, series, track));
    return 'new-class';
  }

  @override
  Future<void> deleteSchoolClass({
    required String adminUid,
    required String classId,
  }) async {
    deleted.add(classId);
  }
}

Future<void> _pump(WidgetTester tester, _FakeAdminRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_AdminAuthController.new),
        adminRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('fr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SchoolClassesSection(establishmentId: 'school-1'),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  const emptyClass = SchoolClassSummary(
    id: 'c-empty',
    name: '6e A',
    levelLabel: '6eme',
    studentCount: 0,
    teacherCount: 1,
  );
  const fullClass = SchoolClassSummary(
    id: 'c-full',
    name: 'Terminale C1',
    levelLabel: 'Terminale',
    studentCount: 24,
    teacherCount: 2,
  );

  testWidgets(
    'creating a class sends name + canonical level to the repository',
    (tester) async {
      final repo = _FakeAdminRepository([emptyClass]);
      await _pump(tester, repo);

      await tester.tap(find.byKey(const ValueKey('create-class')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('create-class-name')),
        '5e B',
      );
      await tester.tap(find.byKey(const ValueKey('create-class-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(repo.created, hasLength(1));
      expect(repo.created.first.$1, '5e B');
      // Niveau canonique (jamais un libellé d'affichage comme « 6ème »).
      expect(repo.created.first.$2, '6eme');
    },
  );

  testWidgets('delete is disabled for a class that still has students', (
    tester,
  ) async {
    await _pump(tester, _FakeAdminRepository([fullClass]));
    final button = tester.widget<IconButton>(
      find.byKey(const ValueKey('delete-class-c-full')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'deleting an empty class calls the repository after confirmation',
    (tester) async {
      final repo = _FakeAdminRepository([emptyClass]);
      await _pump(tester, repo);

      final button = tester.widget<IconButton>(
        find.byKey(const ValueKey('delete-class-c-empty')),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('delete-class-c-empty')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-class-confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(repo.deleted, ['c-empty']);
    },
  );
}
