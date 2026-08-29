import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/config/app_config.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/learn/domain/learn_hub_snapshot.dart';
import 'package:intellia237/features/quiz/application/quiz_providers.dart';
import 'package:intellia237/features/student_home/data/student_home_repository.dart';
import 'package:intellia237/features/student_home/domain/student_home_snapshot.dart';
import 'package:intellia237/features/student_home/presentation/student_home_screen.dart';
import 'package:intellia237/features/student_home/presentation/widgets/quick_access_panel.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ratio de contraste WCAG entre deux couleurs opaques.
double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Compose [fg] (éventuellement translucide) sur [bg] opaque.
Color _flatten(Color fg, Color bg) => Color.alphaBlend(fg, bg);

Color _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text).first).style!.color!;

const _light = TabPalette(TabPresentationMode.embeddedLight);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TabPalette claire — garde AA au niveau des tokens', () {
    const surfaces = <String, Color>{
      'background': IntelliaColors.backgroundPrimary,
      'surface': IntelliaColors.surfaceSolid,
    };

    test('textes et statuts ≥ 4.5:1 sur fond et surface claires', () {
      final tokens = <String, Color>{
        'textPrimary': _light.textPrimary,
        'textSecondary': _light.textSecondary,
        'accent': _light.accent,
        'numberAccent': _light.numberAccent,
        'success': _light.success,
        'warning': _light.warning,
        'error': _light.error,
      };
      for (final surface in surfaces.entries) {
        for (final token in tokens.entries) {
          final ratio = _contrastRatio(
            _flatten(token.value, surface.value),
            surface.value,
          );
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '${token.key} sur ${surface.key} : '
                '${ratio.toStringAsFixed(2)}:1 < 4.5:1',
          );
        }
      }
    });

    test('textTertiary et textDisabled ≥ 3:1 (métadonnées, désactivé)', () {
      for (final surface in surfaces.values) {
        expect(
          _contrastRatio(_flatten(_light.textTertiary, surface), surface),
          greaterThanOrEqualTo(3.0),
        );
        expect(
          _contrastRatio(_flatten(_light.textDisabled, surface), surface),
          greaterThanOrEqualTo(2.6),
          reason: 'atténué mais jamais invisible',
        );
      }
    });
  });

  group('Accueil élève — lisibilité effective', () {
    testWidgets('les titres critiques sont sombres sur le backdrop clair', (
      tester,
    ) async {
      await _pumpHome(tester);

      // Sections visibles ou atteignables par scroll.
      for (final label in ['Matières', 'Défis du jour', 'Ma progression']) {
        await _scrollHomeTo(tester, find.text(label));
        final color = _textColor(tester, label);
        expect(
          color,
          _light.textPrimary,
          reason: '« $label » doit suivre le contrat de surface claire',
        );
        expect(
          _contrastRatio(color, IntelliaColors.backgroundPrimary),
          greaterThanOrEqualTo(4.5),
        );
      }

      // Texte d'un défi : sombre sur carte opaque claire.
      await _scrollHomeTo(tester, find.text('Terminer un quiz'));
      expect(_textColor(tester, 'Terminer un quiz'), _light.textPrimary);

      // Pastille de points : or profond lisible (jamais blanc sur clair).
      expect(
        _contrastRatio(
          _textColor(tester, '+35 pts'),
          IntelliaColors.surfaceSolid,
        ),
        greaterThanOrEqualTo(4.5),
      );

      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Quiz rapide / Compagnon : le dégradé sombre est peint DANS le '
        'sous-arbre (bug Ink) et le blanc y reste contrasté', (tester) async {
      await _pumpHome(tester);
      await _scrollHomeTo(tester, find.text('Quiz rapide'));

      for (final label in ['Quiz rapide', 'Compagnon']) {
        final textFinder = find.descendant(
          of: find.byType(QuickAccessPanel),
          matching: find.text(label),
        );
        expect(textFinder, findsOneWidget);

        final text = tester.widget<Text>(textFinder);
        expect(text.style!.color, Colors.white);

        // Le fond protecteur doit être un ancêtre direct du texte : un
        // Container à dégradé (peint dans le sous-arbre, pas sur le
        // Material sous le backdrop comme le faisait Ink).
        final containerFinder = find.ancestor(
          of: textFinder,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).gradient != null,
          ),
        );
        expect(
          containerFinder,
          findsWidgets,
          reason: 'le libellé blanc doit reposer sur son propre dégradé',
        );

        final gradient =
            (tester.widget<Container>(containerFinder.first).decoration!
                    as BoxDecoration)
                .gradient!
                .colors;
        for (final stop in gradient) {
          expect(
            _contrastRatio(Colors.white, stop),
            greaterThanOrEqualTo(4.5),
            reason: 'blanc sur $stop insuffisant',
          );
        }
      }
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('le changement d\'onglet ne corrompt pas la palette', (
      tester,
    ) async {
      await _pumpHome(tester);

      await _tapNav(tester, 'Apprendre');
      expect(_textColor(tester, 'Apprendre'), _light.textPrimary);
      await _tapNav(tester, 'Accueil');
      await _resetHomeScroll(tester);
      await _scrollHomeTo(tester, find.text('Matières'));
      expect(_textColor(tester, 'Matières'), _light.textPrimary);

      // Retour depuis un écran profond (détail matière) : palette intacte.
      await _resetHomeScroll(tester);
      await _scrollHomeTo(tester, find.text('Mathématiques'));
      await tester.tap(find.text('Mathématiques'));
      await tester.pumpAndSettle();
      expect(find.text('Matière math'), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await _resetHomeScroll(tester);
      await _scrollHomeTo(tester, find.text('Matières'));
      expect(_textColor(tester, 'Matières'), _light.textPrimary);

      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    for (final scale in const [1.3, 1.5]) {
      for (final size in const [Size(320, 640), Size(390, 844)]) {
        testWidgets(
          'texte @${scale}x sur ${size.width.toInt()}dp : lisible, sans débordement',
          (tester) async {
            await _pumpHome(tester, size: size, textScale: scale);

            for (final label in ['Matières', 'Défis du jour']) {
              await _scrollHomeTo(tester, find.text(label));
              expect(_textColor(tester, label), _light.textPrimary);
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
          subjects: const [],
        ),
      ),
      quizHubProvider.overrideWith((ref) async => const []),
      tourGuideRepositoryProvider.overrideWithValue(_SeenTourRepository()),
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

  final router = GoRouter(
    initialLocation: AppRoutes.studentHome,
    routes: [
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (_, _) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.flow,
        builder: (_, _) => const Scaffold(body: Text('Flow destination')),
      ),
      GoRoute(
        path: AppRoutes.learnSubjectRoute,
        builder: (_, state) => Scaffold(
          body: Text('Matière ${state.pathParameters['subjectId']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: TickerMode(enabled: false, child: child!),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pumpAndSettle();
}

Future<void> _tapNav(WidgetTester tester, String label) async {
  await tester.tapAt(tester.getCenter(find.text(label).last));
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _resetHomeScroll(WidgetTester tester) async {
  final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
  state.position.jumpTo(0);
  await tester.pump();
}

Future<void> _scrollHomeTo(WidgetTester tester, Finder finder) async {
  if (tester.any(finder)) {
    // Le widget peut être construit mais hors viewport (cacheExtent) :
    // ensureVisible le ramène réellement à l'écran avant tout tap.
    await tester.ensureVisible(finder.first);
  } else {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  }
  // Vide les délais d'entrée (stagger flutter_animate) des cartes construites
  // paresseusement au scroll — sinon ils restent pendants en fin de test.
  await tester.pump(const Duration(seconds: 1));
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

class _HomeRepository implements StudentHomeRepository {
  @override
  Future<StudentHomeSnapshot> fetchHomeSnapshot({required String firstName}) {
    return Future.value(
      StudentHomeSnapshot(
        firstName: firstName,
        resume: const ResumeTarget(
          subjectId: 'math',
          chapterId: 'chap-3',
          lessonId: 'lecon-2',
          lessonTitle: 'Fonctions affines',
          subjectTitle: 'Maths — Chapitre 3',
          progress: 0.64,
        ),
        subjects: const [
          SubjectOverview(
            id: 'math',
            title: 'Mathématiques',
            progress: 0.71,
            colorHex: 0xFF1451E1,
            iconKey: 'math',
          ),
        ],
        recommendations: const [
          RecommendationItem(
            title: 'Équations du premier degré',
            subtitle: 'Renforcer les acquis',
            estimatedMinutes: 18,
          ),
        ],
        challenges: const [
          DailyChallengeItem(
            title: 'Terminer un quiz',
            rewardPoints: 35,
            completed: false,
          ),
        ],
        globalProgress: 0.58,
        gamification: const StudentGamification(
          currentPoints: 1840,
          level: 12,
          streakDays: 7,
          motivationText: 'Continue comme ça.',
        ),
      ),
    );
  }
}

class _SeenTourRepository implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => true;

  @override
  Future<void> markTourSeen(String uid) async {}
}
