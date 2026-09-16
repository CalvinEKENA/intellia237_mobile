import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/network/network_status.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/quiz/application/quiz_providers.dart';
import 'package:intellia237/features/quiz/domain/quiz_attempt_summary.dart';
import 'package:intellia237/features/quiz/domain/quiz_mode.dart';
import 'package:intellia237/features/quiz/domain/quiz_model.dart';
import 'package:intellia237/features/quiz/presentation/quiz_hub_screen.dart';
import 'package:intellia237/features/quiz/presentation/quiz_play_screen.dart';

const _quizzes = [
  QuizModel(
    id: 'training-quiz',
    title: 'Révision guidée',
    subjectId: 'maths',
    subjectLabel: 'Mathématiques',
    description: 'Consolider les fonctions.',
    difficultyLabel: 'Intermédiaire',
    questions: [],
    questionCount: 8,
    mode: QuizMode.training,
  ),
  QuizModel(
    id: 'exam-quiz',
    title: 'Examen blanc scientifique',
    subjectId: 'physics',
    subjectLabel: 'Physique',
    description: 'Faire le point avant l’épreuve.',
    difficultyLabel: 'Avancé',
    questions: [],
    questionCount: 10,
    timerSeconds: 1200,
    mode: QuizMode.exam,
  ),
];

Future<void> _pumpHub(
  WidgetTester tester, {
  bool offline = false,
  List<QuizAttemptSummary> history = const [],
}) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        quizHubProvider.overrideWith((ref) async => _quizzes),
        quizAttemptHistoryProvider.overrideWith((ref) async => history),
        isOfflineProvider.overrideWithValue(offline),
      ],
      child: MaterialApp(
        home: Scaffold(
          backgroundColor: IntelliaColors.backgroundPrimary,
          body: TabSurface(
            palette: const TabPalette(TabPresentationMode.embeddedLight),
            child: const QuizHubScreen(embedded: true),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sépare et filtre entraînements et examens blancs', (
    tester,
  ) async {
    await _pumpHub(tester);

    expect(find.text('S’entraîner'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FilterChip, 'Évaluation / examen blanc'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Révision guidée'), findsNothing);
    expect(find.text('Examen blanc scientifique'), findsOneWidget);
    expect(find.text('S’évaluer'), findsOneWidget);
    expect(
      find.textContaining('sans remplacer un examen officiel'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Entraînement'));
    await tester.pumpAndSettle();

    expect(find.text('Révision guidée'), findsOneWidget);
    expect(find.text('Examen blanc scientifique'), findsNothing);
    expect(find.text('S’entraîner'), findsOneWidget);
  });

  testWidgets('annonce chaque carte avec son mode et son volume', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpHub(tester);

    await tester.tap(
      find.widgetWithText(FilterChip, 'Évaluation / examen blanc'),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        RegExp(
          r'Évaluation / examen blanc.*Examen blanc scientifique.*10 questions',
        ),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('bloque le démarrage hors ligne et explique les alternatives', (
    tester,
  ) async {
    await _pumpHub(tester, offline: true);

    expect(find.text('Quiz en pause hors connexion'), findsOneWidget);
    expect(find.text('Ouvrir mon parcours hors ligne'), findsOneWidget);
    expect(find.text('Voir mes leçons téléchargées'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Révision guidée'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Révision guidée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Révision guidée'));
    await tester.pumpAndSettle();

    expect(find.text('Ce quiz a besoin du réseau'), findsOneWidget);
    expect(find.textContaining('ne met ni tes réponses'), findsOneWidget);
  });

  testWidgets('le jeu hors ligne ne demande même pas le contenu au serveur', (
    tester,
  ) async {
    var contentRequested = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOfflineProvider.overrideWithValue(true),
          quizByIdProvider.overrideWith((ref, quizId) async {
            contentRequested = true;
            return _quizzes.first;
          }),
        ],
        child: const MaterialApp(home: QuizPlayScreen(quizId: 'quiz-id')),
      ),
    );
    await tester.pumpAndSettle();

    expect(contentRequested, isFalse);
    expect(find.text('Quiz indisponible hors connexion'), findsOneWidget);
    expect(find.textContaining('ne conserve ni tes réponses'), findsOneWidget);
  });

  testWidgets('affiche uniquement les tentatives réelles et un mode honnête', (
    tester,
  ) async {
    await _pumpHub(
      tester,
      history: [
        QuizAttemptSummary(
          quizId: 'training-quiz',
          quizTitle: 'Révision guidée',
          subjectLabel: 'Mathématiques',
          score: 7,
          maxScore: 10,
          pointsAwarded: 30,
          submittedAt: DateTime(2026, 7, 16),
        ),
        QuizAttemptSummary(
          quizId: 'legacy-quiz',
          quizTitle: 'Ancienne tentative',
          subjectLabel: 'Physique',
          score: 4,
          maxScore: 5,
          pointsAwarded: 0,
          submittedAt: null,
        ),
      ],
    );

    await tester.tap(find.text('Mes résultats'));
    await tester.pumpAndSettle();

    expect(find.textContaining('7/10 (70 %)'), findsWidgets);
    expect(find.textContaining('Entraînement'), findsWidgets);
    expect(find.textContaining('Mode non précisé'), findsOneWidget);
    expect(find.text('Date non disponible'), findsOneWidget);
    expect(
      find.textContaining('compétences pédagogiques validées'),
      findsOneWidget,
    );
  });

  testWidgets('explique honnêtement l’absence de résultats', (tester) async {
    await _pumpHub(tester);

    await tester.tap(find.text('Mes résultats'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aucun résultat inventé ici'), findsOneWidget);
  });
}
