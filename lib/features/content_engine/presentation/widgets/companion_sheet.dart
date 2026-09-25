import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../tutor/application/tutor_preference_provider.dart';
import '../../domain/chapter.dart';
import '../../domain/companion_action.dart';
import '../../domain/question.dart';
import '../../engine/companion_engine.dart';
import '../content_style.dart';
import '../visuals/concept_visuals.dart';
import 'practice_panel.dart';

/// Libellé d'une action rapide du Compagnon.
String companionActionLabel(BuildContext context, CompanionAction action) {
  final l10n = context.l10n;
  return switch (action) {
    CompanionAction.explainStandard => l10n.ceActionExplain,
    CompanionAction.explainSimple => l10n.ceActionSimpler,
    CompanionAction.explainUltraSimple => l10n.ceActionUltra,
    CompanionAction.showMe => l10n.ceActionShow,
    CompanionAction.hint => l10n.ceActionHint,
    CompanionAction.testMe => l10n.ceActionTest,
    CompanionAction.whyWrong => l10n.ceActionWhyWrong,
  };
}

/// Le Compagnon hors ligne : il répond avec le cours, rien d'autre.
class CompanionSheet extends ConsumerStatefulWidget {
  const CompanionSheet({
    required this.chapter,
    required this.context,
    this.onHintShown,
    this.onTryQuestion,
    super.key,
  });

  final Chapter chapter;
  final CompanionContext Function() context;
  final VoidCallback? onHintShown;
  final ValueChanged<Question>? onTryQuestion;

  static Future<void> show(
    BuildContext context, {
    required Chapter chapter,
    required CompanionContext Function() companionContext,
    VoidCallback? onHintShown,
    ValueChanged<Question>? onTryQuestion,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ContentPalette.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(IntelliaRadii.sheet),
      ),
    ),
    builder: (_) => CompanionSheet(
      chapter: chapter,
      context: companionContext,
      onHintShown: onHintShown,
      onTryQuestion: onTryQuestion,
    ),
  );

  @override
  ConsumerState<CompanionSheet> createState() => _CompanionSheetState();
}

class _CompanionSheetState extends ConsumerState<CompanionSheet> {
  final _ask = TextEditingController();
  CompanionReply? _reply;

  @override
  void dispose() {
    _ask.dispose();
    super.dispose();
  }

  void _act(CompanionAction action) {
    final reply = CompanionEngine(
      widget.chapter,
    ).respond(action, widget.context());
    if (action == CompanionAction.hint && reply.answered) {
      widget.onHintShown?.call();
    }
    setState(() => _reply = reply);
  }

  void _submitQuestion() {
    final text = _ask.text.trim();
    if (text.isEmpty) return;
    setState(() => _reply = CompanionEngine(widget.chapter).ask(text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tutor = ref.watch(selectedTutorProvider);
    final name = tutor?.name ?? 'Kira';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            IntelliaSpacing.sm,
            IntelliaSpacing.lg,
            IntelliaSpacing.xl,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ContentPalette.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: IntelliaSpacing.md),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: ContentPalette.accent.withValues(
                    alpha: 0.12,
                  ),
                  backgroundImage: tutor == null
                      ? null
                      : AssetImage(tutor.imagePath),
                ),
                const SizedBox(width: IntelliaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.ceCompanionTitle(name),
                        style: ContentText.title(size: 20),
                      ),
                      Text(
                        l10n.ceCompanionOffline,
                        style: ContentText.body(
                          color: ContentPalette.inkSoft,
                          size: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            Wrap(
              spacing: IntelliaSpacing.xs,
              runSpacing: IntelliaSpacing.xs,
              children: [
                for (final action in widget.chapter.companion.actions)
                  ActionChip(
                    key: ValueKey('companion-action-${action.name}'),
                    avatar: Icon(_icon(action), size: 18),
                    label: Text(companionActionLabel(context, action)),
                    onPressed: () => _act(action),
                  ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            TextField(
              key: const ValueKey('companion-ask'),
              controller: _ask,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submitQuestion(),
              decoration: InputDecoration(
                hintText: l10n.ceAskHint,
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  tooltip: l10n.ceAskSend,
                  onPressed: _submitQuestion,
                  icon: const Icon(Icons.send_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(IntelliaRadii.medium),
                ),
              ),
            ),
            if (_reply case final reply?) ...[
              const SizedBox(height: IntelliaSpacing.md),
              CompanionReplyCard(
                reply: reply,
                onTryQuestion: widget.onTryQuestion == null
                    ? null
                    : (question) {
                        Navigator.of(context).pop();
                        widget.onTryQuestion!(question);
                      },
              ),
              if (reply.visual case final kind
                  when ConceptVisual.supports(kind)) ...[
                const SizedBox(height: IntelliaSpacing.md),
                ContentCard(child: ConceptVisual(kind: kind)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  IconData _icon(CompanionAction action) => switch (action) {
    CompanionAction.explainStandard => Icons.menu_book_rounded,
    CompanionAction.explainSimple => Icons.short_text_rounded,
    CompanionAction.explainUltraSimple => Icons.child_care_rounded,
    CompanionAction.showMe => Icons.visibility_rounded,
    CompanionAction.hint => Icons.lightbulb_outline_rounded,
    CompanionAction.testMe => Icons.quiz_outlined,
    CompanionAction.whyWrong => Icons.help_outline_rounded,
  };
}
