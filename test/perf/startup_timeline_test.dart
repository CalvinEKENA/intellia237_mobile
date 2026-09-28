import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/app/config/app_config.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/core/network/network_status.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/subject_journey.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/data/learn_repository.dart';
import 'package:intellia237/features/learn/data/student_academic_profile_source.dart';
import 'package:intellia237/features/learn/domain/learn_subject.dart';
import 'package:intellia237/features/quiz/application/quiz_providers.dart';
import 'package:intellia237/features/quiz/data/quiz_repository.dart';
import 'package:intellia237/features/quiz/domain/quiz_attempt_summary.dart';
import 'package:intellia237/features/quiz/domain/quiz_model.dart';
import 'package:intellia237/features/student_home/data/student_home_repository.dart';
import 'package:intellia237/features/student_home/presentation/student_home_screen.dart';
import 'package:intellia237/features/student_home/presentation/widgets/student_home_skeleton.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/content_engine/pack_fixture.dart';

/// Chronologie du démarrage de l'espace élève, en temps simulé.
///
/// Les latences sont posées à la frontière des données (profil académique,
/// catalogue en ligne, quiz publiés) ; tout le reste est le code réel :
/// dépôt de l'Accueil, providers, onglets. Chaque scénario mesure, depuis
/// l'affichage de la coquille élève, le moment où chaque onglet devient
/// utile. Ce n'est pas une mesure d'appareil : elle isole les attentes que
/// le code impose, pas le coût du rendu.
const _td = ClassKey('terminale', series: 'd');

/// Un réseau : latence de chaque source, et échec éventuel.
class _Network {
  const _Network(
    this.name, {
    required this.profile,
    required this.catalogue,
    required this.quiz,
    this.offline = false,
    this.profileCached = false,
  });

  final String name;
  final Duration profile;
  final Duration catalogue;
  final Duration quiz;

  /// Le serveur ne répond pas : chaque source échoue après sa latence.
  final bool offline;

  /// L'appareil connaît déjà le profil (cache local de Firestore).
  final bool profileCached;
}

const _networks = [
  _Network(
    'rapide',
    profile: Duration(milliseconds: 300),
    catalogue: Duration(milliseconds: 400),
    quiz: Duration(milliseconds: 400),
  ),
  _Network(
    'lent',
    profile: Duration(seconds: 8),
    catalogue: Duration(seconds: 3),
    quiz: Duration(seconds: 3),
  ),
  _Network(
    'hors ligne',
    profile: Duration(seconds: 8),
    catalogue: Duration(seconds: 8),
    quiz: Duration(seconds: 8),
    offline: true,
  ),
  _Network(
    'lent, profil connu',
    profile: Duration(seconds: 8),
    catalogue: Duration(seconds: 3),
    quiz: Duration(seconds: 3),
    profileCached: true,
  ),
  _Network(
    'hors ligne, profil connu',
    profile: Duration(seconds: 8),
    catalogue: Duration(seconds: 8),
    quiz: Duration(seconds: 8),
    offline: true,
    profileCached: true,
  ),
];

/// Ce que l'élève voit d'utile dans chaque onglet.
final _useful = <String, bool Function()>{
  'Accueil': () => find
      .byKey(const ValueKey('student-home-sticky-header'))
      .evaluate()
      .isNotEmpty,
  'Apprendre': () => _anyKeyStartingWith('subject-card-'),
  'Quiz': () => _anyKeyStartingWith('pack-quiz-subject-'),
  'Compagnon': () => find.byType(TextField).evaluate().isNotEmpty,
};

const _navIndex = {'Accueil': 0, 'Apprendre': 1, 'Quiz': 2, 'Compagnon': 3};

bool _anyKeyStartingWith(String prefix) => find
    .byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(prefix),
    )
    .evaluate()
    .isNotEmpty;

class _ProfileSource implements StudentAcademicProfileSource {
  _ProfileSource(this.network);

  final _Network network;

  @override
  Future<Map<String, dynamic>> fetch(String uid) async {
    await Future<void>.delayed(network.profile);
    if (network.offline) {
      throw const AcademicProfileException(
        kind: AcademicProfileFailureKind.network,
        normalizedErrorCode: 'timeout',
        diagnosticId: 'ACADEMIC-NET-203',
      );
    }
    return _terminaleD;
  }
}

/// Même source, avec le dernier profil connu de l'appareil.
class _CachingProfileSource extends _ProfileSource
    implements CachedStudentAcademicProfileSource {
  _CachingProfileSource(super.network);

  @override
  Future<Map<String, dynamic>?> fetchCached(String uid) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return _terminaleD;
  }
}

const _terminaleD = <String, dynamic>{
  'classLevel': 'Terminale',
  'series': 'D',
  'firstName': 'Amina',
  'tutorId': 'kira',
};

class _LearnRepository extends Fake implements LearnRepository {
  _LearnRepository(this.network);

  final _Network network;

  @override
  Future<List<LearnSubject>> fetchSubjects({
    required String userId,
    required String classLevel,
    required String? series,
  }) async {
    await Future<void>.delayed(network.catalogue);
    if (network.offline) throw StateError('hors ligne');
    return const [];
  }
}

class _QuizRepository extends Fake implements QuizRepository {
  _QuizRepository(this.network);

  final _Network network;

  @override
  Future<List<QuizModel>> fetchQuizzes({
    required String classLevel,
    String? series,
  }) async {
    await Future<void>.delayed(network.quiz);
    if (network.offline) throw StateError('hors ligne');
    return const [];
  }

  @override
  Future<List<QuizAttemptSummary>> fetchRecentAttempts({
    required String studentId,
    int limit = 5,
  }) async => const [];
}

/// Firestore absent : les statistiques de l'Accueil (points, série)
/// échouent aussitôt, comme sans réseau ni cache.
class _NoFirestore extends Fake implements FirebaseFirestore {}

class _AuthRepository extends Fake implements AuthRepository {
  @override
  Future<AuthUserData?> getCurrentUser() async => null;

  @override
  Future<void> signOut() async {}
}

class _SeenTour implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => true;

  @override
  Future<void> markTourSeen(String uid) async {}
}

class _IdleSync extends ContentSyncController {
  @override
  Future<ContentSyncReport?> build() async => null;
}

/// Les parcours Terminale D, lus une fois sur disque (vrais packs).
Future<List<SubjectJourney>> _loadJourneys(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      contentPackRepositoryProvider.overrideWithValue(
        ContentPackRepository(source: DiskContentPackSource()),
      ),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      contentClassKeyProvider.overrideWith((ref) async => _td),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SizedBox()),
  );
  await settleSubjectJourneys(tester, container);
  final journeys = container.read(subjectJourneysProvider).requireValue;
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  return journeys;
}

/// Monte l'espace élève et renvoie, en millisecondes simulées depuis la
/// coquille, le moment où [tab] devient utile (null : pas dans le budget).
Future<int?> _measure(
  WidgetTester tester,
  _Network network,
  String tab,
  List<SubjectJourney> journeys, {
  List<Override> extra = const [],
}) async {
  await _pumpSpace(tester, network, journeys, extra: extra);
  return _followTab(tester, tab);
}

/// Monte l'espace élève sur [network] (coquille affichée, rien attendu).
Future<void> _pumpSpace(
  WidgetTester tester,
  _Network network,
  List<SubjectJourney> journeys, {
  List<Override> extra = const [],
}) async {
  SharedPreferences.setMockInitialValues(const {});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.staging),
      authRepositoryProvider.overrideWithValue(_AuthRepository()),
      studentAcademicProfileSourceProvider.overrideWithValue(
        network.profileCached
            ? _CachingProfileSource(network)
            : _ProfileSource(network),
      ),
      learnRepositoryProvider.overrideWithValue(_LearnRepository(network)),
      quizRepositoryProvider.overrideWithValue(_QuizRepository(network)),
      studentHomeRepositoryProvider.overrideWith(
        (ref) => FirestoreStudentHomeRepository(ref, firestore: _NoFirestore()),
      ),
      subjectJourneysProvider.overrideWith((ref) async {
        await ref.watch(contentClassKeyProvider.future);
        return journeys;
      }),
      contentSyncControllerProvider.overrideWith(_IdleSync.new),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      contentPackRepositoryProvider.overrideWithValue(
        ContentPackRepository(source: DiskContentPackSource()),
      ),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
      isOfflineProvider.overrideWithValue(network.offline),
      tourGuideRepositoryProvider.overrideWithValue(_SeenTour()),
      ...extra,
    ],
  );
  addTearDown(container.dispose);
  container
      .read(authControllerProvider.notifier)
      .setAuthenticatedUser(
        role: AppRole.student,
        userId: 'student-perf',
        email: 'amina@example.com',
        firstName: 'Amina',
      );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MediaQuery(
          data: MediaQueryData(size: Size(390, 844), disableAnimations: true),
          child: StudentHomeScreen(),
        ),
      ),
    ),
  );
  // La coquille (barre de navigation) est là dès la première image.
  expect(find.byKey(const ValueKey('bottom-nav-item-0')), findsOneWidget);
}

/// Ouvre [tab] tout de suite et renvoie quand il devient utile.
Future<int?> _followTab(WidgetTester tester, String tab) async {
  final index = _navIndex[tab]!;
  if (index != 0) {
    await tester.tap(find.byKey(ValueKey('bottom-nav-item-$index')));
  }
  const step = Duration(milliseconds: 100);
  int? usefulAt;
  for (var elapsed = 0; elapsed <= 15000; elapsed += step.inMilliseconds) {
    await tester.pump(elapsed == 0 ? Duration.zero : step);
    if (_useful[tab]!()) {
      usefulAt = elapsed;
      break;
    }
  }
  // Laisse s'écouler les attentes restantes avant le démontage.
  await tester.pump(const Duration(seconds: 20));
  await tester.pumpWidget(const SizedBox());
  return usefulAt;
}

/// Budgets (ms simulées depuis la coquille). Sans budget : l'onglet attend
/// légitimement la classe de l'élève (jamais lue sur cet appareil) ; il
/// montre alors sa structure (voir « structure pendant l'attente »).
const _budgets = <(String, String), int>{
  ('rapide', 'Accueil'): 500,
  ('rapide', 'Apprendre'): 1000,
  ('rapide', 'Quiz'): 1000,
  ('rapide', 'Compagnon'): 500,
  ('lent', 'Accueil'): 500,
  ('lent', 'Compagnon'): 500,
  ('hors ligne', 'Accueil'): 500,
  ('hors ligne', 'Compagnon'): 500,
  ('lent, profil connu', 'Accueil'): 500,
  ('lent, profil connu', 'Apprendre'): 500,
  ('lent, profil connu', 'Quiz'): 500,
  ('lent, profil connu', 'Compagnon'): 500,
  ('hors ligne, profil connu', 'Accueil'): 500,
  ('hors ligne, profil connu', 'Apprendre'): 500,
  ('hors ligne, profil connu', 'Quiz'): 500,
  ('hors ligne, profil connu', 'Compagnon'): 500,
};

/// La structure de l'onglet est visible (en-tête et emplacements, ou déjà
/// le contenu) : jamais une page vide.
void _expectStructure(String tab, String when) {
  final reason = '$tab $when';
  switch (tab) {
    case 'Accueil':
      // L'accueil immédiat, ou son squelette pendant ses premiers instants.
      expect(
        find
                .byKey(const ValueKey('student-home-sticky-header'))
                .evaluate()
                .isNotEmpty ||
            find.byType(StudentHomeSkeleton).evaluate().isNotEmpty,
        isTrue,
        reason: reason,
      );
    case 'Apprendre':
      expect(
        find.byKey(const ValueKey('learn-sticky-header')),
        findsOneWidget,
        reason: reason,
      );
      expect(
        _anyKeyStartingWith('subject-card-') ||
            find
                .byKey(const ValueKey('learn-hall-skeleton'))
                .evaluate()
                .isNotEmpty,
        isTrue,
        reason: reason,
      );
    case 'Quiz':
      expect(
        find.byKey(const ValueKey('quiz-sticky-header')),
        findsOneWidget,
        reason: reason,
      );
      expect(
        _useful['Quiz']!() ||
            find
                .byKey(const ValueKey('quiz-hub-loading'))
                .evaluate()
                .isNotEmpty,
        isTrue,
        reason: reason,
      );
    case 'Compagnon':
      expect(find.byType(TextField), findsOneWidget, reason: reason);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'réseau lent, profil jamais lu : chaque onglet montre sa structure '
    'pendant l\'attente, puis le contenu la remplace',
    (tester) async {
      final journeys = await _loadJourneys(tester);
      await _pumpSpace(tester, _networks[1], journeys);
      await tester.pump();
      for (final tab in ['Accueil', 'Apprendre', 'Quiz', 'Compagnon']) {
        await tester.tap(
          find.byKey(ValueKey('bottom-nav-item-${_navIndex[tab]}')),
        );
        await tester.pump();
        _expectStructure(tab, 'à 0 s');
      }
      // Pendant l'attente du profil (8 s) : toujours une structure.
      for (final second in [1, 3, 6]) {
        await tester.pump(const Duration(seconds: 1));
        for (final tab in ['Apprendre', 'Quiz']) {
          await tester.tap(
            find.byKey(ValueKey('bottom-nav-item-${_navIndex[tab]}')),
          );
          await tester.pump();
          _expectStructure(tab, 'vers $second s');
        }
      }
      // Le profil arrive (8 s) : le contenu remplace les emplacements.
      await tester.pump(const Duration(seconds: 6));
      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-1')));
      await tester.pump();
      expect(_anyKeyStartingWith('subject-card-'), isTrue);
      expect(find.byKey(const ValueKey('learn-hall-skeleton')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('bottom-nav-item-2')));
      await tester.pump();
      expect(_useful['Quiz']!(), isTrue);
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Accueil : les matières rejoignent l\'accueil déjà affiché', (
    tester,
  ) async {
    final journeys = await _loadJourneys(tester);
    // Profil connu, catalogue en ligne lent (3 s).
    await _pumpSpace(tester, _networks[3], journeys);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('student-home-sticky-header')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home-subjects-arriving')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('home-subjects-arriving')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(const ValueKey('home-subjects-arriving')), findsNothing);
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hors ligne, profil jamais lu : jamais de page vide', (
    tester,
  ) async {
    final journeys = await _loadJourneys(tester);
    await _pumpSpace(tester, _networks[2], journeys);
    for (final elapsed in [0, 2, 9]) {
      if (elapsed > 0) await tester.pump(Duration(seconds: elapsed));
      for (final tab in ['Accueil', 'Apprendre', 'Quiz', 'Compagnon']) {
        await tester.tap(
          find.byKey(ValueKey('bottom-nav-item-${_navIndex[tab]}')),
        );
        await tester.pump();
        expect(
          find.byType(Text).evaluate().length,
          greaterThan(3),
          reason: '$tab à $elapsed s',
        );
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpWidget(const SizedBox());
  });

  final results = <String, int?>{};
  tearDownAll(() {
    // ignore: avoid_print
    print('[PERF] ── chronologie (ms simulées depuis la coquille) ──');
    for (final entry in results.entries) {
      // ignore: avoid_print
      print('[PERF] ${entry.key} : ${entry.value ?? '> 15000'}');
    }
  });

  for (final network in _networks) {
    for (final tab in _navIndex.keys) {
      testWidgets('réseau ${network.name} — $tab', (tester) async {
        final journeys = await _loadJourneys(tester);
        final at = await _measure(tester, network, tab, journeys);
        results['réseau ${network.name} — $tab'] = at;
        final budget = _budgets[(network.name, tab)];
        if (budget != null) {
          expect(at, isNotNull, reason: '${network.name} $tab');
          expect(at, lessThanOrEqualTo(budget), reason: '${network.name} $tab');
        }
      });
    }
  }
}
