import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/student_home/presentation/student_home_screen.dart';
import 'package:intellia237/features/tutor/application/tutor_preference_provider.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('profile name and portrait always come from the same companion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpCard(tester, TutorPersona.resolve('leo'));

    expect(find.text('Léo'), findsOneWidget);
    expect(find.text('Kira'), findsNothing);
    expect(
      find.byKey(const ValueKey('student-profile-tutor-image-leo')),
      findsOneWidget,
    );

    // Rebuild the same stateful card to reproduce a profile companion change.
    await _pumpCard(tester, TutorPersona.resolve('kira'));

    expect(find.text('Kira'), findsOneWidget);
    expect(find.text('Léo'), findsNothing);
    expect(
      find.byKey(const ValueKey('student-profile-tutor-image-kira')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'authoritative profile restores companion with an empty device cache',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});

      Future<String?> resolveOnFreshDevice() async {
        final container = ProviderContainer(
          overrides: [
            studentAcademicContextProvider.overrideWith(
              (ref) async => const LearnAcademicContext(
                classLevel: '6eme',
                tutorId: 'leo',
              ),
            ),
          ],
        );
        await container.read(studentAcademicContextProvider.future);
        final tutor = container.read(selectedTutorProvider);
        container.dispose();
        return tutor?.id;
      }

      expect(await resolveOnFreshDevice(), 'leo');
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      expect(await resolveOnFreshDevice(), 'leo');
    },
  );
}

Future<void> _pumpCard(WidgetTester tester, TutorPersona tutor) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          textScaler: TextScaler.linear(1.5),
          disableAnimations: true,
        ),
        child: Scaffold(
          body: TabSurface(
            palette: const TabPalette(TabPresentationMode.embeddedLight),
            child: Center(
              child: SizedBox(
                width: 336,
                child: StudentProfileTutorCard(
                  key: const ValueKey('student-profile-tutor-card'),
                  tutor: tutor,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
