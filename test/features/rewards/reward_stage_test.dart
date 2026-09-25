import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/profile/application/user_preferences_controller.dart';
import 'package:intellia237/features/rewards/application/reward_providers.dart';
import 'package:intellia237/features/rewards/domain/haptic_pattern.dart';
import 'package:intellia237/features/rewards/domain/reward_engine.dart';
import 'package:intellia237/features/rewards/domain/reward_event.dart';
import 'package:intellia237/features/rewards/domain/reward_pattern.dart';
import 'package:intellia237/features/rewards/presentation/reward_stage.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Student extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    role: AppRole.student,
    userId: 'eleve-s',
    firstName: 'Awa',
  );
}

const _hard = RewardEvent.correct(
  source: RewardSource.practice,
  difficulty: 3,
  maxDifficulty: 3,
  responseTime: Duration(seconds: 30),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = false,
  Size size = const Size(390, 800),
  double textScale = 1,
  Locale locale = const Locale('fr'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(_Student.new)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: app!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
}

Widget _card(RewardPattern? pattern) => Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RewardStage(
        pattern: pattern,
        child: const SizedBox(
          height: 160,
          child: ColoredBox(color: Colors.white),
        ),
      ),
      RewardMessageLine(pattern: pattern),
    ],
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('animation courte, puis plus rien ne tourne', (tester) async {
    final pattern = RewardEngine().onCorrect(_hard);
    await _pump(tester, _card(pattern));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(pattern.duration + const Duration(milliseconds: 400));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byKey(const ValueKey('reward-message')), findsOneWidget);
  });

  testWidgets('animations réduites : aucun effet, la réussite reste lisible '
      'et annoncée', (tester) async {
    final handle = tester.ensureSemantics();
    final pattern = RewardEngine().onCorrect(_hard);
    await _pump(tester, _card(pattern), reduceMotion: true);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    final stage = find.byType(RewardStage);
    expect(
      find.descendant(of: stage, matching: find.byType(CustomPaint)),
      findsNothing,
    );
    final message = find.byKey(const ValueKey('reward-message'));
    expect(message, findsOneWidget);
    expect(tester.getSemantics(message), isSemantics(isLiveRegion: true));
    handle.dispose();
  });

  testWidgets('grande étape : scène plein écran brève qui ne bloque aucun '
      'geste', (tester) async {
    final pattern = RewardEngine().onCorrect(
      const RewardEvent.chapterCompleted(
        source: RewardSource.feed,
        chapterTitle: 'Arithmétique',
      ),
    );
    var taps = 0;
    await _pump(
      tester,
      Column(
        children: [
          _card(pattern),
          TextButton(onPressed: () => taps++, child: const Text('suite')),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey('reward-milestone-message')),
      findsOneWidget,
    );
    await tester.tap(find.text('suite'), warnIfMissed: false);
    expect(taps, 1, reason: 'le geste traverse la scène');
    await tester.pump(pattern.duration + const Duration(milliseconds: 200));
    expect(
      find.byKey(const ValueKey('reward-milestone-message')),
      findsNothing,
    );
  });

  testWidgets('grande étape avec animations réduites : pas de plein écran', (
    tester,
  ) async {
    final pattern = RewardEngine().onCorrect(
      const RewardEvent.chapterCompleted(
        source: RewardSource.feed,
        chapterTitle: 'Arithmétique',
      ),
    );
    await _pump(tester, _card(pattern), reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey('reward-milestone-message')),
      findsNothing,
    );
    expect(find.textContaining('Arithmétique'), findsOneWidget);
  });

  for (final locale in const [Locale('fr'), Locale('en')]) {
    testWidgets('320 px, texte ×1,5, ${locale.languageCode} : messages longs '
        'en entier', (tester) async {
      final engine = RewardEngine();
      final patterns = [
        engine.onCorrect(_hard),
        engine.onCorrect(
          const RewardEvent.correct(
            source: RewardSource.practice,
            masteryBefore: 60,
            masteryAfter: 75,
            masteryThreshold: 70,
            conceptTitle: 'Division euclidienne et divisibilité dans Z',
          ),
        ),
        engine.onCorrect(
          const RewardEvent.correct(
            source: RewardSource.practice,
            errorsBefore: 3,
          ),
        ),
      ];
      for (final pattern in patterns) {
        await _pump(
          tester,
          _card(pattern),
          size: const Size(320, 700),
          textScale: 1.5,
          locale: locale,
        );
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        for (final p in tester.allRenderObjects.whereType<RenderParagraph>()) {
          expect(p.didExceedMaxLines, isFalse);
        }
      }
    });
  }

  test('préférence « Vibrations pédagogiques » enregistrée et relue', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(hapticModeProvider), HapticMode.on);
    await container
        .read(userPreferencesProvider.notifier)
        .setHaptics(HapticMode.reduced);
    expect(container.read(hapticModeProvider), HapticMode.reduced);
    expect(container.read(hapticPlayerProvider).mode, HapticMode.reduced);

    final next = ProviderContainer();
    addTearDown(next.dispose);
    next.read(userPreferencesProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(next.read(hapticModeProvider), HapticMode.reduced);
  });
}
