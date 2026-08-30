import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/intellia_pass/domain/auth_method.dart';
import 'package:intellia237/features/intellia_pass/domain/household_profile.dart';
import 'package:intellia237/features/intellia_pass/domain/intellia_offer.dart';
import 'package:intellia237/features/intellia_pass/domain/parental_gate.dart';
import 'package:intellia237/features/student_registration/domain/academic_passport.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/domain/learning_goal.dart';
import 'package:intellia237/features/student_registration/domain/student_registration_payload.dart';

void main() {
  group('academic passport', () {
    test('interface language and educational subsystem are independent', () {
      const passport = AcademicPassport(
        preferredDisplayName: 'Amina',
        interfaceLanguage: InterfaceLanguage.english,
        educationalSubsystem: EducationalSubsystem.francophone,
        educationType: EducationType.general,
        level: SchoolClass.terminale,
        accountLinkage: LearnerAccountLinkage.parentManaged,
      );

      expect(passport.interfaceLanguage.code, 'en');
      expect(passport.educationalSubsystem, EducationalSubsystem.francophone);
      expect(passport.hasConsistentLevel, isTrue);
    });

    test('francophone and anglophone level catalogues are complete', () {
      expect(SchoolClassX.ordered, hasLength(7));
      expect(SchoolClassX.orderedAnglophone.map((level) => level.label), [
        'Form 1',
        'Form 2',
        'Form 3',
        'Form 4',
        'Form 5',
        'Lower Sixth',
        'Upper Sixth',
      ]);
    });

    test('an establishment choice never grants private access by itself', () {
      const candidate = EstablishmentAffiliation(name: 'Lycée Exemple');
      const verified = EstablishmentAffiliation(
        name: 'Lycée Exemple',
        status: EstablishmentAffiliationStatus.verified,
      );

      expect(candidate.grantsPrivateAccess, isFalse);
      expect(verified.grantsPrivateAccess, isTrue);
    });

    test('candidate school stays in preferences, not authority fields', () {
      const payload = StudentRegistrationPayload(
        firstName: 'Amina',
        lastName: 'Ndi',
        schoolClass: SchoolClass.terminale,
        schoolSeries: SchoolSeries.d,
        establishment: EstablishmentAffiliation(name: 'Lycée Exemple'),
        preferredSubjects: [],
        difficultSubjects: [],
        learningGoal: LearningGoal.examMastery,
        dailyStudyMinutes: 45,
        email: 'amina@example.com',
        password: 'password8',
        acceptedTerms: true,
        acceptedPrivacy: true,
        acceptedDataPolicy: true,
      );
      final profile = payload.toStudentProfileDocument(
        uid: 'uid',
        now: DateTime.utc(2026),
      );

      expect(profile.containsKey('establishmentId'), isFalse);
      expect(
        (profile['preferences'] as Map<String, dynamic>).containsKey(
          'establishmentCandidate',
        ),
        isTrue,
      );
    });
  });

  test('a household supports several learner profiles without credentials', () {
    final household = HouseholdProfiles(const [
      LearnerProfileSummary(
        id: 'one',
        displayName: 'Amina',
        levelLabel: '3ème',
      ),
      LearnerProfileSummary(
        id: 'two',
        displayName: 'Léo',
        levelLabel: 'Form 2',
      ),
    ]);

    expect(household.supportsSharedDevice, isTrue);
    expect(household.findById('two')?.displayName, 'Léo');
  });

  test('parental gate expresses local proof without server authority', () {
    const request = ParentalGateRequest(
      operation: ParentalOperation.addLearner,
      method: ParentalGateMethod.parentPin,
    );

    expect(request.operation, ParentalOperation.addLearner);
    expect(request.method, ParentalGateMethod.parentPin);
    expect(ParentalGate, isNotNull);
  });

  test('authentication roadmap is explicit and ordered', () {
    expect(IntelliaAuthMethod.phoneOtp.priority, 1);
    expect(IntelliaAuthMethod.phoneOtp.isAvailableNow, isFalse);
    expect(IntelliaAuthMethod.email.isAvailableNow, isTrue);
    expect(IntelliaAuthMethod.parentLinked.isAvailableNow, isTrue);
    expect(IntelliaAuthMethod.passkey.isAvailableNow, isFalse);
  });

  test('offers preserve exact prices, modalities, and restrained naming', () {
    final essentiel = IntelliaOfferDetails.values[IntelliaOffer.essentiel]!;
    final plus = IntelliaOfferDetails.values[IntelliaOffer.plus]!;
    final max = IntelliaOfferDetails.values[IntelliaOffer.max]!;

    expect(essentiel.monthlyPriceXaf, 5000);
    expect(essentiel.voice, isFalse);
    expect(essentiel.vision, isFalse);
    expect(essentiel.includes(IntelliaCapability.flow), isTrue);
    expect(essentiel.includes(IntelliaCapability.arena), isTrue);
    expect(plus.monthlyPriceXaf, 10000);
    expect(plus.supportLabelFr, 'Accompagnement étendu');
    expect(plus.supportLabelEn, 'Extended support');
    expect(plus.voice && plus.vision, isTrue);
    expect(max.monthlyPriceXaf, 15000);
    expect(max.supportLabelFr, 'Accompagnement complet');
    expect(max.supportLabelEn, 'Complete support');
    expect(max.multimodalLevel, greaterThan(plus.multimodalLevel));
    expect(
      IntelliaOfferDetails.values.values
          .expand((offer) => [offer.supportLabelFr, offer.supportLabelEn])
          .join(' ')
          .toLowerCase(),
      isNot(contains('généreux')),
    );
  });

  test('energy is qualitative and exposes no monetary or token amount', () {
    expect(IntelliaEnergyLevel.values.map((level) => level.name), [
      'available',
      'balanced',
      'limited',
    ]);
  });
}
