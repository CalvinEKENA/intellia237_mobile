import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/domain/academic_level_identity.dart';

void main() {
  group('SchoolClass rules', () {
    test('matches Web App class order', () {
      expect(SchoolClassX.ordered.map((item) => item.label), [
        '6ème',
        '5ème',
        '4ème',
        '3ème',
        '2nde',
        '1ère',
        'Terminale',
      ]);
    });

    test('requires series only from 2nde to Terminale', () {
      expect(SchoolClass.sixieme.requiresSeries, isFalse);
      expect(SchoolClass.cinquieme.requiresSeries, isFalse);
      expect(SchoolClass.quatrieme.requiresSeries, isFalse);
      expect(SchoolClass.troisieme.requiresSeries, isFalse);
      expect(SchoolClass.seconde.allowedSeries.map((item) => item.label), [
        'A',
        'C',
      ]);
      expect(SchoolClass.premiere.allowedSeries.map((item) => item.label), [
        'A',
        'C',
        'D',
      ]);
      expect(SchoolClass.terminale.allowedSeries.map((item) => item.label), [
        'A',
        'C',
        'D',
      ]);
    });

    test('stable IDs never depend on localized francophone labels', () {
      expect(
        SchoolClass.sixieme.academicLevelId(EducationType.general),
        'fr_general_6e',
      );
      expect(
        SchoolClass.premiere.academicLevelId(EducationType.general),
        'fr_general_1ere',
      );
      expect(
        SchoolClass.terminale.academicLevelId(EducationType.technical),
        'fr_technical_terminale',
      );
      expect(SchoolClassX.fromStoredValue('6ème'), SchoolClass.sixieme);
      expect(SchoolClassX.fromStoredValue('6eme'), SchoolClass.sixieme);
      expect(
        SchoolClassX.fromStoredValue('fr_general_6e'),
        SchoolClass.sixieme,
      );
      expect(SchoolClassX.fromStoredValue('1ère'), SchoolClass.premiere);
      expect(SchoolClassX.fromStoredValue('Premiere'), SchoolClass.premiere);
      expect(SchoolClassX.fromStoredValue('Première'), SchoolClass.premiere);
      expect(SchoolClass.premiere.catalogKey, 'Premiere');
      expect(SchoolClass.premiere.label, '1ère');
    });

    test(
      'anglophone labels and historical keys map to the same stable level',
      () {
        expect(
          SchoolClass.form1.academicLevelId(EducationType.general),
          'en_general_form1',
        );
        expect(
          SchoolClass.lowerSixth.academicLevelId(EducationType.general),
          'en_general_lower_sixth',
        );
        expect(SchoolClassX.fromStoredValue('Form 1'), SchoolClass.form1);
        expect(SchoolClassX.fromStoredValue('Form1'), SchoolClass.form1);
        expect(
          SchoolClassX.fromStoredValue('en_general_form1'),
          SchoolClass.form1,
        );
        expect(
          SchoolClassX.fromStoredValue('Lower Sixth'),
          SchoolClass.lowerSixth,
        );
        expect(
          SchoolClassX.fromStoredValue('LowerSixth'),
          SchoolClass.lowerSixth,
        );
      },
    );

    test('general and technical remain separate typed dimensions', () {
      final general = AcademicLevelIdentity.resolve(
        academicLevelId: 'fr_general_2nde',
        educationalSubsystem: 'francophone',
        educationType: 'general',
      );
      final technical = AcademicLevelIdentity.resolve(
        academicLevelId: 'fr_technical_2nde',
        educationalSubsystem: 'francophone',
        educationType: 'technical',
      );

      expect(general?.catalogKey, technical?.catalogKey);
      expect(general?.stableId, 'fr_general_2nde');
      expect(technical?.stableId, 'fr_technical_2nde');
      expect(general?.educationType, EducationType.general);
      expect(technical?.educationType, EducationType.technical);
    });

    test('a subsystem mismatch is rejected instead of guessed', () {
      expect(
        AcademicLevelIdentity.resolve(
          storedClassLevel: 'Form1',
          educationalSubsystem: 'francophone',
          educationType: 'general',
        ),
        isNull,
      );
    });

    test('a contradictory canonical ID or unknown dimension is rejected', () {
      expect(
        AcademicLevelIdentity.resolve(
          academicLevelId: 'fr_technical_6e',
          educationalSubsystem: 'francophone',
          educationType: 'general',
        ),
        isNull,
      );
      expect(
        AcademicLevelIdentity.resolve(
          storedClassLevel: '6eme',
          educationalSubsystem: 'francophone',
          educationType: 'professional',
        ),
        isNull,
      );
    });
  });
}
