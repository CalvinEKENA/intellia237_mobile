import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/student_home/application/personal_goal_providers.dart';
import 'package:intellia237/features/student_home/domain/personal_goal.dart';
import 'package:intellia237/features/student_home/domain/student_home_snapshot.dart';
import 'package:intellia237/features/student_home/presentation/widgets/weekly_goal_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _subjects = [
  SubjectOverview(
    id: 'math',
    title: 'Mathématiques',
    progress: 0.4,
    colorHex: 0xFF1451E1,
    iconKey: 'math',
  ),
];

class _FakeGoalController extends PersonalGoalController {
  _FakeGoalController(this._progress);

  final WeeklyGoalProgress _progress;

  @override
  Future<WeeklyGoalProgress> build() async => _progress;
}

class _AuthRepository implements AuthRepository {
  @override
  Future<AuthUserData?> getCurrentUser() async => null;

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();
}

Future<void> _pumpCard(
  WidgetTester tester, {
  WeeklyGoalProgress? fakeProgress,
  ProviderContainer? container,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = container != null
      ? UncontrolledProviderScope(container: container, child: _host())
      : ProviderScope(
          overrides: [
            personalGoalControllerProvider.overrideWith(
              () => _FakeGoalController(fakeProgress!),
            ),
          ],
          child: _host(),
        );

  await tester.pumpWidget(scope);
  await tester.pumpAndSettle();
}

Widget _host() {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(360, 800),
        textScaler: TextScaler.linear(1.5),
        disableAnimations: true,
      ),
      child: Scaffold(
        backgroundColor: IntelliaColors.backgroundPrimary,
        body: TabSurface(
          palette: const TabPalette(TabPresentationMode.embeddedLight),
          child: SingleChildScrollView(
            child: WeeklyGoalCard(subjects: _subjects, onOpenSubject: (_) {}),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sans objectif : invitation lisible, sans compteur factice', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      fakeProgress: const WeeklyGoalProgress(goal: null, activeDays: 0),
    );

    expect(find.text('Fixe ton rythme de la semaine'), findsOneWidget);
    final title = tester.widget<Text>(
      find.text('Fixe ton rythme de la semaine'),
    );
    expect(title.style!.color, IntelliaColors.textPrimary);
    expect(find.textContaining('séance'), findsOneWidget); // le sous-titre
    expect(find.textContaining('/'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avec objectif en cours : compteur honnête, ton neutre', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      fakeProgress: const WeeklyGoalProgress(
        goal: PersonalGoal(sessionsPerWeek: 3, minutesPerSession: 20),
        activeDays: 2,
      ),
    );

    expect(find.text('Mon objectif de la semaine'), findsOneWidget);
    expect(find.textContaining('2/3 séances'), findsOneWidget);
    // Jamais de culpabilisation.
    expect(find.textContaining('retard'), findsNothing);
    expect(find.textContaining('raté'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('objectif atteint : célébration sobre', (tester) async {
    await _pumpCard(
      tester,
      fakeProgress: const WeeklyGoalProgress(
        goal: PersonalGoal(
          sessionsPerWeek: 3,
          minutesPerSession: 20,
          prioritySubjectId: 'math',
          prioritySubjectTitle: 'Mathématiques',
        ),
        activeDays: 3,
      ),
    );

    expect(find.text('Objectif atteint — belle semaine !'), findsOneWidget);
    expect(find.textContaining('Priorité : Mathématiques'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'parcours réel : choisir un rythme depuis l\'invitation puis le voir',
    (tester) async {
      SharedPreferences.setMockInitialValues(const {});
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthRepository()),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(authControllerProvider.notifier)
          .setAuthenticatedUser(
            role: AppRole.student,
            userId: 'student-test',
            email: 'student@example.com',
            firstName: 'Amina',
          );

      await _pumpCard(tester, container: container);
      expect(find.text('Fixe ton rythme de la semaine'), findsOneWidget);

      // Ouvre la sheet, choisit 5 séances, enregistre.
      await tester.tap(find.text('Fixe ton rythme de la semaine'));
      await tester.pumpAndSettle();
      expect(find.text('Séances par semaine'), findsOneWidget);

      await tester.tap(find.text('5'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Enregistrer mon objectif'));
      await tester.pumpAndSettle();

      expect(find.textContaining('0/5 séances'), findsOneWidget);

      // La progression du jour se reflète immédiatement.
      await container
          .read(personalGoalControllerProvider.notifier)
          .recordActivityToday();
      await tester.pumpAndSettle();
      expect(find.textContaining('1/5 séances'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );
}
