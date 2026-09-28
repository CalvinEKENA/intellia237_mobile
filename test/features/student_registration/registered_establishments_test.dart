import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_registration/data/establishment_catalog.dart';
import 'package:intellia237/features/student_registration/domain/establishment.dart';

void main() {
  final school = Establishment(
    id: 'firebase-vogt',
    officialName: 'Collège F.X VOGT',
    normalizedName: 'college f x vogt',
    aliases: const [],
    region: '',
    city: 'Yaoundé',
    type: EstablishmentType.college,
    subsystem: EstablishmentSubsystem.bilingual,
    educationTypes: EstablishmentEducationType.values,
    status: EstablishmentCatalogStatus.active,
  );

  test(
    'search uses only the supplied catalogue, including city and accents',
    () {
      expect(
        EstablishmentSearch.query(
          'Yaounde',
          catalog: [school],
        ).single.establishment.id,
        'firebase-vogt',
      );
      expect(EstablishmentSearch.query('Leclerc', catalog: [school]), isEmpty);
      expect(EstablishmentSearch.query('Vogt', catalog: const []), isEmpty);
    },
  );
}
