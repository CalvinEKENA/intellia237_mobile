import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia_studio/core/academic/academic_context_provider.dart';
import 'package:intellia_studio/core/academic/academic_hierarchy.dart';
import 'package:intellia_studio/features/publishing/presentation/publishing_screen.dart';

void main() {
  group('AcademicHierarchy Canonical Ordering', () {
    test('Francophone classes follow MINESEC canonical pedagogical order', () {
      final classes = AcademicHierarchy.francophoneClasses;
      final labels = classes.map((c) => c.shortLabel).toList();

      expect(labels, [
        '6e',
        '5e',
        '4e',
        '3e',
        '2nde',
        '1ère',
        'Tle',
      ]);
    });

    test('Anglophone classes follow MINESEC canonical pedagogical order', () {
      final classes = AcademicHierarchy.anglophoneClasses;
      final labels = classes.map((c) => c.label).toList();

      expect(labels, [
        'Form 1',
        'Form 2',
        'Form 3',
        'Form 4',
        'Form 5',
        'Lower Sixth',
        'Upper Sixth',
      ]);
    });

    test('Canonical order is strictly non-alphabetical', () {
      final classes = AcademicHierarchy.francophoneClasses;
      final labels = classes.map((c) => c.label).toList();

      // Alphabetical order would sort lexically
      final alphabetical = List<String>.from(labels)..sort();

      // The canonical MINESEC order starts with 6e and ends with Terminale
      expect(labels.first, contains('6'));
      expect(labels.last, 'Terminale');
      expect(labels, isNot(equals(alphabetical)),
          reason: 'Academic order must not be sorted alphabetically');
    });

    test('Series/streams are only available for upper secondary classes', () {
      // Francophone: 6e to 3e have NO series
      expect(AcademicHierarchy.findByKey('6eme')!.allowedSeries, isEmpty);
      expect(AcademicHierarchy.findByKey('5eme')!.allowedSeries, isEmpty);
      expect(AcademicHierarchy.findByKey('4eme')!.allowedSeries, isEmpty);
      expect(AcademicHierarchy.findByKey('3eme')!.allowedSeries, isEmpty);

      // Seconde has A, C
      expect(AcademicHierarchy.findByKey('seconde')!.allowedSeries, ['A', 'C']);

      // Première & Terminale have A, C, D, TI
      expect(AcademicHierarchy.findByKey('premiere')!.allowedSeries, ['A', 'C', 'D', 'TI']);
      expect(AcademicHierarchy.findByKey('terminale')!.allowedSeries, ['A', 'C', 'D', 'TI']);

      // Anglophone: Form 1 to 5 have NO streams
      expect(AcademicHierarchy.findByKey('Form1')!.allowedSeries, isEmpty);
      expect(AcademicHierarchy.findByKey('Form5')!.allowedSeries, isEmpty);

      // Lower/Upper Sixth have Arts, Science
      expect(AcademicHierarchy.findByKey('LowerSixth')!.allowedSeries, ['Arts', 'Science']);
      expect(AcademicHierarchy.findByKey('UpperSixth')!.allowedSeries, ['Arts', 'Science']);
    });

    test('Pedagogical compare sorts arbitrarily shuffled classes into canonical MINESEC order', () {
      final shuffled = [
        AcademicHierarchy.findByKey('terminale')!,
        AcademicHierarchy.findByKey('6eme')!,
        AcademicHierarchy.findByKey('seconde')!,
        AcademicHierarchy.findByKey('4eme')!,
        AcademicHierarchy.findByKey('premiere')!,
        AcademicHierarchy.findByKey('3eme')!,
        AcademicHierarchy.findByKey('5eme')!,
      ];

      shuffled.sort(AcademicHierarchy.compare);

      final sortedShortLabels = shuffled.map((c) => c.shortLabel).toList();
      expect(sortedShortLabels, [
        '6e',
        '5e',
        '4e',
        '3e',
        '2nde',
        '1ère',
        'Tle',
      ]);
    });
  });

  group('AcademicContextProvider and Session Context', () {
    test('Initial context is neutral with no accidental Terminale default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(academicContextProvider);

      // Neutral default: NO class selected automatically
      expect(state.selectedClass, isNull,
          reason: 'Must never accidentally default to Terminale');
      expect(state.series, isNull);
      expect(state.subject, isNull);
      expect(state.isPublicationReady, isFalse);
    });

    test('Context updates and persists state across actions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(academicContextProvider.notifier);

      // Set class to 3e
      notifier.setClassByCatalogKey('3eme');
      var state = container.read(academicContextProvider);
      expect(state.selectedClass?.shortLabel, '3e');
      expect(state.selectedClass?.order, 40);
      expect(state.series, isNull);

      // Set subject
      notifier.setSubject(const CanonicalSubject(id: 'maths', name: 'Mathématiques', iconName: 'calculate'));
      state = container.read(academicContextProvider);
      expect(state.subject?.name, 'Mathématiques');
      expect(state.isPublicationReady, isTrue);

      // Switching system resets class if class is not in system
      notifier.setSystem(StudioEducationSystem.anglophone);
      state = container.read(academicContextProvider);
      expect(state.system, StudioEducationSystem.anglophone);
      expect(state.selectedClass, isNull);
    });

    test('Series resets automatically if class changes to a class without series', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(academicContextProvider.notifier);

      notifier.setClassByCatalogKey('terminale');
      notifier.setSeries('C');
      expect(container.read(academicContextProvider).series, 'C');

      // Change to 4e (no series allowed)
      notifier.setClassByCatalogKey('4eme');
      expect(container.read(academicContextProvider).series, isNull);
    });

    test('Breadcrumb formatting contains full canonical academic path', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(academicContextProvider.notifier);
      notifier.setClassByCatalogKey('terminale');
      notifier.setSeries('C');
      notifier.setSubject(const CanonicalSubject(id: 'maths', name: 'Mathématiques', iconName: 'calculate'));

      final state = container.read(academicContextProvider);
      expect(state.breadcrumb, 'FRANCOPHONE › TLE (C) › MATHÉMATIQUES');
    });
  });

  group('Publishing Center Academic Integrity', () {
    test('PublishingReleaseItem exposes full academic path and target badge', () {
      const item = PublishingReleaseItem(
        id: 'rel_test_1',
        title: 'TVI et stricte monotonie',
        type: 'FLOW',
        system: 'Francophone',
        classLevels: ['Terminale'],
        series: ['C', 'D'],
        subject: 'Mathématiques',
        chapter: 'Limites et continuité',
        author: 'Inspection MINESEC',
        audience: 'Micro-learning',
        status: 'approved',
      );

      expect(item.targetBadge, 'Francophone • Terminale [C/D] • Mathématiques');
      expect(item.academicPath,
          'Terminale (C, D) > Mathématiques > Limites et continuité > FLOW > "TVI et stricte monotonie"');
    });

    test('Filtering strictly isolates classes without cross-class leakage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final items = container.read(releaseItemsProvider);

      // Verify sample contents contain different class targets
      final terminaleItems = items.where((i) => i.classLevels.contains('Terminale')).toList();
      final troisiemeItems = items.where((i) => i.classLevels.contains('3e')).toList();

      expect(terminaleItems, isNotEmpty);
      expect(troisiemeItems, isNotEmpty);

      // Verify no leak between Terminale and 3e items
      for (final it in terminaleItems) {
        expect(it.classLevels, isNot(contains('3e')));
      }
      for (final it in troisiemeItems) {
        expect(it.classLevels, isNot(contains('Terminale')));
      }
    });
  });

  group('AcademicHierarchy Class-Aware Subject Derivation', () {
    test('6ème subjects do NOT include Philosophie or separate Physique-Chimie', () {
      final sixieme = AcademicHierarchy.findByKey('6eme');
      expect(sixieme, isNotNull);

      final subjects = AcademicHierarchy.getSubjectsFor(classLevel: sixieme);
      final subjectIds = subjects.map((s) => s.id).toList();

      // Core subjects present
      expect(subjectIds, contains('maths'));
      expect(subjectIds, contains('svt'));
      expect(subjectIds, contains('informatique'));
      expect(subjectIds, contains('francais'));
      expect(subjectIds, contains('anglais'));
      expect(subjectIds, contains('histoire_geo'));
      expect(subjectIds, contains('ecm'));

      // Prohibited subjects strictly excluded
      expect(subjectIds, isNot(contains('philosophie')),
          reason: 'Philosophie must NOT be offered in 6ème');
      expect(subjectIds, isNot(contains('physique')),
          reason: 'PCT/Physique-Chimie only begins in 4ème');
      expect(subjectIds, isNot(contains('economie')),
          reason: 'Economie is not in lower secondary');
    });

    test('3ème subjects include PCT (physique) but NOT Philosophie', () {
      final troisieme = AcademicHierarchy.findByKey('3eme');
      expect(troisieme, isNotNull);

      final subjects = AcademicHierarchy.getSubjectsFor(classLevel: troisieme);
      final subjectIds = subjects.map((s) => s.id).toList();

      expect(subjectIds, contains('physique')); // PCT
      expect(subjectIds, isNot(contains('philosophie')),
          reason: 'Philosophie only exists in Terminale');
    });

    test('Première subjects do NOT include Philosophie', () {
      final premiere = AcademicHierarchy.findByKey('premiere');
      expect(premiere, isNotNull);

      for (final series in ['A', 'C', 'D', 'TI']) {
        final subjects = AcademicHierarchy.getSubjectsFor(classLevel: premiere, series: series);
        final subjectIds = subjects.map((s) => s.id).toList();

        expect(subjectIds, isNot(contains('philosophie')),
            reason: 'Philosophie must NEVER appear in Première (series $series)');
      }
    });

    test('Terminale subjects include Philosophie for all valid series', () {
      final terminale = AcademicHierarchy.findByKey('terminale');
      expect(terminale, isNotNull);

      for (final series in ['A', 'C', 'D', 'TI']) {
        final subjects = AcademicHierarchy.getSubjectsFor(classLevel: terminale, series: series);
        final subjectIds = subjects.map((s) => s.id).toList();

        expect(subjectIds, contains('philosophie'),
            reason: 'Philosophie is mandatory in Terminale series $series');
      }
    });

    test('Anglophone Form 1 excludes Philosophy, Upper Sixth includes Philosophy', () {
      final form1 = AcademicHierarchy.findByKey('Form1');
      final upperSixth = AcademicHierarchy.findByKey('UpperSixth');

      expect(form1, isNotNull);
      expect(upperSixth, isNotNull);

      final f1Subjects = AcademicHierarchy.getSubjectsFor(classLevel: form1);
      expect(f1Subjects.map((s) => s.id), isNot(contains('philosophie')));

      final u6Subjects = AcademicHierarchy.getSubjectsFor(classLevel: upperSixth, series: 'Arts');
      expect(u6Subjects.map((s) => s.id), contains('philosophie'));
    });
  });

  group('AcademicContextNotifier Class-Aware Subject State Transitions', () {
    test('Switching class from Terminale to 6e resets invalid subject (Philosophie) to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(academicContextProvider.notifier);

      // Select Terminale -> Philosophie
      notifier.setClassById('Terminale');
      notifier.setSubjectById('philosophie');

      expect(container.read(academicContextProvider).subject?.id, 'philosophie');
      expect(container.read(academicContextProvider).isPublicationReady, isTrue);

      // Switch to 6e
      notifier.setClassById('6eme');

      final ctx = container.read(academicContextProvider);
      expect(ctx.selectedClass?.id, '6eme');
      expect(ctx.subject, isNull,
          reason: 'Philosophie is invalid for 6e and must be automatically reset to null');
      expect(ctx.isPublicationReady, isFalse,
          reason: 'Cannot publish without valid subject selection for 6e');
    });

    test('Switching class preserves subject if subject is valid in both classes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(academicContextProvider.notifier);

      // Select 3e -> Mathématiques
      notifier.setClassById('3eme');
      notifier.setSubjectById('maths');

      expect(container.read(academicContextProvider).subject?.id, 'maths');

      // Switch to 6e (Mathématiques is valid in 6e too)
      notifier.setClassById('6eme');

      expect(container.read(academicContextProvider).subject?.id, 'maths',
          reason: 'Maths is valid in both 3e and 6e, so it should be preserved');
    });

    test('Directly attempting to set invalid subject for a class is rejected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(academicContextProvider.notifier);

      // Select 6e
      notifier.setClassById('6eme');

      // Attempt to set Philosophie by ID
      notifier.setSubjectById('philosophie');
      expect(container.read(academicContextProvider).subject, isNull);

      // Attempt to set Philosophie directly
      const philo = CanonicalSubject(id: 'philosophie', name: 'Philosophie', iconName: 'psychology');
      notifier.setSubject(philo);
      expect(container.read(academicContextProvider).subject, isNull);
    });
  });

  group('Class Label UI Hygiene', () {
    test('Class labels display strictly clean designations without internal numeric orders', () {
      final francophone = AcademicHierarchy.francophoneClasses;
      final anglophone = AcademicHierarchy.anglophoneClasses;

      for (final c in [...francophone, ...anglophone]) {
        // Labels must NOT contain parentheses enclosing numbers like (10), (20)
        expect(c.label, isNot(matches(r'\(\d+\)')),
            reason: 'Class label "${c.label}" should not display internal order number');
      }

      expect(francophone.map((c) => c.label).toList(), [
        '6ème',
        '5ème',
        '4ème',
        '3ème',
        '2nde (Seconde)',
        '1ère (Première)',
        'Terminale',
      ]);
    });
  });
}
