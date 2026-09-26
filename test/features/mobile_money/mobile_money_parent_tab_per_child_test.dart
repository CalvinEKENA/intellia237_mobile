import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/mobile_money/application/mobile_money_providers.dart';
import 'package:intellia237/features/mobile_money/data/mobile_money_repository.dart';
import 'package:intellia237/features/mobile_money/domain/mobile_money_models.dart';
import 'package:intellia237/features/mobile_money/presentation/mobile_money_parent_tab.dart';
import 'package:intellia237/features/parent/application/parent_preview.dart';
import 'package:intellia237/features/parent/application/parent_providers.dart';
import 'package:intellia237/features/parent/data/parent_repository.dart';
import 'package:intellia237/features/parent/domain/parent_child_profile.dart';
import 'package:intellia237/features/parent/domain/parent_dashboard.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// Un parent, deux enfants dans deux écoles aux offres différentes : l'enfant
/// choisi désigne l'école, donc l'offre, et l'écran dit qui le paiement couvre.
void main() {
  testWidgets('choosing the child shows its school offer and the covered '
      'children, and the payment names that child', (tester) async {
    final repository = _Payments(supportsBeneficiary: true);
    await _pump(tester, repository);

    expect(find.text('Pour quel enfant payez-vous ?'), findsOneWidget);
    // Aucune offre tant que l'enfant n'est pas choisi : l'école est ambiguë.
    expect(find.text('Offre Lycée A'), findsNothing);
    expect(find.text('Offre Collège B'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('mobile-money-child-child-b')));
    await tester.pumpAndSettle();
    expect(find.text('Offre Collège B'), findsOneWidget);
    expect(find.text('4 000 FCFA'), findsOneWidget);
    expect(find.text('Offre de Collège B'), findsOneWidget);
    expect(find.text('Ce paiement couvre : Bilal'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mobile-money-child-child-a')));
    await tester.pumpAndSettle();
    expect(find.text('Offre Lycée A'), findsOneWidget);
    expect(find.text('2 500 FCFA'), findsOneWidget);
    expect(find.text('Ce paiement couvre : Awa, Chloé'), findsOneWidget);

    await _declare(tester);
    expect(repository.submissions, [('child-a', 'school-a')]);
  });

  testWidgets('an older server without beneficiary support keeps the previous '
      'flow and never sends the unknown field', (tester) async {
    final repository = _Payments(supportsBeneficiary: false);
    await _pump(tester, repository);

    expect(find.text('Pour quel enfant payez-vous ?'), findsNothing);
    expect(find.text('Offre Lycée A'), findsOneWidget);
    await _declare(tester);
    expect(repository.submissions, [(null, 'school-a')]);
  });

  testWidgets('the subscription action of a child card opens that child '
      'directly', (tester) async {
    final repository = _Payments(supportsBeneficiary: true);
    await _pump(tester, repository, initialChildId: 'child-b');
    expect(find.text('Offre Collège B'), findsOneWidget);
    expect(repository.requestedBeneficiaries, contains('child-b'));
  });
}

Future<void> _pump(
  WidgetTester tester,
  _Payments repository, {
  String? initialChildId,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mobileMoneyRepositoryProvider.overrideWithValue(repository),
        parentRepositoryProvider.overrideWithValue(_Dashboard()),
        effectiveParentUidProvider.overrideWithValue('parent-uid'),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: MobileMoneyParentTab(initialChildId: initialChildId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _declare(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Numéro ayant effectué le transfert'),
    '670000000',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Référence de transaction'),
    'TX-12345',
  );
  await tester.ensureVisible(find.text('Transmettre pour vérification'));
  await tester.tap(find.text('Transmettre pour vérification'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Valider'));
  await tester.pumpAndSettle();
}

MobileMoneyOffer _offer(String school, String title, int amount) =>
    MobileMoneyOffer(
      id: school,
      establishmentId: school,
      title: title,
      description: 'Accès INTELLIA237',
      amountXaf: amount,
      durationDays: 30,
      operators: const [
        MobileMoneyOperator(
          code: 'mtn',
          label: 'MTN Mobile Money',
          recipientPhone: '+237670000000',
        ),
      ],
    );

class _Payments implements MobileMoneyRepository {
  _Payments({required this.supportsBeneficiary});

  final bool supportsBeneficiary;
  final submissions = <(String?, String)>[];
  final requestedBeneficiaries = <String?>[];

  static const _children = [
    MobileMoneyChild(
      studentId: 'child-a',
      firstName: 'Awa',
      establishmentId: 'school-a',
    ),
    MobileMoneyChild(
      studentId: 'child-b',
      firstName: 'Bilal',
      establishmentId: 'school-b',
    ),
    MobileMoneyChild(
      studentId: 'child-c',
      firstName: 'Chloé',
      establishmentId: 'school-a',
    ),
  ];

  @override
  Future<MobileMoneyOverview> fetchParentOverview({
    String? beneficiaryStudentId,
  }) async {
    requestedBeneficiaries.add(beneficiaryStudentId);
    if (!supportsBeneficiary) {
      return MobileMoneyOverview(
        availability: MobileMoneyAvailability.available,
        offer: _offer('school-a', 'Offre Lycée A', 2500),
        recentRequests: const [],
      );
    }
    return switch (beneficiaryStudentId) {
      'child-a' => MobileMoneyOverview(
        availability: MobileMoneyAvailability.available,
        offer: _offer('school-a', 'Offre Lycée A', 2500),
        recentRequests: const [],
        children: _children,
        beneficiary: _children[0],
        coveredStudentIds: const ['child-a', 'child-c'],
        supportsBeneficiary: true,
      ),
      'child-b' => MobileMoneyOverview(
        availability: MobileMoneyAvailability.available,
        offer: _offer('school-b', 'Offre Collège B', 4000),
        recentRequests: const [],
        children: _children,
        beneficiary: _children[1],
        coveredStudentIds: const ['child-b'],
        supportsBeneficiary: true,
      ),
      _ => const MobileMoneyOverview(
        availability: MobileMoneyAvailability.multipleSchools,
        recentRequests: [],
        children: _children,
        supportsBeneficiary: true,
      ),
    };
  }

  @override
  Future<void> submitPayment({
    String? beneficiaryStudentId,
    required String offerId,
    required String operatorCode,
    required String payerPhone,
    required String transactionReference,
    required String clientRequestId,
  }) async {
    submissions.add((beneficiaryStudentId, offerId));
  }

  @override
  Future<List<AdminPaymentRequest>> fetchAdminQueue() =>
      throw UnimplementedError();

  @override
  Future<void> reviewPayment({
    required String requestId,
    required bool approved,
    String? reviewNote,
  }) => throw UnimplementedError();
}

class _Dashboard implements ParentRepository {
  @override
  Future<ParentDashboard> fetchDashboard({required String parentUid}) async =>
      ParentDashboard(
        children: [
          for (final (id, name, school) in const [
            ('child-a', 'Awa', 'Lycée A'),
            ('child-b', 'Bilal', 'Collège B'),
            ('child-c', 'Chloé', 'Lycée A'),
          ])
            ParentChildProfile(
              id: id,
              firstName: name,
              establishmentName: school,
              classLevel: 'Terminale',
              series: null,
              globalProgress: 0,
              studyMinutesToday: 0,
              studyMinutesTarget: 45,
              strongSubjects: const [],
              weakSubjects: const [],
              weeklyProgress: const [],
            ),
        ],
        announcements: const [],
      );
}
