import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/application/admin_providers.dart';
import 'package:intellia237/features/admin/domain/admin_models.dart';
import 'package:intellia237/features/admin/presentation/unattached_staff_section.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// Le personnel approuvé avant l'arrivée de son école se rattache depuis
/// l'application : plus de console Firestore pour renseigner l'école.
void main() {
  const teacher = UnattachedStaffMember(
    id: 'teacher-1',
    fullName: 'Awa Mbarga',
    email: 'awa@lycee-a.cm',
    role: AdminRoleType.teacher,
  );
  const school = EstablishmentOption(
    id: 'lycee-a',
    name: 'Lycée bilingue A',
    city: 'Douala',
  );

  Future<List<(String, String)>> pumpSection(
    WidgetTester tester, {
    required List<UnattachedStaffMember> members,
  }) async {
    final calls = <(String, String)>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUnattachedStaffProvider.overrideWith((ref) async => members),
          adminEstablishmentsProvider.overrideWith((ref) async => [school]),
          adminActionsProvider.overrideWith(
            (ref) => _RecordingActions(ref, calls),
          ),
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
            body: SingleChildScrollView(child: UnattachedStaffSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('le super-admin rattache un enseignant à son école', (
    tester,
  ) async {
    final calls = await pumpSection(tester, members: [teacher]);

    expect(find.text('Awa Mbarga'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('attach-staff-teacher-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('attach-school-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('attach-school-lycee-a')));
    await tester.pumpAndSettle();

    expect(calls, [('teacher-1', 'lycee-a')]);
    expect(find.textContaining('Compte rattaché'), findsOneWidget);
  });

  testWidgets('refermer la feuille ne rattache rien', (tester) async {
    final calls = await pumpSection(tester, members: [teacher]);

    await tester.tap(find.byKey(const ValueKey('attach-staff-teacher-1')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
  });

  testWidgets('sans compte en attente d’école, la section le dit', (
    tester,
  ) async {
    await pumpSection(tester, members: const []);

    expect(
      find.text('Tout le personnel approuvé a son école.'),
      findsOneWidget,
    );
  });
}

class _RecordingActions extends AdminActions {
  _RecordingActions(super.ref, this.calls);

  final List<(String, String)> calls;

  @override
  Future<void> attachStaffToEstablishment({
    required String staffId,
    required String establishmentId,
  }) async {
    calls.add((staffId, establishmentId));
  }
}
