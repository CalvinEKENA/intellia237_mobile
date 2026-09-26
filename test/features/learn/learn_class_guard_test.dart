import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/learn/domain/learn_class_guard.dart';

/// Registre (QA appareil, 25/09/2026) : un compte Terminale D voyait des
/// cours de SVT et d'Anglais du premier cycle, copiés par un script
/// d'amorçage sous `classes/Terminale` sans aucune déclaration de classe.
void main() {
  group('ClassKey : une règle pour toutes les classes', () {
    test('écritures courantes ramenées à une clé canonique', () {
      expect(ClassKey.fromProfile('6ème')?.key, 'sixieme');
      expect(ClassKey.fromProfile('6eme')?.key, 'sixieme');
      expect(ClassKey.fromProfile('3ème')?.key, 'troisieme');
      expect(ClassKey.fromProfile('Seconde')?.key, 'seconde');
      expect(ClassKey.fromProfile('Première', series: 'D')?.key, 'premiere-d');
      expect(
        ClassKey.fromProfile('Terminale', series: 'C')?.key,
        'terminale-c',
      );
      expect(
        ClassKey.fromProfile('Terminale', series: 'Série D')?.key,
        'terminale-d',
      );
      expect(ClassKey.fromProfile('Tle', series: 'd')?.key, 'terminale-d');
      expect(ClassKey.fromProfile('Form1')?.key, 'form1');
      expect(ClassKey.fromProfile('inconnue'), isNull);
    });

    test('cibles : une série, plusieurs séries, tout le niveau', () {
      expect(ClassKey.parseTargets('terminale-d'), [
        const ClassKey('terminale', series: 'd'),
      ]);
      expect(ClassKey.parseTargets('terminale-c-d'), [
        const ClassKey('terminale', series: 'c'),
        const ClassKey('terminale', series: 'd'),
      ]);
      expect(ClassKey.parseTargets('Terminale D'), [
        const ClassKey('terminale', series: 'd'),
      ]);
      expect(ClassKey.parseTargets('sixieme'), [const ClassKey('sixieme')]);
    });

    test('admission : même niveau, et même série quand elle est exigée', () {
      const td = ClassKey('terminale', series: 'd');
      const tc = ClassKey('terminale', series: 'c');
      expect(td.admits(const ClassKey('terminale')), isTrue);
      expect(td.admits(const ClassKey('terminale', series: 'd')), isTrue);
      expect(tc.admits(const ClassKey('terminale', series: 'd')), isFalse);
      expect(td.admits(const ClassKey('sixieme')), isFalse);
      expect(
        const ClassKey('sixieme').admits(const ClassKey('terminale')),
        isFalse,
      );
      final commonCD = ClassKey.parseTargets('terminale-c-d');
      expect(td.admitsAny(commonCD), isTrue);
      expect(tc.admitsAny(commonCD), isTrue);
      expect(
        const ClassKey('terminale', series: 'a').admitsAny(commonCD),
        isFalse,
      );
    });
  });

  group('LearnClassGuard : Apprendre ne montre que la classe de l\'élève', () {
    final terminaleD = LearnClassGuard.forProfile('Terminale', 'D');
    final terminaleC = LearnClassGuard.forProfile('Terminale', 'C');
    final sixieme = LearnClassGuard.forProfile('6eme', null);

    // Exactement les documents d'amorçage trouvés en production.
    const seededSubject = <String, dynamic>{
      'title': 'SVT',
      'description':
          'Sciences de la Vie et de la Terre, Éducation à l\'Environnement, '
          'Hygiène et Biotechnique',
      'status': 'published',
    };
    const seededChapter = <String, dynamic>{
      'title': 'Module 1: Le monde vivant',
      'status': 'published',
    };

    test('un chapitre sans classe déclarée n\'entre jamais dans la liste', () {
      expect(
        terminaleD.admitsChapter(seededChapter, subject: seededSubject),
        isFalse,
      );
      expect(
        sixieme.admitsChapter(seededChapter, subject: seededSubject),
        isFalse,
      );
    });

    test('un compte Terminale D ne voit aucun cours de Sixième', () {
      const sixiemeChapter = {'title': 'Climat', 'classLevel': '6eme'};
      expect(terminaleD.admitsChapter(sixiemeChapter), isFalse);
      expect(sixieme.admitsChapter(sixiemeChapter), isTrue);
    });

    test('un compte Sixième ne voit aucun cours de Terminale', () {
      const terminaleChapter = {
        'title': 'Arithmétique',
        'classLevel': 'Terminale',
      };
      expect(sixieme.admitsChapter(terminaleChapter), isFalse);
      expect(terminaleD.admitsChapter(terminaleChapter), isTrue);
    });

    test('contenu commun C-D explicite : visible en C et en D, pas en A', () {
      const common = {
        'audience': {
          'version': 1,
          'clauses': [
            {
              'classLevels': ['Terminale'],
              'series': ['C', 'D'],
            },
          ],
        },
      };
      expect(terminaleD.admitsChapter(common), isTrue);
      expect(terminaleC.admitsChapter(common), isTrue);
      expect(
        LearnClassGuard.forProfile('Terminale', 'A').admitsChapter(common),
        isFalse,
      );
    });

    test('contenu réservé à Terminale D : absent de Terminale C', () {
      const onlyD = {
        'classLevels': ['Terminale'],
        'series': ['D'],
      };
      expect(terminaleD.admitsChapter(onlyD), isTrue);
      expect(terminaleC.admitsChapter(onlyD), isFalse);
    });

    test('la série exigée par la matière s\'applique au chapitre', () {
      const subject = {
        'classLevel': 'Terminale',
        'allowedSeries': ['D'],
      };
      const chapter = {'classLevel': 'Terminale'};
      expect(terminaleD.admitsChapter(chapter, subject: subject), isTrue);
      expect(terminaleC.admitsChapter(chapter, subject: subject), isFalse);
    });

    test('une audience sans classe ne vaut jamais « toutes les classes »', () {
      const open = {
        'audience': {
          'version': 1,
          'clauses': [
            {
              'educationSystems': ['francophone'],
            },
          ],
        },
      };
      expect(terminaleD.admitsChapter(open), isFalse);
      expect(sixieme.admitsChapter(open), isFalse);
    });

    test('sans classe connue, rien n\'est admis', () {
      expect(
        const LearnClassGuard(null).admitsChapter({'classLevel': '6eme'}),
        isFalse,
      );
    });
  });
}
