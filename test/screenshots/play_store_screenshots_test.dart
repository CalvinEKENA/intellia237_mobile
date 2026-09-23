@Tags(['screenshots'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/app/config/app_config.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/app/theme/app_theme.dart';
import 'package:intellia237/features/ai_companion/data/companion_history_repository.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_experience_scaffold.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/data/flow_points_gateway.dart';
import 'package:intellia237/features/flow/presentation/flow_screen.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/curriculum_catalog.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/learn/domain/learn_hub_snapshot.dart';
import 'package:intellia237/features/learn/domain/learn_subject.dart';
import 'package:intellia237/features/mastery/application/mastery_providers.dart';
import 'package:intellia237/features/mastery/data/mastery_repository.dart';
import 'package:intellia237/features/mastery/domain/quiz_evidence.dart';
import 'package:intellia237/features/quiz/application/quiz_providers.dart';
import 'package:intellia237/features/quiz/domain/quiz_model.dart';
import 'package:intellia237/features/student_home/data/student_home_repository.dart';
import 'package:intellia237/features/student_home/domain/student_home_snapshot.dart';
import 'package:intellia237/features/student_home/presentation/student_home_screen.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/presentation/widgets/companion_discovery.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captures destinées à la fiche Google Play.
///
/// Elles sortent de l'**écran de production** — `StudentHomeScreen` et ses
/// onglets réels, le vrai routeur, le thème `AppTheme.light`, les polices du
/// projet — peint par le moteur Flutter. Les données proviennent de fixtures
/// explicites : aucun compte réel, aucune donnée privée.
///
/// Le format est celui d'un téléphone 1080×1920 : 360×640 en unités logiques à
/// une densité de 3, configuration très répandue sur le marché visé.
///
/// Inerte par défaut. Pour produire les fichiers :
///   flutter test test/screenshots/play_store_screenshots_test.dart \
///     --dart-define=INTELLIA_PLAY_SHOTS=true
const _enabled = bool.fromEnvironment('INTELLIA_PLAY_SHOTS');

const _outDir = r'C:\projets\FlutterProjects\Intellia237_artifacts\play-store';

/// 1080×1920 exactement : 405×720 en unités logiques à une densité de 8/3.
///
/// 360×640 tenait aussi le format, mais 640 points de haut serrent l'écran de
/// découverte des compagnons au point de rogner « Découvrir Léo ».
const _logical = Size(405, 720);
const _density = 8 / 3;

Future<void> _loadFonts() async {
  // `google_fonts` ne demande pas « Montserrat » mais « Montserrat_regular »,
  // « Montserrat_700 »… Enregistrer la famille nue ne suffit donc pas : le
  // moteur dessinerait des rectangles à la place de chaque texte.
  GoogleFonts.config.allowRuntimeFetching = false;
  const weights = <String, String>{
    '400': 'regular',
    '500': '500',
    '600': '600',
    '700': '700',
    '800': '800',
    '900': '900',
  };
  const families = <String, String>{
    'Manrope': 'Manrope',
    'Montserrat': 'Montserrat',
    'PlayfairDisplay': 'PlayfairDisplay',
  };

  for (final family in families.entries) {
    // Toutes les graisses ne sont pas fournies pour chaque famille. Un poids
    // manquant doit retomber sur le fichier disponible le plus proche, sinon
    // le moteur dessine des rectangles pour ce seul niveau de titre.
    final available = <String, ByteData>{};
    for (final weight in weights.keys) {
      final file = File('assets/fonts/${family.value}-$weight.ttf');
      if (file.existsSync()) {
        available[weight] = ByteData.sublistView(await file.readAsBytes());
      }
    }
    if (available.isEmpty) continue;

    ByteData nearest(String weight) {
      final target = int.parse(weight);
      final keys = available.keys.map(int.parse).toList()..sort();
      var best = keys.first;
      for (final candidate in keys) {
        if ((candidate - target).abs() < (best - target).abs()) {
          best = candidate;
        }
      }
      return available['$best']!;
    }

    for (final weight in weights.entries) {
      final bytes = nearest(weight.key);
      // La famille nue sert aux styles écrits à la main dans le produit ;
      // la variante suffixée sert à google_fonts.
      final names = <String>{
        if (weight.key == '400') family.key,
        '${family.key}_${weight.value}',
      };
      for (final name in names) {
        final loader = FontLoader(name)..addFont(Future.value(bytes));
        await loader.load();
      }
    }
  }

  // Certains styles du produit laissent `fontFamily` nul et s'en remettent à
  // la police système — ce qui est correct sur un téléphone. Le moteur de test
  // y substitue une police dont chaque glyphe est un rectangle plein. On lui
  // donne donc une vraie police par défaut, sinon les libellés de navigation
  // apparaîtraient en barres alors qu'ils sont parfaitement lisibles sur
  // l'appareil.
  final fallback = ByteData.sublistView(
    await File('assets/fonts/Montserrat-Medium.ttf').readAsBytes(),
  );
  for (final name in const ['FlutterTest', 'Ahem', 'Roboto', 'sans-serif']) {
    final loader = FontLoader(name)..addFont(Future.value(fallback));
    await loader.load();
  }

  const iconFont =
      r'C:\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf';
  if (File(iconFont).existsSync()) {
    final icons = FontLoader('MaterialIcons')
      ..addFont(File(iconFont).readAsBytes().then(ByteData.sublistView));
    await icons.load();
  }
}

void main() {
  if (!_enabled) {
    test('captures Play désactivées (INTELLIA_PLAY_SHOTS)', () {
      expect(_enabled, isFalse);
    });
    return;
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
    Directory(_outDir).createSync(recursive: true);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    debugShowNavTapCounter = false;
  });

  tearDown(() => debugShowNavTapCounter = kDebugMode);

  /// Peint la frontière et écrit le PNG.
  Future<void> shoot(WidgetTester tester, String name) async {
    final boundary =
        tester.firstRenderObject(find.byKey(_captureKey))
            as RenderRepaintBoundary;
    // Le décodage des visuels et l'encodage PNG demandent du temps réel.
    late ui.Image image;
    await tester.runAsync(() async {
      image = await boundary.toImage(pixelRatio: _density);
    });
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    image.dispose();
    File('$_outDir/$name').writeAsBytesSync(bytes!.buffer.asUint8List());

    // Les entrées en fondu programment des minuteries ; on démonte l'arbre et
    // on les laisse expirer, sinon la vérification de fin de test échoue.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> settle(WidgetTester tester, {int steps = 8}) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    // Laisse les images d'assets se décoder avant la peinture.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    // Les entrées en fondu durent quelques centaines de millisecondes et
    // sont décalées entre elles : on avance par paliers plutôt que par
    // `pumpAndSettle`, qui n'aboutirait pas sur les animations en boucle.
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  // ── Écrans hors coquille d'onglets ─────────────────────────────────────

  testWidgets('03 choix du compagnon', (tester) async {
    await _pumpBare(
      tester,
      const Scaffold(
        backgroundColor: AuthExperienceColors.canvas,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SingleChildScrollView(child: CompanionDiscovery()),
          ),
        ),
      ),
    );
    await settle(tester);
    await shoot(tester, '03_companion_choice.png');
  });

  testWidgets('05 Flow', (tester) async {
    await _pumpBare(
      tester,
      const FlowScreen(),
      overrides: [flowPointsGatewayProvider.overrideWithValue(_InertGateway())],
      withRouter: true,
    );
    // Flow valide la carte de contenu affichée au bout de 1,2 s. On peint
    // avant ce délai, sinon la capture porte une notification de
    // synchronisation qui n'a rien à faire sur une fiche de magasin.
    await settle(tester, steps: 3);
    await shoot(tester, '05_flow.png');
  });

  // ── Onglets réels de la coquille élève ─────────────────────────────────

  testWidgets('01 accueil', (tester) async {
    await _pumpShell(tester);
    await settle(tester);
    await shoot(tester, '01_home.png');
  });

  testWidgets('02 apprendre', (tester) async {
    await _pumpShell(tester);
    await _selectTab(tester, 1);
    await settle(tester);
    await shoot(tester, '02_learn.png');
  });

  testWidgets('06 quiz', (tester) async {
    await _pumpShell(tester);
    await _selectTab(tester, 2);
    await settle(tester);
    await shoot(tester, '06_quiz.png');
  });

  testWidgets('04 chat compagnon', (tester) async {
    await _pumpShell(tester, seedConversation: true);
    await _selectTab(tester, 3);
    await settle(tester);
    await shoot(tester, '04_companion_chat.png');
  });

  testWidgets('07 profil Encre & Tracé', (tester) async {
    await _pumpShell(tester);
    await _selectTab(tester, 4);
    await settle(tester);
    await shoot(tester, '07_mastery.png');
  });
}

const _captureKey = ValueKey('play-capture');

void _sizeView(WidgetTester tester) {
  tester.view.physicalSize = Size(
    _logical.width * _density,
    _logical.height * _density,
  );
  tester.view.devicePixelRatio = _density;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _frame(Widget child) => RepaintBoundary(key: _captureKey, child: child);

Future<void> _pumpBare(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  bool withRouter = false,
}) async {
  _sizeView(tester);
  final app = withRouter
      ? MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: _delegates,
          supportedLocales: _locales,
          locale: const Locale('fr'),
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [GoRoute(path: '/', builder: (_, _) => screen)],
          ),
          builder: (context, child) => _chrome(context, child),
        )
      : MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: _delegates,
          supportedLocales: _locales,
          locale: const Locale('fr'),
          home: screen,
          builder: (context, child) => _chrome(context, child),
        );

  await tester.pumpWidget(ProviderScope(overrides: overrides, child: app));
}

/// Gèle les animations et enveloppe l'arbre dans la frontière de capture.
/// Enveloppe l'arbre dans la frontière de capture.
///
/// Les tickers restent actifs : les cartes d'accueil entrent par un
/// `TweenAnimationBuilder` qui démarre à une opacité nulle. Les figer
/// donnerait une capture vide. On laisse donc le temps avancer, puis on
/// stabilise avant de peindre.
Widget _chrome(BuildContext context, Widget? child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(disableAnimations: true),
  child: _frame(child!),
);

const _delegates = <LocalizationsDelegate<Object>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const _locales = <Locale>[Locale('fr'), Locale('en')];

Future<void> _selectTab(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(ValueKey('bottom-nav-item-$index')));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Monte la coquille élève de production avec des données de démonstration.
Future<void> _pumpShell(
  WidgetTester tester, {
  bool seedConversation = false,
  List<Override> overrides = const [],
}) async {
  _sizeView(tester);
  // Le stockage doit être garni avant que le dépôt ne le lise.
  if (seedConversation) {
    await _seedConversation();
  } else {
    SharedPreferences.setMockInitialValues(const {'selected_tutor_id': 'kira'});
  }

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.staging),
      authRepositoryProvider.overrideWithValue(_AuthRepository()),
      studentHomeRepositoryProvider.overrideWithValue(_HomeRepository()),
      studentAcademicContextProvider.overrideWith(
        (ref) async =>
            const LearnAcademicContext(classLevel: 'Terminale', series: 'D'),
      ),
      learnHubProvider.overrideWith(
        (ref) async => LearnHubSnapshot(
          context: const LearnAcademicContext(
            classLevel: 'Terminale',
            series: 'D',
          ),
          subjects: _subjects,
        ),
      ),
      quizHubProvider.overrideWith((ref) async => _quizzes),
      masteryRepositoryProvider.overrideWithValue(_MasteryRepository()),
      flowPointsGatewayProvider.overrideWithValue(_InertGateway()),
      tourGuideRepositoryProvider.overrideWithValue(_SeenTourRepository()),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  container
      .read(authControllerProvider.notifier)
      .setAuthenticatedUser(
        role: AppRole.student,
        userId: 'demo-eleve',
        email: 'demo@intellia237.cm',
        firstName: 'Amina',
      );

  final router = GoRouter(
    initialLocation: AppRoutes.studentHome,
    routes: [
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (_, _) => const StudentHomeScreen(),
      ),
      GoRoute(path: AppRoutes.flow, builder: (_, _) => const FlowScreen()),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: _delegates,
        supportedLocales: _locales,
        locale: const Locale('fr'),
        routerConfig: router,
        builder: (context, child) => _chrome(context, child),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

/// Écrit une conversation de démonstration dans le stockage local, avec les
/// clés réelles, pour que le compagnon la restaure par son propre chemin.
Future<void> _seedConversation() async {
  const learnerId = 'demo-eleve';
  final scope = CompanionHistoryRepository.scopeOf(learnerId)!;
  final createdAt = DateTime(2026, 9, 6, 14, 30);
  final answer = <String>[
    '### Le discriminant',
    'Pour une équation **ax² + bx + c = 0**, on calcule Δ = b² − 4ac.',
    '',
    '- Si Δ > 0, il y a *deux* solutions distinctes.',
    '- Si Δ = 0, il y a une solution double.',
    '- Si Δ < 0, il n’y a pas de solution réelle.',
    '',
    '1. Repère a, b et c.',
    '2. Calcule Δ.',
    '3. Conclus selon son signe.',
    '',
    '> Le signe de Δ décide de tout.',
  ].join('\n');
  final messages = <Map<String, Object?>>[
    {
      'id': 'u1',
      'role': 'user',
      'text': 'Explique-moi le discriminant.',
      'createdAt': createdAt.toIso8601String(),
    },
    {
      'id': 'a1',
      'role': 'assistant',
      'companionId': 'kira',
      'text': answer,
      'createdAt': createdAt.add(const Duration(minutes: 1)).toIso8601String(),
    },
  ];
  SharedPreferences.setMockInitialValues({
    'selected_tutor_id': 'kira',
    'intellia_companion_thread_v1_${scope}_c1': jsonEncode(messages),
    'intellia_companion_index_v1_$scope': jsonEncode([
      {
        'id': 'c1',
        'learnerId': learnerId,
        'createdAt': createdAt.toIso8601String(),
        'lastActivityAt': createdAt
            .add(const Duration(minutes: 1))
            .toIso8601String(),
        'title': 'Explique-moi le discriminant.',
        'preview': 'Le signe de Δ décide de tout.',
        'companionId': 'kira',
      },
    ]),
  });
}
// ── Fixtures ─────────────────────────────────────────────────────────────

final _subjects = <LearnSubject>[
  for (final subject in CurriculumCatalog.forLevel(
    schoolClass: SchoolClass.terminale,
    series: SchoolSeries.d,
  ).take(8))
    LearnSubject(
      id: subject.id,
      title: subject.frenchLabel,
      description: 'Programme officiel · Terminale D',
      colorHex: subject.colorHex,
      iconKey: subject.iconKey,
      chapters: const [],
    ),
];

final _quizzes = <QuizModel>[
  const QuizModel(
    id: 'q-maths',
    title: 'Équations du second degré',
    subjectId: 'maths',
    subjectLabel: 'Mathématiques',
    description: 'Discriminant, racines et factorisation',
    difficultyLabel: 'Intermédiaire',
    questions: [],
    questionCount: 12,
  ),
  const QuizModel(
    id: 'q-svt',
    title: 'Génétique mendélienne',
    subjectId: 'svteehb',
    subjectLabel: 'SVTEEHB',
    description: 'Croisements et lois de Mendel',
    difficultyLabel: 'Débutant',
    questions: [],
    questionCount: 10,
  ),
  const QuizModel(
    id: 'q-pc',
    title: 'Cinématique du point',
    subjectId: 'physique',
    subjectLabel: 'Physique',
    description: 'Vitesse, accélération et trajectoires',
    difficultyLabel: 'Avancé',
    questions: [],
    questionCount: 15,
  ),
];

class _HomeRepository implements StudentHomeRepository {
  @override
  Future<StudentHomeSnapshot> fetchHomeSnapshot({required String firstName}) {
    // Première séance honnête : aucune reprise, aucune série inventée.
    return Future.value(
      StudentHomeSnapshot(firstName: firstName, subjects: _overviews),
    );
  }

  static final _overviews = <SubjectOverview>[
    for (final subject in _subjects.take(6))
      SubjectOverview(
        id: subject.id,
        title: subject.title,
        progress: 0,
        colorHex: subject.colorHex,
        iconKey: subject.iconKey,
      ),
  ];
}

class _MasteryRepository implements MasteryRepository {
  @override
  Stream<List<QuizEvidence>> watchQuizEvidence(String learnerId) =>
      Stream.value([
        QuizEvidence(
          quizId: 'q-maths-1',
          subjectId: 'maths',
          correctAnswers: 8,
          questionCount: 12,
          recordedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        QuizEvidence(
          quizId: 'q-svt-1',
          subjectId: 'svteehb',
          correctAnswers: 7,
          questionCount: 10,
          recordedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ]);
}

class _InertGateway implements FlowPointsGateway {
  var _n = 0;

  @override
  String newClientEventId() => 'shot_${++_n}_abcdefgh';

  @override
  Future<FlowPointsResult> submit(FlowActivityCommand command) async =>
      FlowPointsResult(
        clientEventId: command.clientEventId,
        cardId: command.cardId,
        correct: true,
        pointsAwarded: 0,
        totalPoints: 0,
        alreadyCompleted: true,
        dailyCapReached: false,
        idempotentReplay: true,
      );

  @override
  Future<List<FlowPointsResult>> flushPending() async => const [];

  @override
  Future<int> pendingCount() async => 0;
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

class _SeenTourRepository implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => true;

  @override
  Future<void> markTourSeen(String uid) async {}
}
