import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';

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
  });
}
