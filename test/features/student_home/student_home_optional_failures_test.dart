import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/network/network_status.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/learn/data/student_academic_profile_source.dart';
import 'package:intellia237/features/quiz/application/quiz_providers.dart';
import 'package:intellia237/features/quiz/data/quiz_diagnostic.dart';
import 'package:intellia237/features/student_home/data/student_home_repository.dart';
import 'package:intellia237/features/student_home/domain/student_home_snapshot.dart';
import 'package:intellia237/features/student_home/presentation/student_home_screen.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'quiz backend failure never prevents the core home from rendering',
    (tester) async {
      final container = await _pumpHome(
        tester,
        quizFailure: const QuizContentException(
          operation: QuizOperation.callableUnavailable,
          normalizedErrorCode: 'not-found',
          diagnosticId: 'QUIZ-CALLABLE-305',
        ),
      );

      _expectCoreHome();
      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-2')));
      // L'onglet se construit à sa première visite : sa réponse arrive à
      // l'image suivante.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Tes quiz arrivent'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-0')));
      await tester.pump();
      _expectCoreHome();
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();
    },
  );

  testWidgets(
    'academic profile failure stays inside Profile instead of UI-RENDER-500',
    (tester) async {
      final container = await _pumpHome(
        tester,
        academicFailure: const AcademicProfileException(
          kind: AcademicProfileFailureKind.missing,
          normalizedErrorCode: 'not-found',
          diagnosticId: 'ACADEMIC-PROFILE-201',
        ),
      );

      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-4')));
      await tester.pump();
      expect(find.text('Mon profil'), findsOneWidget);
      expect(find.text('Erreur de chargement'), findsOneWidget);
      expect(find.text('Un affichage n’a pas pu se charger.'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );

  testWidgets(
    'the companion answers on the device, and the core home stays intact',
    (tester) async {
      final container = await _pumpHome(tester);

      _expectCoreHome();
      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-3')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'Aide-moi');
      await tester.pump();
      // « Parler » devient « Envoyer » dès qu'un caractère utile est saisi.
      await tester.tap(find.byKey(const ValueKey('companion-send')));
      // La banque de dialogues est un asset local : aucun réseau.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byKey(const ValueKey('companion-reply-actions')),
        findsOneWidget,
      );
      expect(find.textContaining('cours et exercices'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-0')));
      await tester.pump();
      _expectCoreHome();
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();
    },
  );
}

void _expectCoreHome() {
  expect(find.text('Mon parcours'), findsOneWidget);
  expect(find.text('Tes cours arrivent'), findsOneWidget);
}

Future<ProviderContainer> _pumpHome(
  WidgetTester tester, {
  Object? quizFailure,
  Object? academicFailure,
}) async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      studentHomeRepositoryProvider.overrideWithValue(_CoreHomeRepository()),
      studentAcademicContextProvider.overrideWith((ref) async {
        if (academicFailure != null) throw academicFailure;
        return const LearnAcademicContext(
          classLevel: '6eme',
          catalogClassLevel: '6eme',
          academicLevelId: 'fr_general_6e',
          tutorId: 'kira',
        );
      }),
      quizHubProvider.overrideWith((ref) async {
        if (quizFailure != null) throw quizFailure;
        return const [];
      }),
      isOfflineProvider.overrideWithValue(false),
      tourGuideRepositoryProvider.overrideWithValue(_SeenTourRepository()),
    ],
  );
  container
      .read(authControllerProvider.notifier)
      .setAuthenticatedUser(
        role: AppRole.student,
        userId: 'student-home-resilience',
        email: 'amina@example.com',
        firstName: 'Amina',
      );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: StudentHomeScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return container;
}

class _CoreHomeRepository implements StudentHomeRepository {
  @override
  Future<StudentHomeSnapshot> fetchHomeSnapshot({required String firstName}) {
    return Future.value(StudentHomeSnapshot(firstName: firstName));
  }
}

class _SeenTourRepository implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => true;

  @override
  Future<void> markTourSeen(String uid) async {}
}
