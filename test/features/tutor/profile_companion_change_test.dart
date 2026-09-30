import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_home/presentation/student_home_screen.dart';
import 'package:intellia237/features/tutor/application/tutor_preference_provider.dart';
import 'package:intellia237/features/tutor/data/tutor_preference_repository.dart';
import 'package:intellia237/features/tutor/presentation/tutor_selection_screen.dart';

import '../mastery/mastery_test_harness.dart';

/// Registre (QA appareil, 24/09/2026) : changer de compagnon depuis le profil
/// finissait sur « Un affichage n'a pas pu se charger », sans bouton retour.
/// L'enregistrement prend du temps sur un vrai réseau ; sans attente visible,
/// un second appui lançait un second enregistrement, et chacun fermait un
/// écran : le second fermait le profil lui-même.
class _SlowTutorRepository implements TutorPreferenceRepository {
  _SlowTutorRepository({this.fails = false});

  final bool fails;
  final saved = <String>[];

  @override
  Future<void> save({required String userId, required String tutorId}) async {
    saved.add(tutorId);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (fails) throw const TutorPreferenceException('permission-denied');
  }
}

Future<void> _openSelectionAndSwipe(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(StudentProfileTutorCard));
  await tester.pump();
  await tester.tap(find.byType(StudentProfileTutorCard));
  await _pumpFor(tester, 12);
  expect(find.byType(TutorSelectionScreen), findsOneWidget);
  await tester.drag(find.byType(PageView).first, const Offset(300, 0));
  await _pumpFor(tester, 8);
}

Future<void> _pumpFor(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final fails in [false, true]) {
    testWidgets(
      'a double tap while saving saves once and closes only the choice '
      '(save ${fails ? 'deferred' : 'confirmed'})',
      (tester) async {
        final repository = _SlowTutorRepository(fails: fails);
        final container = await pumpMasteryHarness(
          tester,
          companion: 'leo',
          tutorRepository: repository,
        );
        await _openSelectionAndSwipe(tester);

        final confirm = find.byKey(const ValueKey('tutor-confirm'));
        await tester.tap(confirm);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(confirm, warnIfMissed: false);
        await _pumpFor(tester, 40);

        expect(tester.takeException(), isNull);
        expect(repository.saved, ['kira']);
        expect(find.byType(TutorSelectionScreen), findsNothing);
        expect(find.byType(StudentProfileTutorCard), findsOneWidget);
        expect(container.read(selectedTutorIdProvider), 'kira');
      },
    );
  }

  testWidgets('the choice screen has a visible way back', (tester) async {
    await pumpMasteryHarness(
      tester,
      companion: 'leo',
      tutorRepository: _SlowTutorRepository(),
    );
    await _openSelectionAndSwipe(tester);
    await tester.tap(find.byKey(const ValueKey('tutor-selection-back')));
    await _pumpFor(tester, 20);
    expect(find.byType(TutorSelectionScreen), findsNothing);
    expect(find.byType(StudentProfileTutorCard), findsOneWidget);
  });
}
