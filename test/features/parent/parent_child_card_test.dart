import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/app_theme.dart';
import 'package:intellia237/features/family_access/domain/family_access_models.dart';
import 'package:intellia237/features/parent/domain/parent_child_profile.dart';
import 'package:intellia237/features/parent/presentation/widgets/parent_child_card.dart';
import 'package:intellia237/features/study_reserve/data/study_reserve_service.dart';
import 'package:intellia237/features/study_reserve/domain/study_reserve.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// Carte « Mes enfants » sur un petit téléphone, texte système à 150 % :
/// nom, classe, école, accès et abonnement restent lisibles, les quatre
/// actions passent à la ligne au lieu de déborder.
const _viewport = Size(360, 1400);
const _textScale = 1.5;

ParentChildProfile _child({bool pending = false}) => ParentChildProfile(
  id: 'child-a',
  firstName: 'Anne-Marie-Clémentine',
  lastName: 'Ekena Mbarga Nkoulou',
  classLevel: pending ? '' : 'Terminale',
  series: pending ? null : 'D',
  establishmentName: pending
      ? null
      : 'Lycée bilingue d’Etoug-Ebe de Yaoundé, section anglophone',
  globalProgress: 0,
  studyMinutesToday: 0,
  studyMinutesTarget: 45,
  strongSubjects: const [],
  weakSubjects: const [],
  weeklyProgress: const [],
  access: ChildAccessMethods(ownPhone: !pending, accessCode: true),
  subscription: pending
      ? null
      : ChildSubscription(
          active: true,
          endsAt: DateTime(2026, 10, 15),
          paidBy: ChildSubscriptionPayer.anotherGuardian,
        ),
  pendingFirstSignIn: pending,
);

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required bool pending,
}) async {
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studyReserveProvider.overrideWith(
          (ref, studentId) async => StudyReserve(
            studentId: studentId ?? 'child-a',
            percentRemaining: 64,
            status: StudyReserveStatus.healthy,
            cycleEnd: DateTime(2026, 10, 1),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(_textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ParentChildCard(
              child: _child(pending: pending),
              onSubscription: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectReadable(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final content = (widget.data ?? widget.textSpan?.toPlainText() ?? '')
        .trim();
    final box = element.renderObject! as RenderBox;
    final left = box.localToGlobal(Offset.zero).dx;
    expect(left, greaterThanOrEqualTo(-0.01), reason: content);
    expect(
      left + box.size.width,
      lessThanOrEqualTo(_viewport.width + 0.01),
      reason: '"$content" sort de l’écran.',
    );
    if (content.length >= 12) {
      expect(box.size.width, greaterThan(48), reason: content);
    }
  }
}

void main() {
  for (final locale in const [Locale('fr'), Locale('en')]) {
    testWidgets('an active child card stays readable at 360 px, text 150 % '
        '(${locale.languageCode})', (tester) async {
      await _pump(tester, locale: locale, pending: false);
      _expectReadable(tester);
      final profile = locale.languageCode == 'fr'
          ? 'Voir le profil'
          : 'View profile';
      final accessCode = locale.languageCode == 'fr'
          ? 'Code d’accès élève'
          : 'Student access code';
      expect(find.text(profile), findsOneWidget);
      expect(find.text(accessCode), findsOneWidget);
      expect(
        find.text(
          locale.languageCode == 'fr'
              ? 'Connecté avec son propre accès INTELLIA'
              : 'Signed in with their own INTELLIA access',
        ),
        findsOneWidget,
      );
      // Les actions sont des cibles tactiles d'au moins 48 dp.
      for (final key in [
        'parent-child-profile-child-a',
        'parent-child-activity-child-a',
        'parent-child-access-code-child-a',
        'parent-child-subscription-action-child-a',
      ]) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.height, greaterThanOrEqualTo(48), reason: key);
      }
    });

    testWidgets('a child waiting for the first sign-in says so, without a '
        'reserve (${locale.languageCode})', (tester) async {
      await _pump(tester, locale: locale, pending: true);
      _expectReadable(tester);
      expect(
        find.text(
          locale.languageCode == 'fr'
              ? 'En attente de sa première connexion'
              : 'Waiting for their first sign-in',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('study-reserve-loading')), findsNothing);
    });
  }
}
