import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/learn/domain/curriculum_catalog.dart';
import 'package:intellia237/features/mastery/domain/mastery_estimate.dart';
import 'package:intellia237/features/mastery/domain/mastery_policy.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';

/// Le profil de maîtrise n'affichait que « Anglais » et « SVT » : sa liste
/// venait des matières **publiées** dans Firestore, donc des seules matières
/// alimentées en contenu. Le catalogue du programme est désormais une source
/// distincte des preuves de maîtrise.
void main() {
  List<String> idsFor(SchoolClass schoolClass, [SchoolSeries? series]) =>
      CurriculumCatalog.forLevel(
        schoolClass: schoolClass,
        series: series,
      ).map((subject) => subject.id).toList();

  group('premier cycle francophone', () {
    test('la 6e porte le tronc commun sans PCT ni LV2', () {
      final ids = idsFor(SchoolClass.sixieme);

      expect(ids, contains('maths'));
      expect(ids, contains('svteehb'));
      expect(ids, contains('francais'));
      expect(ids, contains('anglais'));
      expect(ids, contains('lcn'));
      expect(ids, contains('histoire'));
      expect(ids, contains('geographie'));
      expect(ids, contains('ecm'));
      expect(ids, contains('informatique'));
      // PCT et LV2 n'apparaissent qu'à partir de la 4e.
      expect(ids, isNot(contains('pct')));
      expect(ids, isNot(contains('lv2')));
    });

    test('la 4e ajoute PCT, la LV2 et le texte suivi', () {
      final ids = idsFor(SchoolClass.quatrieme);

      expect(ids, contains('pct'));
      expect(ids, contains('lv2'));
      expect(ids, contains('litterature'));
    });

    test('la 3e garde le même programme que la 4e', () {
      expect(idsFor(SchoolClass.troisieme), idsFor(SchoolClass.quatrieme));
    });
  });

  group('second cycle francophone', () {
    test('la Seconde C est scientifique', () {
      final ids = idsFor(SchoolClass.seconde, SchoolSeries.c);

      expect(ids, containsAll(['maths', 'physique', 'chimie', 'svteehb']));
      expect(ids, contains('histoire_geographie'));
      expect(ids, isNot(contains('latin')));
    });

    test('la Seconde A est littéraire et garde des compléments', () {
      final ids = idsFor(SchoolClass.seconde, SchoolSeries.a);

      expect(ids, containsAll(['francais', 'litterature', 'lv2', 'latin']));
      // Compléments explicitement demandés par le programme.
      expect(ids, containsAll(['maths', 'svteehb', 'informatique', 'ecm']));
    });

    test('la Terminale D est biologique et porte la philosophie', () {
      final ids = idsFor(SchoolClass.terminale, SchoolSeries.d);

      expect(ids.first, 'svteehb');
      expect(ids, containsAll(['maths', 'physique', 'chimie', 'informatique']));
      expect(ids, contains('philosophie'));
    });

    test('la philosophie n’apparaît pas en Première', () {
      // L'annoncer un an trop tôt promettrait une matière que l'élève n'a pas.
      expect(
        idsFor(SchoolClass.premiere, SchoolSeries.d),
        isNot(contains('philosophie')),
      );
      expect(
        idsFor(SchoolClass.premiere, SchoolSeries.c),
        isNot(contains('philosophie')),
      );
      expect(
        idsFor(SchoolClass.premiere, SchoolSeries.a),
        isNot(contains('philosophie')),
      );
    });

    test('la Terminale A porte les lettres et la philosophie', () {
      final ids = idsFor(SchoolClass.terminale, SchoolSeries.a);

      expect(
        ids,
        containsAll(['litterature', 'anglais', 'lv2', 'philosophie']),
      );
      expect(ids, containsAll(['maths', 'svteehb', 'informatique']));
    });
  });

  group('exclusions assumées', () {
    test('aucun niveau ne propose l’EPS ni de matière purement pratique', () {
      for (final schoolClass in SchoolClassX.ordered) {
        for (final series in [null, ...schoolClass.allowedSeries]) {
          final ids = idsFor(schoolClass, series);
          expect(ids, isNot(contains('eps')));
          expect(ids, isNot(contains('sport')));
          expect(ids, isNot(contains('musique')));
          expect(ids, isNot(contains('arts')));
        }
      }
    });

    test('le sous-système anglophone reste vide plutôt qu’inventé', () {
      // Aucune donnée curriculaire anglophone n'existe dans le projet : les
      // élèves anglophones conservent les matières réellement publiées.
      for (final schoolClass in SchoolClassX.orderedAnglophone) {
        expect(idsFor(schoolClass), isEmpty);
      }
    });

    test('chaque matière est unique dans un niveau donné', () {
      for (final schoolClass in SchoolClassX.ordered) {
        for (final series in [null, ...schoolClass.allowedSeries]) {
          final ids = idsFor(schoolClass, series);
          expect(ids.toSet(), hasLength(ids.length));
        }
      }
    });
  });

  group('normalisation des identifiants publiés', () {
    test('les variantes historiques rejoignent la matière canonique', () {
      expect(CurriculumCatalog.normalizeId('SVT'), 'svteehb');
      expect(
        CurriculumCatalog.normalizeId('Sciences de la Vie et de la Terre'),
        'svteehb',
      );
      expect(CurriculumCatalog.normalizeId('Mathématiques'), 'maths');
      expect(CurriculumCatalog.normalizeId('Maths'), 'maths');
      expect(CurriculumCatalog.normalizeId('English'), 'anglais');
      expect(
        CurriculumCatalog.normalizeId('Histoire-Géographie'),
        'histoire_geographie',
      );
    });

    test('une matière inconnue garde sa forme normalisée', () {
      expect(
        CurriculumCatalog.normalizeId('Atelier Théâtre'),
        'ateliertheatre',
      );
    });
  });

  group('le contrat de maîtrise reste inchangé', () {
    test('les plafonds de source ne bougent pas', () {
      // Afficher plus de matières ne donne aucun droit d'estimer davantage.
      expect(MasteryCalibration.sourceStateCeiling, MasteryState.building);
      expect(
        MasteryCalibration.sourceConfidenceCeiling,
        MasteryConfidence.limited,
      );
    });

    test('une matière sans preuve n’obtient aucune estimation', () {
      const profile = MasteryProfile();
      final estimate = profile.forSubject('philosophie');

      expect(estimate.entityId, 'philosophie');
      expect(estimate.state, MasteryState.noEvidence);
    });
  });
}
