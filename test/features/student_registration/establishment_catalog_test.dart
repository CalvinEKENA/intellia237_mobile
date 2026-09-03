import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_registration/data/establishment_catalog.dart';

void main() {
  test('ships a structured seed covering every Cameroon region', () {
    expect(EstablishmentCatalog.all, hasLength(100));
    expect(EstablishmentCatalog.countByRegion, hasLength(10));
    expect(
      EstablishmentCatalog.countByRegion.values,
      everyElement(greaterThanOrEqualTo(10)),
    );
    for (final establishment in EstablishmentCatalog.all) {
      expect(establishment.id, isNotEmpty);
      expect(establishment.officialName, isNotEmpty);
      expect(establishment.normalizedName, isNotEmpty);
      expect(establishment.region, isNotEmpty);
      expect(establishment.city, isNotEmpty);
      expect(establishment.educationTypes, isNotEmpty);
    }
  });

  test('normalizes accents, punctuation and apostrophes', () {
    expect(
      EstablishmentSearch.normalize('Lycée d’Édéa — Centre'),
      'lycee d edea centre',
    );
    expect(
      EstablishmentSearch.normalize("Collège d'Application"),
      'college d application',
    );
  });

  test('progressively makes Lycée Général Leclerc dominant', () {
    final broad = EstablishmentSearch.query('L');
    expect(broad.length, greaterThan(1));

    final lycees = EstablishmentSearch.query('Lycée');
    expect(lycees, isNotEmpty);

    final leclerc = EstablishmentSearch.query('Lecl');
    expect(leclerc.first.establishment.officialName, 'Lycée Général Leclerc');
    expect(leclerc.first.isDominant, isTrue);
    expect(
      leclerc.first.highlightEnd,
      greaterThan(leclerc.first.highlightStart),
    );
  });

  test('matches aliases, city and light typos deterministically', () {
    expect(
      EstablishmentSearch.query('LGL').first.establishment.id,
      'ce-yaounde-leclerc',
    );
    expect(
      EstablishmentSearch.query('leclrc').first.establishment.id,
      'ce-yaounde-leclerc',
    );
    final first = EstablishmentSearch.query(
      'Douala',
    ).map((e) => e.establishment.id);
    final second = EstablishmentSearch.query(
      'Douala',
    ).map((e) => e.establishment.id);
    expect(first, orderedEquals(second));
  });
}
