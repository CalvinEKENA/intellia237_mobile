import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/presentation/student_access_code_screen.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';
import 'package:intellia237/features/auth/presentation/widgets/pass_auth_progress.dart';
import 'package:intellia237/features/family_access/domain/family_access_models.dart';
import 'package:intellia237/features/mobile_money/domain/mobile_money_models.dart';
import 'package:intellia237/features/parent/data/firestore_parent_repository.dart';
import 'package:intellia237/features/parent/domain/parent_child_profile.dart';

void main() {
  group('student access code format (same rules as the server)', () {
    test('normalizes the grouped form a family reads aloud', () {
      expect(
        StudentAccessCodeFormat.normalize(' abcd-efgh jkmn '),
        'ABCDEFGHJKMN',
      );
      expect(StudentAccessCodeFormat.isWellFormed('abcd-efgh-jkmn'), isTrue);
      expect(StudentAccessCodeFormat.format('ABCDEFGHJKMN'), 'ABCD-EFGH-JKMN');
    });

    test('refuses ambiguous symbols and wrong lengths', () {
      for (final code in [
        'ABCD-EFGH-JKM0',
        'ABCD-EFGH-JKMO',
        'ABCD-EFGH-JKM1',
        'ABCD',
        '',
      ]) {
        expect(
          StudentAccessCodeFormat.isWellFormed(code),
          isFalse,
          reason: code,
        );
      }
    });

    test('the input formatter keeps only code symbols, grouped by four', () {
      const formatter = StudentAccessCodeInputFormatter();
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'ab0cd efg-hjkmn9999'),
      );
      expect(value.text, 'ABCD-EFGH-JKMN');
      expect(value.selection.baseOffset, value.text.length);
    });

    test('never prints the code in diagnostics', () {
      const issued = IssuedStudentAccessCode(code: 'ABCD-EFGH-JKMN');
      expect('$issued', isNot(contains('ABCD')));
    });
  });

  group('the 237 seal on the access code screen', () {
    test(
      '2 when well formed, 3 once the server accepts, 7 as the space opens',
      () {
        PassSealStage stage(
          String input, {
          bool accepted = false,
          bool opened = false,
        }) => PassAuthProgress.studentAccessCode(
          codeInput: input,
          codeAccepted: accepted,
          accessOpened: opened,
        );
        expect(stage('ABCD-EF'), PassSealStage.neutral);
        expect(stage('ABCD-EFGH-JKMN'), PassSealStage.identifier);
        expect(stage('ABCD-EFGH-JKMN', accepted: true), PassSealStage.secret);
        expect(
          stage('ABCD-EFGH-JKMN', accepted: true, opened: true),
          PassSealStage.verified,
        );
      },
    );
  });

  group('parent read model', () {
    Map<String, dynamic> summary({
      String id = 'child-a',
      String status = 'active',
      String school = 'Lycée A',
      Map<String, dynamic>? access,
      Map<String, dynamic>? subscription,
    }) => {
      'studentId': id,
      'status': status,
      'firstName': 'Awa',
      'lastName': 'Mbarga',
      'classLevel': 'Terminale',
      'series': null,
      'establishmentId': 'school-a',
      'establishmentName': school,
      'access':
          access ??
          {'ownPhone': true, 'accessCode': false, 'accessCodeIssuedAt': null},
      'subscription':
          subscription ??
          {
            'status': 'active',
            'endsAt': '2026-10-15T00:00:00.000Z',
            'offerId': 'school-a',
            'paidBy': 'another_guardian',
          },
      'offerAvailable': true,
    };

    test('reads access, school and payer without any credential', () {
      final child = ParentChildSummary.fromMap(summary());
      expect(child.access.ownPhone, isTrue);
      expect(child.access.accessCode, isFalse);
      expect(child.establishmentName, 'Lycée A');
      expect(child.subscription.active, isTrue);
      expect(child.subscription.paidBy, ChildSubscriptionPayer.anotherGuardian);
      expect(child.pendingFirstSignIn, isFalse);
    });

    ParentChildProfile linked(String id) => ParentChildProfile(
      id: id,
      firstName: 'Awa',
      classLevel: 'Terminale',
      series: null,
      globalProgress: 0.4,
      studyMinutesToday: 12,
      studyMinutesTarget: 45,
      strongSubjects: const [],
      weakSubjects: const [],
      weeklyProgress: const [],
    );

    test(
      'the server projection enriches Firestore children and never replaces their progress',
      () {
        final merged = mergeChildSummaries(
          [linked('child-a')],
          {'child-a': ParentChildSummary.fromMap(summary())},
        );
        expect(merged.single.establishmentName, 'Lycée A');
        expect(merged.single.access?.ownPhone, isTrue);
        expect(merged.single.globalProgress, 0.4);
        expect(merged.single.lastName, 'Mbarga');
      },
    );

    test(
      'without the projection (function not deployed), children stay visible, access unknown',
      () {
        final merged = mergeChildSummaries([linked('child-a')], null);
        expect(merged.single.id, 'child-a');
        expect(merged.single.access, isNull);
        expect(merged.single.subscription, isNull);
      },
    );

    test(
      'a child whose parent opened the access appears before any profile exists',
      () {
        final merged = mergeChildSummaries(
          [linked('child-a')],
          {
            'child-a': ParentChildSummary.fromMap(summary()),
            'child-new': ParentChildSummary.fromMap(
              summary(
                id: 'child-new',
                status: 'pending_first_sign_in',
                school: '',
                access: {'ownPhone': false, 'accessCode': true},
              ),
            ),
            // Un enfant actif sans profil Firestore lisible n'est pas inventé.
            'child-ghost': ParentChildSummary.fromMap(
              summary(id: 'child-ghost'),
            ),
          },
        );
        expect(merged.map((child) => child.id), ['child-a', 'child-new']);
        expect(merged.last.pendingFirstSignIn, isTrue);
        expect(merged.last.access?.accessCode, isTrue);
      },
    );
  });

  group('Mobile Money per child', () {
    test(
      'an older server has no beneficiary support: the field is never sent',
      () {
        final legacy = MobileMoneyOverview.fromMap({
          'availability': 'multiple_schools',
          'offer': null,
          'recentRequests': [],
        });
        expect(legacy.supportsBeneficiary, isFalse);
        expect(legacy.availability, MobileMoneyAvailability.multipleSchools);
      },
    );

    test(
      'a current server lists children with their schools and the covered children',
      () {
        final overview = MobileMoneyOverview.fromMap({
          'availability': 'available',
          'offer': {
            'id': 'school-b',
            'establishmentId': 'school-b',
            'title': 'Offre B',
            'description': 'Accès',
            'amountXaf': 4000,
            'durationDays': 90,
            'operators': [
              {
                'code': 'mtn',
                'label': 'MTN',
                'recipientPhone': '+237670000000',
              },
            ],
          },
          'recentRequests': [
            {
              'requestId': 'r1',
              'establishmentId': 'school-b',
              'beneficiaryStudentId': 'child-b',
              'status': 'pending',
            },
          ],
          'children': [
            {
              'studentId': 'child-a',
              'firstName': 'Awa',
              'establishmentId': 'school-a',
            },
            {
              'studentId': 'child-b',
              'firstName': 'Bilal',
              'establishmentId': 'school-b',
            },
          ],
          'beneficiary': {
            'studentId': 'child-b',
            'firstName': 'Bilal',
            'establishmentId': 'school-b',
          },
          'coveredStudentIds': ['child-b'],
        });
        expect(overview.supportsBeneficiary, isTrue);
        expect(overview.children.map((child) => child.establishmentId), [
          'school-a',
          'school-b',
        ]);
        expect(overview.beneficiary?.studentId, 'child-b');
        expect(overview.offer?.amountXaf, 4000);
        expect(overview.coveredStudentIds, ['child-b']);
        expect(overview.recentRequests.single.beneficiaryStudentId, 'child-b');
      },
    );
  });
}
