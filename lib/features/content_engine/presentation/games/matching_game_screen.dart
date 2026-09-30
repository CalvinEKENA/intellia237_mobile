import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../profile/application/user_preferences_controller.dart';
import '../../application/content_providers.dart';
import '../../domain/chapter.dart';
import '../../domain/game_blueprint.dart';
import '../../domain/matching_game.dart';
import '../../engine/matching_game_engine.dart';

/// A board rather than a sequence of QCM: all cards are visible, relationships
/// are rebuilt and successful pairs remain locked. Works with taps alone.
class MatchingGameShell extends ConsumerStatefulWidget {
  const MatchingGameShell({
    required this.chapter,
    required this.game,
    this.seed = 0,
    super.key,
  });
  final Chapter chapter;
  final GameBlueprint game;
  final int seed;
  @override
  ConsumerState<MatchingGameShell> createState() => _MatchingGameShellState();
}

class _MatchingGameShellState extends ConsumerState<MatchingGameShell> {
  int _index = 0;
  int _replays = 0;
  late MatchingGameEngine _board;
  String? _feedback;
  bool _saving = false;
  bool? _saved;
  bool _saveError = false;

  @override
  void initState() {
    super.initState();
    _newBoard();
  }

  void _newBoard() {
    _board = MatchingGameEngine(
      widget.game.matchingRounds[_index],
      seed: widget.seed + _index + _replays * 237,
    );
    _feedback = null;
    _saved = null;
    _saving = false;
    _saveError = false;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = false;
    });
    try {
      final saved = await ref
          .read(learnerContentControllerProvider.notifier)
          .recordMatchingBoard(
            chapter: widget.chapter,
            game: widget.game,
            board: _board,
          );
      if (mounted) setState(() => _saved = saved);
    } catch (_) {
      if (mounted) setState(() => _saveError = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _link(MatchingPair target) {
    final selected = _board.round.pairs
        .where((p) => p.id == _board.selected)
        .firstOrNull;
    if (selected == null) return;
    final verdict = _board.link(target.id);
    if (verdict == null) return;
    setState(() {
      _feedback =
          '${verdict ? context.l10n.gmCorrectLink : context.l10n.gmWrongLink} '
          '${selected.left} → ${selected.right}. ${selected.explanation}';
    });
    if (_board.complete) _save();
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final reduced =
        ref.watch(userPreferencesProvider).reduceMotion ||
        MediaQuery.disableAnimationsOf(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: ListView(
        key: const ValueKey('matching-board-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            widget.game.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy.gmBoard(
              _index + 1,
              widget.game.matchingRounds.length,
              _board.round.difficulty,
            ),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9FC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _board.round.prompt,
                  style: const TextStyle(
                    color: IntelliaColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  copy.gmInstruction,
                  style: const TextStyle(
                    color: IntelliaColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, box) {
                    final a = _column(_board.left, true);
                    final b = _column(_board.right, false);
                    if (box.maxWidth < 400 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                      return Column(
                        children: [a, const SizedBox(height: 16), b],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: a),
                        const SizedBox(width: 16),
                        Expanded(child: b),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  copy.gmAccuracy(
                    _board.firstPass,
                    _board.round.pairs.length,
                    _board.errors,
                  ),
                  key: const ValueKey('matching-accuracy'),
                ),
                if (_feedback != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _feedback!,
                      key: const ValueKey('matching-feedback'),
                    ),
                  ),
                ],
                if (_board.round.hint != null && !_board.complete) ...[
                  TextButton.icon(
                    key: const ValueKey('matching-hint'),
                    icon: const Icon(Icons.lightbulb_outline),
                    onPressed: () => setState(() => _board.revealHint()),
                    label: Text(copy.ceHint),
                  ),
                  if (_board.helped) Text(_board.round.hint!),
                ],
                if (_board.complete) ...[
                  const SizedBox(height: 16),
                  Text(
                    _saveError
                        ? copy.gmSaveError
                        : _saving
                        ? copy.savingLabel
                        : _board.helped
                        ? copy.gmAssisted
                        : _saved == true
                        ? copy.gmRecorded
                        : copy.gmAlreadyRecorded,
                    key: const ValueKey('matching-evidence-status'),
                  ),
                  if (_saveError)
                    TextButton(onPressed: _save, child: Text(copy.retryLabel)),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('matching-next'),
                    onPressed: _saving || _saveError
                        ? null
                        : () => setState(() {
                            if (_index + 1 ==
                                widget.game.matchingRounds.length) {
                              _replays++;
                            }
                            _index =
                                (_index + 1) %
                                widget.game.matchingRounds.length;
                            _newBoard();
                          }),
                    child: Text(
                      _index + 1 < widget.game.matchingRounds.length
                          ? copy.nextLabel
                          : copy.gmReplay,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _column(List<MatchingPair> pairs, bool left) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        left ? context.l10n.gmLeft : context.l10n.gmRight,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      for (final pair in pairs)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            selected: left && _board.selected == pair.id,
            child: OutlinedButton(
              key: ValueKey('matching-${left ? 'left' : 'right'}-${pair.id}'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(48, 56),
                padding: const EdgeInsets.all(12),
                backgroundColor: _board.matched.contains(pair.id)
                    ? const Color(0xFFEBF5EF)
                    : left && _board.selected == pair.id
                    ? const Color(0xFFEDEBFF)
                    : Colors.white,
                foregroundColor: IntelliaColors.textPrimary,
                disabledForegroundColor: IntelliaColors.textPrimary,
              ),
              onPressed: _board.matched.contains(pair.id) || _board.complete
                  ? null
                  : left
                  ? () => setState(() => _board.select(pair.id))
                  : _board.selected == null
                  ? null
                  : () => _link(pair),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_board.matched.contains(pair.id)) ...[
                    const Icon(Icons.check_rounded, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: Text(left ? pair.left : pair.right)),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
