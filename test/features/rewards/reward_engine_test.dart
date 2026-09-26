import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/rewards/application/reward_providers.dart';
import 'package:intellia237/features/rewards/domain/haptic_pattern.dart';
import 'package:intellia237/features/rewards/domain/reward_engine.dart';
import 'package:intellia237/features/rewards/domain/reward_event.dart';
import 'package:intellia237/features/rewards/domain/reward_pattern.dart';

class _Clock {
  DateTime now = DateTime(2026, 9, 25, 9);
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

class _RecordingDriver implements HapticDriver {
  final impulses = <HapticImpulse>[];

  @override
  Future<void> impulse(HapticImpulse impulse) async => impulses.add(impulse);
}

const _easy = RewardEvent.correct(
  source: RewardSource.practice,
  difficulty: 1,
  maxDifficulty: 3,
  masteryBefore: 10,
  masteryAfter: 14,
  masteryThreshold: 70,
);

RewardEvent _slow(RewardEvent e) => RewardEvent.correct(
  source: e.source,
  difficulty: e.difficulty,
  maxDifficulty: e.maxDifficulty,
  masteryBefore: e.masteryBefore,
  masteryAfter: e.masteryAfter,
  masteryThreshold: e.masteryThreshold,
  errorsBefore: e.errorsBefore,
  responseTime: const Duration(seconds: 12),
);

const _hard = RewardEvent.correct(
  source: RewardSource.practice,
  difficulty: 3,
  maxDifficulty: 3,
  masteryBefore: 40,
  masteryAfter: 48,
  masteryThreshold: 70,
  responseTime: Duration(seconds: 40),
);

void main() {
  late _Clock clock;
  late RewardEngine engine;

  setUp(() {
    clock = _Clock();
    engine = RewardEngine(clock: clock.call);
  });

  group('niveaux de récompense', () {
    test('A. bonne réponse ordinaire : léger, 300–500 ms, un tap', () {
      final p = engine.onCorrect(_slow(_easy));
      expect(p.tier, RewardTier.ordinary);
      expect(p.intensity, RewardIntensity.light);
      expect(p.haptic, HapticPattern.tap);
      expect(p.duration.inMilliseconds, inInclusiveRange(300, 500));
      expect(p.isRich, isFalse);
    });

    test('réponse rapide : retour minimal, sans message', () {
      final p = engine.onCorrect(
        const RewardEvent.correct(
          source: RewardSource.feed,
          responseTime: Duration(milliseconds: 1200),
        ),
      );
      expect(p.intensity, RewardIntensity.minimal);
      expect(p.message, isNull);
      expect(p.visual, RewardVisual.check);
    });

    test('B. série : « 3 de suite », deux petites impulsions', () {
      engine.onCorrect(_slow(_easy));
      engine.onCorrect(_slow(_easy));
      final third = engine.onCorrect(_slow(_easy));
      expect(third.tier, RewardTier.streak);
      expect(third.message, RewardMessage.streak);
      expect(third.streakCount, 3);
      expect(third.haptic, HapticPattern.doubleTap);
      expect(third.isRich, isFalse);
    });

    test('une erreur interrompt la série', () {
      engine.onCorrect(_slow(_easy));
      engine.onCorrect(_slow(_easy));
      engine.recordIncorrect();
      final p = engine.onCorrect(_slow(_easy));
      expect(p.tier, isNot(RewardTier.streak));
      expect(engine.streak, 1);
    });

    test('C. défi réussi : déploiement, halo, double impulsion marquée', () {
      final p = engine.onCorrect(_hard);
      expect(p.tier, RewardTier.hardWin);
      expect(p.visual, RewardVisual.unfold);
      expect(p.haptic, HapticPattern.firm);
      expect(
        p.message,
        anyOf(RewardMessage.realStep, RewardMessage.challengeMet),
      );
      expect(p.isRich, isTrue);
      expect(p.mayUseName, isTrue);
    });

    test('D. réussite après plusieurs erreurs : doux, sans célébration', () {
      final p = engine.onCorrect(
        const RewardEvent.correct(
          source: RewardSource.practice,
          difficulty: 1,
          maxDifficulty: 3,
          errorsBefore: 3,
        ),
      );
      expect(p.tier, RewardTier.recovery);
      expect(p.isRich, isFalse);
      expect(p.haptic, HapticPattern.soft);
      expect(
        p.message,
        anyOf(RewardMessage.gotItThisTime, RewardMessage.foundIt),
      );
    });

    test('E. notion maîtrisée : anneau, motif distinct, nom réel', () {
      final p = engine.onCorrect(
        const RewardEvent.correct(
          source: RewardSource.practice,
          difficulty: 2,
          maxDifficulty: 3,
          masteryBefore: 64,
          masteryAfter: 72,
          masteryThreshold: 70,
          conceptTitle: 'Congruence modulo n',
        ),
      );
      expect(p.tier, RewardTier.mastery);
      expect(p.visual, RewardVisual.masteryRing);
      expect(p.haptic, HapticPattern.mastery);
      expect(p.message, RewardMessage.conceptMastered);
      expect(p.conceptTitle, 'Congruence modulo n');
    });

    test('F. chapitre terminé : scène plein écran courte', () {
      final p = engine.onCorrect(
        const RewardEvent.chapterCompleted(
          source: RewardSource.practice,
          chapterTitle: 'Arithmétique',
        ),
      );
      expect(p.tier, RewardTier.milestone);
      expect(p.intensity, RewardIntensity.grand);
      expect(p.visual, RewardVisual.milestone);
      expect(p.duration.inMilliseconds, lessThanOrEqualTo(1500));
      expect(p.chapterTitle, 'Arithmétique');
    });

    test('difficulté supérieure débloquée', () {
      final p = engine.onCorrect(
        const RewardEvent.correct(
          source: RewardSource.practice,
          difficulty: 1,
          maxDifficulty: 3,
          difficultyRaised: true,
        ),
      );
      expect(p.tier, RewardTier.levelUp);
      expect(p.message, RewardMessage.levelUp);
    });

    test('progrès net sans franchir le seuil', () {
      final p = engine.onCorrect(
        const RewardEvent.correct(
          source: RewardSource.practice,
          difficulty: 2,
          maxDifficulty: 3,
          masteryBefore: 45,
          masteryAfter: 53,
          masteryThreshold: 70,
          responseTime: Duration(seconds: 20),
        ),
      );
      expect(p.tier, RewardTier.progress);
      expect(p.message, RewardMessage.niceProgress);
    });
  });

  group('anti-répétition', () {
    test('jamais le même effet deux fois de suite, jamais un message parmi '
        'les trois derniers, une réponse ordinaire sur deux sans message', () {
      final patterns = <RewardPattern>[];
      for (var i = 0; i < 20; i++) {
        engine.recordIncorrect(); // pas de série : que de l'ordinaire
        patterns.add(engine.onCorrect(_slow(_easy)));
      }
      for (var i = 1; i < patterns.length; i++) {
        expect(patterns[i].visual, isNot(patterns[i - 1].visual), reason: '$i');
      }
      final shown = [for (final p in patterns) ?p.message];
      for (var i = 0; i < shown.length; i++) {
        final window = shown.sublist((i - 3).clamp(0, i), i);
        expect(window, isNot(contains(shown[i])), reason: '$i');
      }
      expect(shown.length, patterns.length ~/ 2);
    });

    test(
      'plusieurs exercices faciles de suite : aucune grande célébration',
      () {
        final patterns = [
          for (var i = 0; i < 12; i++) engine.onCorrect(_slow(_easy)),
        ];
        expect(patterns.where((p) => p.isRich), isEmpty);
        expect(
          patterns
              .where((p) => p.tier == RewardTier.streak)
              .map((p) => p.streakCount),
          [3, 5, 10],
        );
      },
    );

    test('grandes animations : pas deux à moins de 25 s', () {
      expect(engine.onCorrect(_hard).isRich, isTrue);
      clock.advance(const Duration(seconds: 10));
      final second = engine.onCorrect(_hard);
      expect(second.isRich, isFalse);
      expect(second.intensity, RewardIntensity.medium);
      expect(second.message, isNotNull, reason: 'le message reste');
      clock.advance(const Duration(seconds: 16));
      expect(engine.onCorrect(_hard).isRich, isTrue);
    });

    test('reset : la mémoire d\'un élève ne passe pas au suivant', () {
      engine.onCorrect(_hard);
      engine.reset();
      expect(engine.streak, 0);
      expect(engine.onCorrect(_hard).isRich, isTrue);
    });
  });

  group('haptique comme langage', () {
    test('désactivées : aucune impulsion', () {
      for (final p in HapticPattern.values) {
        expect(p.stepsFor(HapticMode.off), isEmpty, reason: p.name);
      }
    });

    test('réduites : une seule impulsion légère, pour les vrais progrès', () {
      expect(HapticPattern.tap.stepsFor(HapticMode.reduced), isEmpty);
      expect(HapticPattern.soft.stepsFor(HapticMode.reduced), isEmpty);
      for (final p in [
        HapticPattern.doubleTap,
        HapticPattern.firm,
        HapticPattern.mastery,
        HapticPattern.milestone,
      ]) {
        expect(p.stepsFor(HapticMode.reduced), [
          const HapticStep(HapticImpulse.light),
        ]);
      }
    });

    test('activées : motifs distincts, courts, jamais d\'impulsion forte', () {
      final signatures = <String>{};
      for (final p in HapticPattern.values.where(
        (p) => p != HapticPattern.none,
      )) {
        final steps = p.stepsFor(HapticMode.on);
        expect(steps, isNotEmpty);
        final total = steps.fold<int>(
          0,
          (sum, s) => sum + s.pauseBefore.inMilliseconds,
        );
        expect(total, lessThanOrEqualTo(300), reason: p.name);
        signatures.add(steps.join(','));
      }
      expect(signatures, hasLength(HapticPattern.values.length - 1));
      expect(HapticImpulse.values.map((i) => i.name), isNot(contains('heavy')));
    });

    test('le lecteur respecte la préférence', () async {
      for (final (mode, expected) in [
        (HapticMode.on, 2),
        (HapticMode.reduced, 1),
        (HapticMode.off, 0),
      ]) {
        final driver = _RecordingDriver();
        HapticPlayer(driver, mode).play(HapticPattern.doubleTap);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(driver.impulses, hasLength(expected), reason: mode.name);
      }
    });

    test(
      'réponse à revoir : série interrompue, retour doux uniquement',
      () async {
        final driver = _RecordingDriver();
        final dispatcher = RewardDispatcher(
          engine,
          HapticPlayer(driver, HapticMode.on),
        );
        dispatcher.correct(_slow(_easy));
        dispatcher.incorrect();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(engine.streak, 0);
        expect(driver.impulses, [HapticImpulse.light, HapticImpulse.selection]);
      },
    );
  });

  group('aucune dépendance réseau ni modèle de langage', () {
    test('le domaine n\'importe que Flutter foundation', () {
      final dir = Directory('lib/features/rewards/domain');
      for (final file in dir.listSync().whereType<File>()) {
        for (final line in file.readAsLinesSync()) {
          if (!line.startsWith('import ')) continue;
          expect(
            line == "import 'package:flutter/foundation.dart';" ||
                !line.contains(':'),
            isTrue,
            reason: '${file.path}: $line',
          );
          expect(line, isNot(contains('package:http')));
          expect(line, isNot(contains('cloud_functions')));
          expect(line, isNot(contains('firebase')));
        }
      }
    });

    test('la couche récompense n\'importe aucun client réseau ni tuteur', () {
      const forbidden = [
        'package:http/',
        'package:dio/',
        'cloud_functions',
        'firebase_ai',
        'firebase_vertexai',
        'google_generative_ai',
        'ai_companion',
        'cloud_firestore',
      ];
      for (final entity in Directory(
        'lib/features/rewards',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        for (final line in entity.readAsLinesSync()) {
          if (!line.startsWith('import ')) continue;
          for (final token in forbidden) {
            expect(line, isNot(contains(token)), reason: entity.path);
          }
        }
      }
    });

    test('hors ligne : aucune connexion n\'est ouverte', () async {
      var opened = 0;
      await HttpOverrides.runZoned(
        () async {
          final e = RewardEngine();
          for (var i = 0; i < 30; i++) {
            e.onCorrect(i.isEven ? _hard : _slow(_easy));
          }
          e.onCorrect(
            const RewardEvent.chapterCompleted(
              source: RewardSource.feed,
              chapterTitle: 'X',
            ),
          );
        },
        createHttpClient: (_) {
          opened++;
          throw StateError('réseau');
        },
      );
      expect(opened, 0);
    });
  });
}
