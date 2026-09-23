import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/app/config/build_identity.dart';
import 'package:intellia237/app/theme/app_theme.dart';
import 'package:intellia237/core/widgets/intellia_bottom_nav_bar.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/learn/domain/learn_hub_snapshot.dart';
import 'package:intellia237/features/learn/domain/learn_subject.dart';
import 'package:intellia237/features/mastery/application/mastery_providers.dart';
import 'package:intellia237/features/mastery/data/mastery_repository.dart';
import 'package:intellia237/features/mastery/domain/mastery_policy.dart';
import 'package:intellia237/features/mastery/domain/quiz_evidence.dart';
import 'package:intellia237/features/parent/application/parent_providers.dart';
import 'package:intellia237/features/parent/domain/parent_child_profile.dart';
import 'package:intellia237/features/parent/domain/parent_dashboard.dart';
import 'package:intellia237/features/student_home/data/student_home_repository.dart';
import 'package:intellia237/features/student_home/domain/student_home_snapshot.dart';
import 'package:intellia237/features/student_home/presentation/student_home_screen.dart';
import 'package:intellia237/features/study_reserve/data/study_reserve_service.dart';
import 'package:intellia237/features/study_reserve/domain/study_reserve.dart';
import 'package:intellia237/features/tutor/application/tutor_preference_provider.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

final masteryNow = DateTime.utc(2026, 9, 5, 12);

LearnSubject subjectFixture({
  String language = 'fr',
  String id = 'math',
  bool explored = true,
}) => LearnSubject(
  id: id,
  title: id == 'math'
      ? (language == 'fr' ? 'Mathématiques' : 'Mathematics')
      : (language == 'fr' ? 'Histoire et géographie' : 'History and geography'),
  description: '',
  colorHex: 0xFF007AFF,
  iconKey: 'math',
  chapters: [
    for (var i = 0; i < 7; i++)
      LearnChapterSummary(
        id: 'chapter-$i',
        title: 'Chapter $i',
        description: '',
        lessonsCount: 3,
        completion: explored ? 1 : 0,
      ),
  ],
);

List<QuizEvidence> evidenceFixture({int score = 3, int count = 3}) => [
  for (var i = 0; i < count; i++)
    QuizEvidence(
      quizId: 'quiz-$i',
      subjectId: 'math',
      correctAnswers: score,
      questionCount: 5,
      recordedAt: masteryNow.subtract(Duration(days: i + 1)),
    ),
];

MasteryProfile profileFixture() =>
    MasterySession().update(evidenceFixture(), now: masteryNow);

const childFixture = ParentChildProfile(
  id: 'learner',
  firstName: 'Amina',
  classLevel: '6ème',
  series: null,
  globalProgress: 1,
  studyMinutesToday: 9876,
  studyMinutesTarget: 9999,
  strongSubjects: ['FAKE_STRENGTH_FROM_LESSONS'],
  weakSubjects: ['FAKE_WEAKNESS'],
  weeklyProgress: [0.8, 0.9, 1],
  hasProgressData: true,
  hasStudyTimeData: true,
  exploredLessonCount: 21,
);

class FixtureMasteryRepository implements MasteryRepository {
  FixtureMasteryRepository({this.failure = false, List<QuizEvidence>? records})
    : records = records ?? evidenceFixture();
  bool failure;
  final List<QuizEvidence> records;
  int calls = 0;
  @override
  Stream<List<QuizEvidence>> watchQuizEvidence(String learnerId) {
    calls++;
    return failure
        ? Stream.error(StateError('mastery unavailable'))
        : Stream.value(records);
  }
}

class FixtureHomeRepository implements StudentHomeRepository {
  @override
  Future<StudentHomeSnapshot> fetchHomeSnapshot({
    required String firstName,
  }) async => StudentHomeSnapshot(firstName: firstName);
}

class _SeenTourRepository implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => true;
  @override
  Future<void> markTourSeen(String uid) async {}
}

Future<ProviderContainer> pumpMasteryHarness(
  WidgetTester tester, {
  Widget content = const StudentProfileTab(),
  String language = 'fr',
  double width = 390,
  double textScale = 1,
  bool reduced = true,
  bool parent = false,
  String companion = 'leo',
  bool academicFailure = false,
  bool coverageFailure = false,
  bool companionFailure = false,
  bool schoolFailure = false,
  MasteryRepository? repository,
  GlobalKey? captureKey,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.runAsync(loadMasteryReviewFonts);
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final subjects = [
    subjectFixture(language: language),
    subjectFixture(language: language, id: 'history', explored: false),
  ];
  final container = ProviderContainer(
    overrides: [
      tourGuideRepositoryProvider.overrideWithValue(_SeenTourRepository()),
      masteryRepositoryProvider.overrideWithValue(
        repository ?? FixtureMasteryRepository(),
      ),
      masteryClockProvider.overrideWithValue(() => masteryNow),
      studentHomeRepositoryProvider.overrideWithValue(FixtureHomeRepository()),
      studentAcademicContextProvider.overrideWith((ref) async {
        if (academicFailure) throw StateError('academic unavailable');
        return LearnAcademicContext(
          classLevel: '6eme',
          displayClassLevel: '6ème',
          tutorId: companion,
        );
      }),
      learnHubProvider.overrideWith((ref) async {
        if (coverageFailure) throw StateError('coverage unavailable');
        return LearnHubSnapshot(
          context: const LearnAcademicContext(classLevel: '6eme'),
          subjects: subjects,
        );
      }),
      selectedTutorProvider.overrideWith((ref) {
        if (companionFailure) throw StateError('companion unavailable');
        return TutorPersona.resolve(companion);
      }),
      profileDeclaredEstablishmentProvider.overrideWith((ref) async {
        if (schoolFailure) throw StateError('school unavailable');
        return 'Collège de Yaoundé';
      }),
      parentDashboardProvider.overrideWith(
        (ref) async =>
            const ParentDashboard(children: [childFixture], announcements: []),
      ),
      parentMasterySubjectsProvider.overrideWith((ref, id) async => subjects),
      // Le profil élève embarque la Réserve d'étude : réponse serveur réelle
      // « unavailable » (aucun pourcentage), sans appel Firebase en test.
      studyReserveProvider.overrideWith(
        (ref, id) async => StudyReserve(
          studentId: id ?? 'learner',
          percentRemaining: 0,
          status: StudyReserveStatus.unavailable,
        ),
      ),
      buildIdentityProvider.overrideWith(
        (ref) async => const BuildIdentity(
          version: '3.0.0',
          buildNumber: '22',
          flavor: 'Review fixture',
          commit: '7521a94',
        ),
      ),
    ],
  );
  container
      .read(authControllerProvider.notifier)
      .setAuthenticatedUser(
        role: parent ? AppRole.parent : AppRole.student,
        userId: parent ? 'parent-viewer' : 'learner',
        firstName: 'Amina',
        email: 'fixture@example.test',
      );

  final app = _OwnedTestContainer(
    key: ObjectKey(container),
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduced,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: TabSurface(
          palette: const TabPalette(TabPresentationMode.embeddedLight),
          child: content,
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    captureKey == null ? app : RepaintBoundary(key: captureKey, child: app),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  return container;
}

bool _reviewFontsLoaded = false;

/// Widget tests default to Ahem. Use the repository's real font assets for
/// responsive checks and captures, without network or platform font lookup.
/// Noms officiels des fichiers, ceux que google_fonts sait trouver.
const _weightName = {
  400: 'Regular',
  500: 'Medium',
  600: 'SemiBold',
  700: 'Bold',
  800: 'ExtraBold',
  900: 'Black',
};

Future<void> loadMasteryReviewFonts() async {
  if (_reviewFontsLoaded) return;
  final icons = FontLoader('MaterialIcons');
  icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  for (final (family, weights) in [
    ('Montserrat', [400, 500, 600, 700, 800, 900]),
    ('Manrope', [400, 600, 700, 800]),
    ('PlayfairDisplay', [400, 600, 700]),
  ]) {
    for (final weight in weights) {
      final loader = FontLoader(
        '${family}_${weight == 400 ? 'regular' : weight}',
      );
      loader.addFont(
        rootBundle.load('assets/fonts/$family-${_weightName[weight]}.ttf'),
      );
      await loader.load();
    }
    final fallback = FontLoader(family);
    fallback.addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'));
    await fallback.load();
  }
  _reviewFontsLoaded = true;
}

class _OwnedTestContainer extends StatefulWidget {
  const _OwnedTestContainer({
    required this.container,
    required this.child,
    super.key,
  });
  final ProviderContainer container;
  final Widget child;
  @override
  State<_OwnedTestContainer> createState() => _OwnedTestContainerState();
}

class _OwnedTestContainerState extends State<_OwnedTestContainer> {
  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
    container: widget.container,
    child: widget.child,
  );
  @override
  void dispose() {
    widget.container.dispose();
    super.dispose();
  }
}

Future<void> inspectWholeScroll(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  void inspectText() {
    for (final element in find.byType(Text).evaluate()) {
      // The shared navigation has its own one-line visual labels and full
      // Semantics labels. Its typography/motion is outside the mastery scope;
      // this assertion covers the page content, including its app bar.
      var inSharedNavigation = false;
      element.visitAncestorElements((ancestor) {
        inSharedNavigation = ancestor.widget is IntelliaBottomNavBar;
        return !inSharedNavigation;
      });
      if (inSharedNavigation) continue;
      final paragraph = element.renderObject;
      if (paragraph is RenderParagraph && paragraph.hasSize) {
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: (element.widget as Text).data,
        );
      }
    }
  }

  inspectText();
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 40; i++) {
    final position = tester.state<ScrollableState>(scrollable).position;
    if (position.pixels >= position.maxScrollExtent) break;
    await tester.drag(scrollable, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('%'), findsNothing);
    inspectText();
  }
}
