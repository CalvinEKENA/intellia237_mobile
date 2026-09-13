import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/application/admin_providers.dart';
import 'package:intellia237/features/admin/domain/account_school_record.dart';
import 'package:intellia237/features/admin/domain/admin_models.dart';
import 'package:intellia237/features/admin/presentation/school_transfer_section.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// Une erreur d'inscription se corrige depuis l'application : l'administration
/// générale retrouve le compte, choisit la bonne école et dit pourquoi.
void main() {
  const schools = [
    EstablishmentOption(id: 'lycee-a', name: 'Lycée A', city: 'Douala'),
    EstablishmentOption(id: 'lycee-b', name: 'Lycée B', city: 'Bafoussam'),
  ];

  Future<List<(String, String, String?)>> pumpSection(
    WidgetTester tester, {
    required List<AccountSchoolRecord> results,
  }) async {
    final changes = <(String, String, String?)>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminEstablishmentsProvider.overrideWith((ref) async => schools),
          adminActionsProvider.overrideWith(
            (ref) => _RecordingActions(ref, results, changes),
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
            body: SingleChildScrollView(child: SchoolTransferSection()),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('school-transfer-query')),
      '699 00 00 00',
    );
    await tester.tap(find.byKey(const ValueKey('school-transfer-search')));
    await tester.pumpAndSettle();
    return changes;
  }

  testWidgets('un élève inscrit dans la mauvaise école change d’école, '
      'avec un motif', (tester) async {
    final changes = await pumpSection(
      tester,
      results: const [
        AccountSchoolRecord(
          id: 'eleve-1',
          fullName: 'Paul Ndi',
          role: AdminRoleType.student,
          phone: '+237699000000',
          establishmentId: 'lycee-a',
          establishmentName: 'Lycée A',
          declaredSchoolName: 'Lycée B',
          declaredSchoolCity: 'Bafoussam',
        ),
      ],
    );

    expect(find.text('Paul Ndi'), findsOneWidget);
    expect(find.text('École : Lycée A'), findsOneWidget);
    expect(find.textContaining('Déclarée à l’inscription'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('school-transfer-change-eleve-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('attach-school-lycee-b')));
    await tester.pumpAndSettle();

    final confirm = find.byKey(
      const ValueKey('school-transfer-reason-confirm'),
    );
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('school-transfer-reason')),
      'Erreur du parent à l’inscription',
    );
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(changes, [
      ('eleve-1', 'lycee-b', 'Erreur du parent à l’inscription'),
    ]);
    expect(find.textContaining('École mise à jour'), findsOneWidget);
  });

  testWidgets('un compte sans école se rattache sans motif', (tester) async {
    final changes = await pumpSection(
      tester,
      results: const [
        AccountSchoolRecord(
          id: 'eleve-2',
          fullName: 'Awa Mbarga',
          role: AdminRoleType.student,
        ),
      ],
    );

    await tester.tap(
      find.byKey(const ValueKey('school-transfer-change-eleve-2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('attach-school-lycee-a')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('school-transfer-reason')), findsNothing);
    expect(changes, [('eleve-2', 'lycee-a', null)]);
  });

  testWidgets('un parent montre ses enfants, dont l’école se corrige aussi', (
    tester,
  ) async {
    await pumpSection(
      tester,
      results: const [
        AccountSchoolRecord(
          id: 'parent-1',
          fullName: 'Marie Ndi',
          role: AdminRoleType.parent,
          children: [
            AccountSchoolRecord(
              id: 'eleve-3',
              fullName: 'Léa Ndi',
              role: AdminRoleType.student,
            ),
          ],
        ),
      ],
    );

    expect(find.text('Enfants liés'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('school-transfer-change-eleve-3')),
      findsOneWidget,
    );
  });

  test('le numéro tapé retrouve sa forme enregistrée', () {
    for (final raw in [
      '699 98 90 99',
      '+237 6 99 98 90 99',
      '00237699989099',
      '237-699-989-099',
    ]) {
      expect(normalizeCameroonPhone(raw), '+237699989099', reason: raw);
    }
    expect(normalizeCameroonPhone('+33 6 12 34 56 78'), '+33612345678');
    expect(normalizeCameroonPhone('abc'), isNull);
    expect(normalizeCameroonPhone('12345'), isNull);
  });
}

class _RecordingActions extends AdminActions {
  _RecordingActions(super.ref, this.results, this.changes);

  final List<AccountSchoolRecord> results;
  final List<(String, String, String?)> changes;

  @override
  Future<List<AccountSchoolRecord>> searchAccounts(String query) async =>
      results;

  @override
  Future<void> changeAccountEstablishment({
    required String accountId,
    required String establishmentId,
    String? reason,
  }) async {
    changes.add((accountId, establishmentId, reason));
  }
}
