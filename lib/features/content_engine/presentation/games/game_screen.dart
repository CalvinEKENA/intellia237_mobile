import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../rewards/application/reward_providers.dart';
import '../../../rewards/domain/reward_event.dart';
import '../../../rewards/domain/reward_pattern.dart';
import '../../../rewards/presentation/reward_stage.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/intellia_state_view.dart';
import '../../application/content_providers.dart';
import '../../domain/chapter.dart';
import '../../domain/game_blueprint.dart';
import '../content_style.dart';
import '../../domain/question.dart';
import '../../engine/mission_planner.dart';
import 'game_rounds.dart';

/// Un jeu du pack, joué par son moteur générique.
class ContentGameScreen extends ConsumerWidget {
  const ContentGameScreen({
    required this.contentId,
    required this.gameId,
    this.seed,
    super.key,
  });

  final String contentId;
  final String gameId;

  /// Graine des manches (tests) ; sinon chaque partie est différente.
  final int? seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync = ref.watch(contentChapterProvider(contentId));
    return Scaffold(
      backgroundColor: const Color(0xFF14122B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Unavailable(),
        data: (chapter) {
          final game = chapter.games.where((g) => g.id == gameId).firstOrNull;
          if (game == null || !game.playable || !chapter.isPlayable) {
            return _Unavailable();
          }
          return GameShell(chapter: chapter, game: game, seed: seed);
        },
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(IntelliaSpacing.lg),
    child: IntelliaStateView(
      kind: IntelliaStateKind.comingSoon,
      title: context.l10n.ceGameComingSoon,
    ),
  );
}

/// Partie : choix du niveau, manches, score, série, bilan.
class GameShell extends ConsumerStatefulWidget {
  const GameShell({
    required this.chapter,
    required this.game,
    this.seed,
    this.rounds = 5,
    super.key,
  });

  final Chapter chapter;
  final GameBlueprint game;
  final int? seed;
  final int rounds;

  @override
  ConsumerState<GameShell> createState() => _GameShellState();
}

class _GameShellState extends ConsumerState<GameShell> {
  int? _level;
  int _round = 0;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _wins = 0;
  bool? _lastCorrect;
  int _lastPoints = 0;
  RewardPattern? _reward;
  DateTime _roundStartedAt = DateTime.now();
  late math.Random _random;

  /// Étapes validées d'une mission d'intégration (sinon vide).
  late final List<Question> _missionSteps =
      widget.game.engine == GameEngineKind.integrationMission
      ? missionSteps(widget.chapter, widget.game)
      : const [];

  /// Une mission compte autant de manches que d'étapes.
  int get _rounds =>
      _missionSteps.isEmpty ? widget.rounds : _missionSteps.length;

  @override
  void initState() {
    super.initState();
    _random = math.Random(widget.seed ?? DateTime.now().microsecondsSinceEpoch);
  }

  void _start(int level) => setState(() {
    _level = level;
    _round = 0;
    _score = 0;
    _streak = 0;
    _bestStreak = 0;
    _wins = 0;
    _lastCorrect = null;
  });

  void _resolved(bool correct) {
    if (_lastCorrect != null) return;
    // Même moteur de récompense que les exercices : la manche la plus
    // difficile compte comme un défi, les séries sont annoncées.
    final rewards = ref.read(rewardDispatcherProvider);
    if (correct) {
      _reward = rewards.correct(
        RewardEvent.correct(
          source: RewardSource.game,
          difficulty: _level,
          maxDifficulty: widget.game.levels.keys.fold<int>(1, math.max),
          responseTime: DateTime.now().difference(_roundStartedAt),
        ),
      );
    } else {
      _reward = null;
      rewards.incorrect();
    }
    setState(() {
      _streak = correct ? _streak + 1 : 0;
      _bestStreak = math.max(_bestStreak, _streak);
      if (correct) _wins++;
      _lastPoints = widget.game.scoring.pointsFor(
        correct: correct,
        streak: _streak,
        level: _level!,
      );
      _score = math.max(0, _score + _lastPoints);
      _lastCorrect = correct;
    });
  }

  void _next() => setState(() {
    _round++;
    _lastCorrect = null;
    _reward = null;
    _roundStartedAt = DateTime.now();
  });

  @override
  Widget build(BuildContext context) {
    final level = _level;
    if (level == null) return _LevelPicker(game: widget.game, onPick: _start);
    if (_round >= _rounds) {
      final levels = widget.game.levels.keys.toList();
      final nextLevel = levels.where((l) => l > level).firstOrNull;
      return _Summary(
        game: widget.game,
        score: _score,
        wins: _wins,
        rounds: _rounds,
        bestStreak: _bestStreak,
        onReplay: () => _start(level),
        onNextLevel: nextLevel == null ? null : () => _start(nextLevel),
      );
    }
    final l10n = context.l10n;
    return Column(
      children: [
        _Hud(
          title: widget.game.title,
          round: _round + 1,
          rounds: _rounds,
          score: _score,
          streak: _streak,
          levelLabel: widget.game.levels[level] ?? '',
          level: level,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.lg,
              IntelliaSpacing.sm,
              IntelliaSpacing.lg,
              IntelliaSpacing.lg,
            ),
            child: Container(
              padding: const EdgeInsets.all(IntelliaSpacing.lg),
              decoration: BoxDecoration(
                color: ContentPalette.paper,
                borderRadius: BorderRadius.circular(IntelliaRadii.hero),
              ),
              child: RewardStage(
                pattern: _lastCorrect == true ? _reward : null,
                child: GameRound(
                  key: ValueKey('round-$level-$_round'),
                  engine: widget.game.engine!,
                  level: level,
                  random: _random,
                  round: _round,
                  onResolved: _resolved,
                  missionSteps: _missionSteps,
                ),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _lastCorrect == null
              ? const SizedBox(height: 0)
              : Padding(
                  key: ValueKey('result-$_round'),
                  padding: const EdgeInsets.fromLTRB(
                    IntelliaSpacing.lg,
                    0,
                    IntelliaSpacing.lg,
                    IntelliaSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lastCorrect!
                            ? Icons.celebration_rounded
                            : Icons.replay_rounded,
                        color: _lastCorrect!
                            ? IntelliaFlag.yellowOnInk
                            : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_lastCorrect! ? l10n.ceGameGreat : l10n.ceGameMissed}'
                              '  ${_lastPoints >= 0 ? '+' : ''}$_lastPoints',
                              style: ContentText.label(
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            if (_lastCorrect! && _reward != null)
                              RewardMessageLine(
                                pattern: _reward,
                                style: ContentText.label(
                                  color: IntelliaFlag.yellowOnInk,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        key: const ValueKey('game-next-round'),
                        style: FilledButton.styleFrom(
                          backgroundColor: IntelliaFlag.yellowOnInk,
                          foregroundColor: ContentPalette.ink,
                        ),
                        onPressed: _next,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(l10n.ceGameContinue),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.title,
    required this.round,
    required this.rounds,
    required this.score,
    required this.streak,
    required this.levelLabel,
    required this.level,
  });

  final String title;
  final int round;
  final int rounds;
  final int score;
  final int streak;
  final String levelLabel;
  final int level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        0,
        IntelliaSpacing.lg,
        IntelliaSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContentHeading(
            title,
            style: ContentText.title(color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            levelLabel,
            style: ContentText.body(color: Colors.white70, size: 12.5),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Pill(
                      icon: Icons.flag_rounded,
                      text: l10n.ceGameRound(round, rounds),
                      color: ContentPalette.difficulty(level),
                    ),
                    _Pill(
                      icon: Icons.local_fire_department_rounded,
                      text: l10n.ceGameStreak(streak),
                      color: streak > 1 ? ContentPalette.warm : Colors.white24,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TweenAnimationBuilder<int>(
                tween: IntTween(end: score),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, _) => Text(
                  l10n.ceGameScore(value),
                  key: const ValueKey('game-score'),
                  style: ContentText.math(
                    color: IntelliaFlag.yellowOnInk,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (round - 1) / rounds,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(
                IntelliaFlag.yellowOnInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(IntelliaRadii.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(text, style: ContentText.label(color: Colors.white, size: 12)),
      ],
    ),
  );
}

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({required this.game, required this.onPick});

  final GameBlueprint game;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(IntelliaSpacing.lg),
    children: [
      Text(game.title, style: ContentText.title(color: Colors.white, size: 30)),
      const SizedBox(height: IntelliaSpacing.xs),
      Text(game.mechanic, style: ContentText.body(color: Colors.white70)),
      const SizedBox(height: IntelliaSpacing.lg),
      Text(
        context.l10n.ceGameChooseLevel.toUpperCase(),
        style: ContentText.eyebrow(color: IntelliaFlag.yellowOnInk),
      ),
      const SizedBox(height: IntelliaSpacing.sm),
      for (final entry in game.levels.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
          child: Material(
            color: ContentPalette.difficulty(entry.key).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(IntelliaRadii.card),
            child: InkWell(
              key: ValueKey('game-level-${entry.key}'),
              borderRadius: BorderRadius.circular(IntelliaRadii.card),
              onTap: () => onPick(entry.key),
              child: Padding(
                padding: const EdgeInsets.all(IntelliaSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: ContentPalette.difficulty(entry.key),
                      child: Text(
                        '${entry.key}',
                        style: ContentText.math(color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: IntelliaSpacing.md),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: ContentText.body(color: Colors.white, size: 15),
                      ),
                    ),
                    const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.game,
    required this.score,
    required this.wins,
    required this.rounds,
    required this.bestStreak,
    required this.onReplay,
    this.onNextLevel,
  });

  final GameBlueprint game;
  final int score;
  final int wins;
  final int rounds;
  final int bestStreak;
  final VoidCallback onReplay;
  final VoidCallback? onNextLevel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 88,
                color: IntelliaFlag.yellowOnInk,
              ),
            ),
            const SizedBox(height: IntelliaSpacing.md),
            Text(
              l10n.ceGameFinished,
              style: ContentText.title(color: Colors.white, size: 28),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              l10n.ceGameFinalScore(score),
              key: const ValueKey('game-final-score'),
              style: ContentText.math(
                color: IntelliaFlag.yellowOnInk,
                size: 30,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.ceGameWins(wins, rounds, bestStreak),
              textAlign: TextAlign.center,
              style: ContentText.body(color: Colors.white70),
            ),
            const SizedBox(height: IntelliaSpacing.lg),
            Wrap(
              spacing: IntelliaSpacing.sm,
              runSpacing: IntelliaSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('game-replay'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l10n.ceGameReplay),
                ),
                if (onNextLevel != null)
                  FilledButton.icon(
                    key: const ValueKey('game-next-level'),
                    style: FilledButton.styleFrom(
                      backgroundColor: IntelliaFlag.yellowOnInk,
                      foregroundColor: ContentPalette.ink,
                    ),
                    onPressed: onNextLevel,
                    icon: const Icon(Icons.trending_up_rounded),
                    label: Text(l10n.ceGameNextLevel),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
