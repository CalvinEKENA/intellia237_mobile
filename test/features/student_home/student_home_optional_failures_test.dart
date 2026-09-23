import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/network/network_status.dart';
import 'package:intellia237/features/ai_companion/application/ai_companion_controller.dart';
import 'package:intellia237/features/ai_companion/domain/tutor_turn_options.dart';
import 'package:intellia237/features/ai_companion/data/ai_repository.dart';
import 'package:intellia237/features/ai_companion/domain/ai_companion_reply.dart';
import 'package:intellia237/features/ai_companion/domain/ai_message.dart';
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
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';
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
    'companion live-service failure remains isolated from the core home',
    (tester) async {
      final repository = _FailingCompanionRepository();
      final container = await _pumpHome(
        tester,
        companionRepository: repository,
      );

      _expectCoreHome();
      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-3')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'Aide-moi');
      await tester.pump();
      // « Parler » devient « Envoyer » dès qu'un caractère utile est saisi.
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      expect(repository.calls, 1);
      expect(find.textContaining('cours et exercices'), findsOneWidget);

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
  AIRepository? companionRepository,
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
      if (companionRepository != null)
        aiRepositoryProvider.overrideWithValue(companionRepository),
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

class _FailingCompanionRepository implements AIRepository {
  int calls = 0;

  @override
  Future<AICompanionReply> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
    TutorTurnOptions options = const TutorTurnOptions(),
  }) async {
    calls += 1;
    throw AICompanionException(
      message:
          '${tutor.name} n’arrive pas à répondre pour le moment. '
          'Tu peux continuer à consulter tes cours et exercices.',
      kind: AICompanionFailureKind.serviceUnavailable,
      normalizedErrorCode: 'not-found',
      diagnosticId: 'TUTOR-SERVICE-505',
    );
  }
}

class _SeenTourRepository implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => true;

  @override
  Future<void> markTourSeen(String uid) async {}
}
