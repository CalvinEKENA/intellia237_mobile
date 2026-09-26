import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../data/content_pack_parser.dart' show isPrime;
import '../../domain/game_blueprint.dart';
import '../../engine/answer_checker.dart' show parseInteger;
import '../../domain/question.dart';
import '../../engine/answer_checker.dart' show AnswerChecker, StudentResponse;
import '../../engine/number_theory.dart';
import '../widgets/answer_input.dart';
import '../content_style.dart';
import '../visuals/concept_visuals.dart';
import '../visuals/visual_controls.dart';

/// Une manche de jeu : le moteur fabrique l'énigme (juste par construction)
/// et appelle [onResolved] une seule fois.
class GameRound extends StatelessWidget {
  const GameRound({
    required this.engine,
    required this.level,
    required this.random,
    required this.round,
    required this.onResolved,
    this.missionSteps = const [],
    super.key,
  });

  /// Étapes d'une mission d'intégration (vide pour les autres moteurs).
  final List<Question> missionSteps;

  final GameEngineKind engine;
  final int level;
  final math.Random random;
  final int round;
  final ValueChanged<bool> onResolved;

  @override
  Widget build(BuildContext context) => switch (engine) {
    GameEngineKind.grouping => GroupingRound(
      level: level,
      random: random,
      onResolved: onResolved,
    ),
    GameEngineKind.placeValue => PlaceValueRound(
      level: level,
      random: random,
      round: round,
      onResolved: onResolved,
    ),
    GameEngineKind.modularClock => ModularClockRound(
      level: level,
      random: random,
      onResolved: onResolved,
    ),
    GameEngineKind.factorForge => FactorForgeRound(
      level: level,
      random: random,
      onResolved: onResolved,
    ),
    GameEngineKind.tiling => TilingRound(
      level: level,
      random: random,
      round: round,
      onResolved: onResolved,
    ),
    GameEngineKind.remainderZone => RemainderZoneRound(
      level: level,
      random: random,
      onResolved: onResolved,
    ),
    GameEngineKind.integrationMission => MissionStepRound(
      question: missionSteps[round.clamp(0, missionSteps.length - 1)],
      step: round,
      steps: missionSteps.length,
      onResolved: onResolved,
    ),
  };
}

/// Énoncé d'une manche.
class _Goal extends StatelessWidget {
  const _Goal(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: IntelliaSpacing.md),
    child: Text(
      text,
      key: const ValueKey('game-goal'),
      style: ContentText.body(size: 18, weight: FontWeight.w800),
    ),
  );
}

/// Bouton d'action principal d'une manche.
class _Action extends StatelessWidget {
  const _Action({required this.label, required this.onPressed, this.color});

  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => FilledButton(
    key: ValueKey('game-action-$label'),
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      backgroundColor: color ?? ContentPalette.ink,
    ),
    child: Text(label),
  );
}

/// Bandeau de résultat d'une manche (juste / raté + la bonne écriture).
class _Outcome extends StatelessWidget {
  const _Outcome({required this.correct, required this.detail});

  final bool correct;
  final String detail;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.8, end: 1),
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutBack,
    builder: (context, scale, child) =>
        Transform.scale(scale: scale, child: child),
    child: Container(
      key: const ValueKey('game-outcome'),
      margin: const EdgeInsets.only(top: IntelliaSpacing.md),
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        color: (correct ? ContentPalette.success : ContentPalette.error)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      ),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.highlight_off_rounded,
            color: correct ? ContentPalette.success : ContentPalette.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(detail, style: ContentText.math(size: 18)),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Mixin : résoudre une seule fois, et garder le verdict pour l'afficher.
mixin _Resolves<T extends StatefulWidget> on State<T> {
  bool? verdict;

  void resolve(bool correct, ValueChanged<bool> onResolved) {
    if (verdict != null) return;
    setState(() => verdict = correct);
    onResolved(correct);
  }
}

int _between(math.Random random, int min, int max) =>
    min + random.nextInt(max - min + 1);

// ── Regroupement (ex. Savonnerie Express) ───────────────────────────────

class GroupingRound extends StatefulWidget {
  const GroupingRound({
    required this.level,
    required this.random,
    required this.onResolved,
    super.key,
  });

  final int level;
  final math.Random random;
  final ValueChanged<bool> onResolved;

  @override
  State<GroupingRound> createState() => _GroupingRoundState();
}

class _GroupingRoundState extends State<GroupingRound>
    with _Resolves<GroupingRound> {
  late int _items;
  late int _capacity;
  late int _fullBoxes;
  late int _left;
  late bool _possible;
  int _chosen = 0;

  @override
  void initState() {
    super.initState();
    final r = widget.random;
    switch (widget.level) {
      case 1:
        _capacity = _between(r, 3, 9);
        _items = _between(r, 10, 60);
        _chosen = 0;
      case 2:
        _capacity = _between(r, 4, 15);
        _fullBoxes = _between(r, 3, 9);
        _left = r.nextInt(_capacity);
        _items = _capacity * _fullBoxes + _left;
        _chosen = 2;
      default:
        _items = _between(r, 300, 3000);
        _possible = r.nextBool();
        if (_possible) {
          _capacity = _between(r, 12, 90);
          _fullBoxes = _items ~/ _capacity;
        } else {
          // Un nombre de boîtes pleines qu'aucune taille ne peut produire.
          final start = math.sqrt(_items).ceil() + 1;
          _fullBoxes = -1;
          for (var attempt = 0; attempt < 200; attempt++) {
            final k = _between(r, start, _items ~/ 3);
            if (_items ~/ k == _items ~/ (k + 1)) {
              _fullBoxes = k;
              break;
            }
          }
          if (_fullBoxes < 0) {
            _possible = true;
            _capacity = _between(r, 12, 90);
            _fullBoxes = _items ~/ _capacity;
          }
        }
        _chosen = math.max(1, _items ~/ math.max(_fullBoxes, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.level) {
      1 => _quotient(),
      2 => _capacityRound(),
      _ => _report(),
    };
  }

  Widget _quotient() {
    final q = _items ~/ _capacity;
    final tooMany = _chosen * _capacity > _items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Goal(context.l10n.ceGroupingQuotientGoal(_items, _capacity)),
        GroupingPicture(
          items: _items,
          capacity: _capacity,
          fullBoxes: tooMany ? _items ~/ _capacity : _chosen,
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Text(
          tooMany
              ? context.l10n.ceGroupingTooMany
              : context.l10n.ceGroupingState(
                  _chosen,
                  _items - _chosen * _capacity,
                ),
          textAlign: TextAlign.center,
          style: ContentText.label(
            color: tooMany ? ContentPalette.error : ContentPalette.inkSoft,
          ),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Center(
          child: ValueStepper(
            key: const ValueKey('grouping-boxes'),
            label: context.l10n.ceGroupingFullBoxesLabel,
            value: _chosen,
            min: 0,
            max: _items,
            onChanged: verdict == null
                ? (v) => setState(() => _chosen = v)
                : (_) {},
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        _Action(
          label: context.l10n.ceGameValidate,
          onPressed: verdict == null
              ? () => resolve(_chosen == q, widget.onResolved)
              : null,
        ),
        if (verdict != null)
          _Outcome(
            correct: verdict!,
            detail: '$_items = $_capacity × $q + ${_items % _capacity}',
          ),
      ],
    );
  }

  Widget _capacityRound() {
    final full = _items ~/ _chosen;
    final left = _items % _chosen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Goal(context.l10n.ceGroupingCapacityGoal(_items, _fullBoxes, _left)),
        GroupingPicture(
          items: _items,
          capacity: _chosen,
          fullBoxes: full,
          maxBoxes: 14,
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Text(
          context.l10n.ceGroupingState(full, left),
          textAlign: TextAlign.center,
          style: ContentText.label(color: ContentPalette.inkSoft),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Center(
          child: ValueStepper(
            key: const ValueKey('grouping-capacity'),
            label: context.l10n.ceGroupingCapacity,
            value: _chosen,
            min: 1,
            max: 30,
            color: ContentPalette.warm,
            onChanged: verdict == null
                ? (v) => setState(() => _chosen = v)
                : (_) {},
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        _Action(
          label: context.l10n.ceGameValidate,
          onPressed: verdict == null
              ? () => resolve(
                  full == _fullBoxes && left == _left,
                  widget.onResolved,
                )
              : null,
        ),
        if (verdict != null)
          _Outcome(
            correct: verdict!,
            detail: '$_items = $_capacity × $_fullBoxes + $_left',
          ),
      ],
    );
  }

  Widget _report() {
    final full = _items ~/ _chosen;
    final left = _items % _chosen;
    final maxCapacity = math.max(2, _items ~/ 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Goal(context.l10n.ceGroupingReportGoal(_items, _fullBoxes)),
        FormulaBanner(
          '$_items = $_chosen × $full + $left',
          color: full == _fullBoxes
              ? ContentPalette.success
              : ContentPalette.ink,
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        LabeledSlider(
          label: context.l10n.ceGroupingCapacity,
          value: _chosen.clamp(1, maxCapacity),
          min: 1,
          max: maxCapacity,
          color: ContentPalette.warm,
          onChanged: (v) {
            if (verdict == null) setState(() => _chosen = v);
          },
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _Action(
                label: context.l10n.ceGroupingPossibleWith(_chosen),
                color: ContentPalette.success,
                onPressed: verdict == null
                    ? () => resolve(
                        _possible && full == _fullBoxes,
                        widget.onResolved,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: IntelliaSpacing.sm),
            Expanded(
              child: _Action(
                label: context.l10n.ceGroupingImpossible,
                color: ContentPalette.error,
                onPressed: verdict == null
                    ? () => resolve(!_possible, widget.onResolved)
                    : null,
              ),
            ),
          ],
        ),
        if (verdict != null)
          _Outcome(
            correct: verdict!,
            detail: _possible
                ? '$_items = $_capacity × $_fullBoxes + ${_items - _capacity * _fullBoxes}'
                : '${_items ~/ (_fullBoxes + 1) + 1} ≤ b ≤ ${_items ~/ _fullBoxes}  ∅',
          ),
      ],
    );
  }
}

// ── Valeur de position (ex. La Valise Binaire) ──────────────────────────

class PlaceValueRound extends StatefulWidget {
  const PlaceValueRound({
    required this.level,
    required this.random,
    required this.round,
    required this.onResolved,
    super.key,
  });

  final int level;
  final math.Random random;
  final int round;
  final ValueChanged<bool> onResolved;

  @override
  State<PlaceValueRound> createState() => _PlaceValueRoundState();
}

class _PlaceValueRoundState extends State<PlaceValueRound>
    with _Resolves<PlaceValueRound> {
  late final int _bits = widget.level == 1 ? 5 : 8;
  late final List<bool> _switches = List.filled(_bits, false);
  late final int _target;

  /// Niveau 3, une manche sur deux : lire le code de la valise.
  late final bool _reading = widget.level >= 3 && widget.round.isOdd;
  final _answer = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 25;

  @override
  void initState() {
    super.initState();
    _target = _between(widget.random, 1, (1 << _bits) - 1);
    if (widget.level >= 3) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || verdict != null) return;
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) resolve(false, widget.onResolved);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answer.dispose();
    super.dispose();
  }

  int get _value => [
    for (var i = 0; i < _bits; i++)
      if (_switches[i]) 1 << i,
  ].fold(0, (a, b) => a + b);

  void _toggle(int i) {
    if (verdict != null) return;
    setState(() => _switches[i] = !_switches[i]);
    if (_value == _target) resolve(true, widget.onResolved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final open = verdict == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.level >= 3)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.ceGameTimeLeft(_secondsLeft.clamp(0, 99)),
              style: ContentText.math(
                color: _secondsLeft <= 5
                    ? ContentPalette.error
                    : ContentPalette.inkSoft,
                size: 16,
              ),
            ),
          ),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              open ? Icons.lock_open_rounded : Icons.luggage_rounded,
              key: ValueKey(open),
              size: 72,
              color: open ? ContentPalette.success : ContentPalette.ink,
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        if (_reading) ...[
          _Goal(l10n.ceBinaryReadGoal),
          FormulaBanner('${toBinary(_target)}₂'),
          const SizedBox(height: IntelliaSpacing.sm),
          TextField(
            key: const ValueKey('binary-read-answer'),
            controller: _answer,
            enabled: verdict == null,
            keyboardType: TextInputType.number,
            style: ContentText.math(size: 22),
            decoration: InputDecoration(
              labelText: l10n.ceFieldDecimal,
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          _Action(
            label: l10n.ceGameValidate,
            onPressed: verdict == null
                ? () => resolve(
                    parseInteger(_answer.text) == _target,
                    widget.onResolved,
                  )
                : null,
          ),
        ] else ...[
          _Goal(l10n.ceBinaryTarget(_target)),
          BinarySwitchRow(
            bits: _switches,
            onToggle: _toggle,
            enabled: verdict == null,
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          Text(
            l10n.ceBinaryCurrent(_value),
            textAlign: TextAlign.center,
            style: ContentText.math(
              size: 18,
              color: _value > _target
                  ? ContentPalette.error
                  : ContentPalette.accent,
            ),
          ),
        ],
        if (verdict != null)
          _Outcome(
            correct: verdict!,
            detail: '${toBinary(_target)}₂ = $_target',
          ),
      ],
    );
  }
}

// ── Horloge modulaire (ex. Horloge Modulo) ──────────────────────────────

class ModularClockRound extends StatefulWidget {
  const ModularClockRound({
    required this.level,
    required this.random,
    required this.onResolved,
    super.key,
  });

  final int level;
  final math.Random random;
  final ValueChanged<bool> onResolved;

  @override
  State<ModularClockRound> createState() => _ModularClockRoundState();
}

class _ModularClockRoundState extends State<ModularClockRound>
    with _Resolves<ModularClockRound> {
  late final int _n;
  late final String _expression;
  late final int _answer;
  int? _travel;
  int? _selected;

  @override
  void initState() {
    super.initState();
    final r = widget.random;
    switch (widget.level) {
      case 1:
        _n = _between(r, 5, 12);
        final a = r.nextInt(5) == 0
            ? -_between(r, 1, 3 * _n)
            : _between(r, _n + 1, 6 * _n);
        _expression = '$a';
        _answer = euclideanMod(a, _n);
        _travel = a;
      case 2:
        _n = _between(r, 5, 12);
        final a = _between(r, _n, 5 * _n);
        final b = _between(r, 2, 4 * _n);
        final multiply = r.nextBool();
        _expression = multiply ? '$a × $b' : '$a + $b';
        _answer = euclideanMod(multiply ? a * b : a + b, _n);
      default:
        _n = _between(r, 5, 13);
        final base = _between(r, 2, 5);
        final exponent = _between(r, 10, 60);
        _expression = '$base${superscript(exponent)}';
        _answer = modPow(base, exponent, _n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Goal(
          widget.level == 1
              ? l10n.ceClockGoalReduce(_expression, _n)
              : l10n.ceClockGoalOperation(_expression, _n),
        ),
        Center(
          child: ModularClock(
            modulus: _n,
            selected: _selected,
            correctSlot: verdict == null ? null : _answer,
            travel: verdict == null ? null : _travel,
            onTapSlot: verdict == null
                ? (slot) {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = slot);
                  }
                : null,
            size: 260,
          ),
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        Text(
          l10n.ceClockTap,
          textAlign: TextAlign.center,
          style: ContentText.body(color: ContentPalette.inkSoft, size: 13),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        _Action(
          label: l10n.ceGameValidate,
          onPressed: verdict == null && _selected != null
              ? () => resolve(_selected == _answer, widget.onResolved)
              : null,
        ),
        if (verdict != null)
          _Outcome(
            correct: verdict!,
            detail: '$_expression ≡ $_answer  (mod $_n)',
          ),
      ],
    );
  }
}

// ── Forge des premiers ──────────────────────────────────────────────────

class FactorForgeRound extends StatefulWidget {
  const FactorForgeRound({
    required this.level,
    required this.random,
    required this.onResolved,
    super.key,
  });

  final int level;
  final math.Random random;
  final ValueChanged<bool> onResolved;

  @override
  State<FactorForgeRound> createState() => _FactorForgeRoundState();
}

class _FactorForgeRoundState extends State<FactorForgeRound>
    with _Resolves<FactorForgeRound>, SingleTickerProviderStateMixin {
  static const _hammers = [2, 3, 5, 7, 11, 13, 17, 19, 23];
  late final int _number;
  late int _block;
  final _bricks = <int>[];
  int _misses = 0;
  int? _bounced;
  final _divisors = TextEditingController();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void initState() {
    super.initState();
    final r = widget.random;
    if (widget.level == 1) {
      var n = _between(r, 11, 99);
      final wantPrime = r.nextBool();
      while (isPrime(n) != wantPrime) {
        n = _between(r, 11, 99);
      }
      _number = n;
    } else {
      final primes = widget.level == 2
          ? const [2, 3, 5, 7, 11, 13]
          : const [2, 3, 5, 7, 11, 13, 17, 19, 23];
      var n = 1;
      final count = _between(r, 3, 5);
      for (var i = 0; i < count; i++) {
        final p = primes[r.nextInt(primes.length)];
        if (n * p > 7000) break;
        n *= p;
      }
      if (isPrime(n) || n < 12) n *= 6;
      _number = n;
    }
    _block = _number;
  }

  @override
  void dispose() {
    _shake.dispose();
    _divisors.dispose();
    super.dispose();
  }

  void _strike(int prime) {
    if (verdict != null || _block == 1) return;
    if (_block % prime == 0) {
      HapticFeedback.mediumImpact();
      setState(() {
        _bricks.add(prime);
        _block ~/= prime;
        _bounced = null;
      });
      if (_block == 1 && widget.level == 2) {
        resolve(_misses <= 2, widget.onResolved);
      }
    } else {
      HapticFeedback.lightImpact();
      _shake.forward(from: 0);
      setState(() {
        _misses++;
        _bounced = prime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final done = _block == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Goal(
          widget.level == 1
              ? l10n.ceForgePrimeGoal(_number)
              : done && widget.level >= 3
              ? l10n.ceForgeDivisorsGoal(_number)
              : l10n.ceForgeSplitGoal(_number),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(math.sin(_shake.value * math.pi * 6) * 8, 0),
              child: child,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: BoxDecoration(
                color: done ? ContentPalette.success : const Color(0xFF3E3A5C),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 6),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                done ? '✓' : '$_block',
                key: const ValueKey('forge-block'),
                style: ContentText.math(color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        BrickRow(bricks: _bricks),
        if (_bounced != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.ceForgeBounce(_bounced!),
              textAlign: TextAlign.center,
              style: ContentText.label(color: ContentPalette.error),
            ),
          ),
        const SizedBox(height: IntelliaSpacing.md),
        if (!done || widget.level == 1)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final prime in _hammers.where(
                (p) => widget.level > 1 || p <= 7,
              ))
                ActionChip(
                  key: ValueKey('hammer-$prime'),
                  avatar: const Icon(Icons.hardware_rounded, size: 18),
                  label: Text('$prime', style: ContentText.math(size: 16)),
                  onPressed: verdict == null ? () => _strike(prime) : null,
                ),
            ],
          ),
        if (widget.level == 1) ...[
          const SizedBox(height: IntelliaSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Action(
                  label: l10n.cePrime,
                  color: ContentPalette.success,
                  onPressed: verdict == null
                      ? () => resolve(isPrime(_number), widget.onResolved)
                      : null,
                ),
              ),
              const SizedBox(width: IntelliaSpacing.sm),
              Expanded(
                child: _Action(
                  label: l10n.ceComposite,
                  color: ContentPalette.warm,
                  onPressed: verdict == null
                      ? () => resolve(!isPrime(_number), widget.onResolved)
                      : null,
                ),
              ),
            ],
          ),
        ],
        if (done && widget.level >= 3 && verdict == null) ...[
          TextField(
            key: const ValueKey('forge-divisors'),
            controller: _divisors,
            keyboardType: TextInputType.number,
            style: ContentText.math(size: 22),
            decoration: InputDecoration(
              labelText: l10n.ceForgeDivisorsLabel,
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          _Action(
            label: l10n.ceGameValidate,
            onPressed: () => resolve(
              parseInteger(_divisors.text) == divisorCount(_number) &&
                  _misses <= 3,
              widget.onResolved,
            ),
          ),
        ],
        if (verdict != null)
          _Outcome(
            correct: verdict!,
            detail: widget.level == 1
                ? (isPrime(_number)
                      ? l10n.ceForgeIsPrime(_number)
                      : '$_number = ${factorizationText(factorize(_number))}')
                : widget.level >= 3
                ? '$_number = ${factorizationText(factorize(_number))}  →  '
                      '${divisorCount(_number)}'
                : '$_number = ${factorizationText(factorize(_number))}',
          ),
      ],
    );
  }
}

// ── Pavage et rythmes (ex. Maître Carreleur) ────────────────────────────

class TilingRound extends StatefulWidget {
  const TilingRound({
    required this.level,
    required this.random,
    required this.round,
    required this.onResolved,
    super.key,
  });

  final int level;
  final math.Random random;
  final int round;
  final ValueChanged<bool> onResolved;

  @override
  State<TilingRound> createState() => _TilingRoundState();
}

class _TilingRoundState extends State<TilingRound> with _Resolves<TilingRound> {
  /// Niveau 3 : un rectangle ou deux rythmes, et il faut choisir l'outil.
  late final bool _rhythm = widget.level >= 3 && widget.random.nextBool();
  late final int _a;
  late final int _b;
  late int _choice;
  bool? _tool; // true : PPCM choisi, false : PGCD choisi.

  @override
  void initState() {
    super.initState();
    final r = widget.random;
    const units = [10, 12, 15, 20, 30, 40, 60];
    int coprimePart(int exclude) {
      var value = _between(r, 1, 6);
      while (gcd(value, exclude) != 1) {
        value = _between(r, 1, 6);
      }
      return value;
    }

    if (_rhythm) {
      final g = _between(r, 2, 6);
      final x = _between(r, 2, 5);
      final y = coprimePart(x);
      _a = g * x;
      _b = g * (y == x ? y + 1 : y);
      _choice = math.max(_a, _b);
    } else {
      final g = widget.level == 1
          ? _between(r, 2, 6)
          : units[r.nextInt(units.length)];
      final x = _between(r, 2, 5);
      final y = coprimePart(x);
      _a = g * x;
      _b = g * math.max(y, 1);
      _choice = 1;
    }
  }

  bool get _toolPicked => widget.level < 3 || _tool != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final target = _rhythm ? lcm(_a, _b) : gcd(_a, _b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Goal(
          _rhythm ? l10n.ceTilingLcmGoal(_a, _b) : l10n.ceTilingGcdGoal(_a, _b),
        ),
        if (!_toolPicked) ...[
          Text(
            l10n.ceTilingChooseTool,
            textAlign: TextAlign.center,
            style: ContentText.label(size: 16),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          Row(
            children: [
              for (final (isLcm, label) in [
                (false, l10n.ceGcd),
                (true, l10n.ceLcm),
              ]) ...[
                Expanded(
                  child: _Action(
                    label: label,
                    color: isLcm ? ContentPalette.warm : ContentPalette.accent,
                    onPressed: () {
                      if (isLcm != _rhythm) {
                        setState(() => _tool = isLcm);
                        resolve(false, widget.onResolved);
                      } else {
                        setState(() => _tool = isLcm);
                      }
                    },
                  ),
                ),
                if (!isLcm) const SizedBox(width: IntelliaSpacing.sm),
              ],
            ],
          ),
        ] else if (_rhythm) ...[
          RhythmPicture(a: _a, b: _b, length: _choice, meetAt: target),
          LabeledSlider(
            label: l10n.ceTilingDistance,
            value: _choice,
            min: 1,
            max: _a * _b,
            onChanged: (v) {
              if (verdict == null) setState(() => _choice = v);
            },
          ),
        ] else ...[
          TilingPicture(width: _a, height: _b, tile: _choice),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            _a % _choice == 0 && _b % _choice == 0
                ? (_choice == target
                      ? l10n.ceVisTilesFit
                      : l10n.ceTilingFitsButSmaller)
                : l10n.ceVisTilesCut,
            textAlign: TextAlign.center,
            style: ContentText.label(color: ContentPalette.inkSoft),
          ),
          if (widget.level == 1)
            Center(
              child: ValueStepper(
                key: const ValueKey('tiling-side'),
                label: l10n.ceTilingTile,
                value: _choice,
                min: 1,
                max: math.min(_a, _b),
                onChanged: (v) {
                  if (verdict == null) setState(() => _choice = v);
                },
              ),
            )
          else
            LabeledSlider(
              label: l10n.ceTilingTile,
              value: _choice,
              min: 1,
              max: math.min(_a, _b),
              onChanged: (v) {
                if (verdict == null) setState(() => _choice = v);
              },
            ),
        ],
        if (_toolPicked && verdict == null) ...[
          const SizedBox(height: IntelliaSpacing.md),
          _Action(
            label: l10n.ceGameValidate,
            onPressed: () => resolve(_choice == target, widget.onResolved),
          ),
        ],
        if (verdict != null)
          _Outcome(
            correct: verdict!,
            detail: _rhythm
                ? '${l10n.ceLcm}($_a, $_b) = $target'
                : '${l10n.ceGcd}($_a, $_b) = $target',
          ),
      ],
    );
  }
}

// ── Zone du Reste (division euclidienne dans Z) ─────────────────────────

class RemainderZoneRound extends StatefulWidget {
  const RemainderZoneRound({
    required this.level,
    required this.random,
    required this.onResolved,
    super.key,
  });

  final int level;
  final math.Random random;
  final ValueChanged<bool> onResolved;

  @override
  State<RemainderZoneRound> createState() => _RemainderZoneRoundState();
}

class _RemainderZoneRoundState extends State<RemainderZoneRound>
    with _Resolves<RemainderZoneRound> {
  late final int _a;
  late final int _b;
  int _q = 0;
  String? _justification;

  /// Niveau 3 : la condition qui justifie le reste.
  static const _conditions = ['0 ≤ r < |b|', '0 ≤ r < b', '−|b| < r ≤ 0'];

  @override
  void initState() {
    super.initState();
    final r = widget.random;
    switch (widget.level) {
      case 1:
        _a = _between(r, 10, 90);
        _b = _between(r, 3, 12);
      case 2:
        _a = -_between(r, 10, 90);
        _b = _between(r, 3, 12);
      default:
        _a = _between(r, -60, 90);
        _b = -_between(r, 3, 12);
    }
  }

  int get _r => _a - _b * _q;
  bool get _inZone => _r >= 0 && _r < _b.abs();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = _b.abs();
    final bText = _b < 0 ? '($_b)' : '$_b';
    final qText = _q < 0 ? '($_q)' : '$_q';
    final needsJustification = widget.level >= 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Goal(l10n.ceRemainderGoal(_a, _b)),
        Text(
          l10n.ceVisAllowedRemainders(size - 1),
          textAlign: TextAlign.center,
          style: ContentText.label(color: ContentPalette.inkSoft),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _Edge(active: _r < 0, pointsLeft: true),
            for (var i = 0; i < size; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: 46,
                  decoration: BoxDecoration(
                    color: i == _r
                        ? ContentPalette.success
                        : ContentPalette.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    child: Text(
                      '$i',
                      style: ContentText.math(
                        size: 15,
                        color: i == _r ? Colors.white : ContentPalette.success,
                      ),
                    ),
                  ),
                ),
              ),
            _Edge(active: _r >= size, pointsLeft: false),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        FormulaBanner(
          '$_a = $bText × $qText + $_r',
          color: _inZone ? ContentPalette.success : ContentPalette.error,
        ),
        const SizedBox(height: 4),
        Text(
          _inZone
              ? l10n.ceRemainderInZone
              : _r < 0
              ? l10n.ceRemainderTooSmall
              : l10n.ceRemainderTooLarge,
          textAlign: TextAlign.center,
          style: ContentText.label(
            color: _inZone ? ContentPalette.success : ContentPalette.error,
          ),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Center(
          child: ValueStepper(
            key: const ValueKey('remainder-q'),
            label: l10n.ceFieldQuotient,
            value: _q,
            min: -60,
            max: 60,
            onChanged: verdict == null ? (v) => setState(() => _q = v) : (_) {},
          ),
        ),
        if (needsJustification) ...[
          const SizedBox(height: IntelliaSpacing.md),
          Text(l10n.ceRemainderWhy, style: ContentText.label(size: 14)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final condition in _conditions)
                ChoiceChip(
                  key: ValueKey('remainder-why-$condition'),
                  label: Text(condition, style: ContentText.math(size: 16)),
                  selected: _justification == condition,
                  onSelected: verdict == null
                      ? (_) => setState(() => _justification = condition)
                      : null,
                ),
            ],
          ),
        ],
        const SizedBox(height: IntelliaSpacing.md),
        _Action(
          label: l10n.ceGameValidate,
          onPressed:
              verdict == null && (!needsJustification || _justification != null)
              ? () => resolve(
                  _inZone &&
                      (!needsJustification ||
                          _justification == _conditions.first),
                  widget.onResolved,
                )
              : null,
        ),
        if (verdict != null)
          _Outcome(
            correct: verdict!,
            detail:
                '$_a = $bText × ${euclideanQuotient(_a, _b)} + '
                '${euclideanMod(_a, _b)}',
          ),
      ],
    );
  }
}

/// Flèche de bord : le reste est sorti de la zone, de ce côté.
class _Edge extends StatelessWidget {
  const _Edge({required this.active, required this.pointsLeft});

  final bool active;
  final bool pointsLeft;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: const Duration(milliseconds: 200),
    opacity: active ? 1 : 0.15,
    child: Icon(
      pointsLeft ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      color: ContentPalette.error,
      size: 28,
    ),
  );
}

// ── Mission d'intégration ───────────────────────────────────────────────

class MissionStepRound extends StatefulWidget {
  const MissionStepRound({
    required this.question,
    required this.step,
    required this.steps,
    required this.onResolved,
    super.key,
  });

  final Question question;
  final int step;
  final int steps;
  final ValueChanged<bool> onResolved;

  @override
  State<MissionStepRound> createState() => _MissionStepRoundState();
}

class _MissionStepRoundState extends State<MissionStepRound>
    with _Resolves<MissionStepRound> {
  StudentResponse? _draft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final question = widget.question;
    final critical = question.tags.any(Question.sensitiveTags.contains);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.ceMissionStep(widget.step + 1, widget.steps).toUpperCase(),
          style: ContentText.eyebrow(color: ContentPalette.warm),
        ),
        const SizedBox(height: 6),
        _Goal(question.prompt),
        for (final flag in question.visibleFlags)
          Container(
            margin: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
            padding: const EdgeInsets.all(IntelliaSpacing.sm),
            decoration: BoxDecoration(
              color: ContentPalette.warm.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(IntelliaRadii.small),
            ),
            child: Text(flag.issue, style: ContentText.body(size: 13)),
          ),
        AnswerInput(
          question: question,
          enabled: verdict == null,
          onChanged: (draft) => setState(() => _draft = draft),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        _Action(
          label: l10n.ceGameValidate,
          onPressed: verdict == null && _draft != null
              ? () => resolve(
                  const AnswerChecker().grade(question, _draft!).correct,
                  widget.onResolved,
                )
              : null,
        ),
        if (verdict != null) ...[
          const SizedBox(height: IntelliaSpacing.md),
          if (verdict! && critical)
            Text(
              l10n.ceMissionCriticalThinking,
              style: ContentText.label(color: ContentPalette.success, size: 14),
            ),
          if (question.explanation case final text?)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(text, style: ContentText.body(size: 14.5)),
            ),
        ],
      ],
    );
  }
}
