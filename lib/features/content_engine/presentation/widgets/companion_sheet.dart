import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../tutor/application/tutor_preference_provider.dart';
import '../../application/content_providers.dart';
import '../../domain/chapter.dart';
import '../../domain/companion_action.dart';
import '../../domain/question.dart';
import '../../engine/companion_engine.dart';
import '../content_style.dart';
import '../visuals/concept_visuals.dart';
import 'practice_panel.dart';

/// Libellé d'une action rapide du Compagnon : celui du pack d'abord (dans la
/// langue du contenu, ex. « Explain this »), sinon celui de l'application.
String companionActionLabel(
  BuildContext context,
  CompanionAction action, [
  Map<CompanionAction, String> packLabels = const {},
]) {
  final l10n = context.l10n;
  return packLabels[action] ??
      switch (action) {
        CompanionAction.explainStandard => l10n.ceActionExplain,
        CompanionAction.explainSimple => l10n.ceActionSimpler,
        CompanionAction.explainUltraSimple => l10n.ceActionUltra,
        CompanionAction.showMe => l10n.ceActionShow,
        CompanionAction.example => l10n.ceActionExample,
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
  String? _addressedName;
  CompanionMoment _moment = CompanionMoment.routine;
  int _examplesShown = 0;

  /// Moment de la conversation, pour décider (avec parcimonie) si le
  /// Compagnon appelle l'élève par son prénom.
  CompanionMoment _momentFor(
    CompanionAction? action,
    CompanionContext context,
  ) {
    if (action == CompanionAction.whyWrong &&
        (context.lastGrade?.correct == false) &&
        context.hintsShown + 1 >= 2) {
      return CompanionMoment.afterErrors;
    }
    if ((context.mastery ?? 0) >= 90 && action == CompanionAction.testMe) {
      return CompanionMoment.notableSuccess;
    }
    return CompanionMoment.routine;
  }

  void _address(CompanionAction? action, CompanionContext context) {
    final moment = _momentFor(action, context);
    final name = ref
        .read(companionNamePolicyProvider)
        .nameFor(moment, ref.read(authControllerProvider).firstName);
    _addressedName = name;
    _moment = name == null
        ? moment
        : (moment == CompanionMoment.routine
              ? CompanionMoment.firstInteraction
              : moment);
  }

  @override
  void dispose() {
    _ask.dispose();
    super.dispose();
  }

  void _act(CompanionAction action) {
    final base = widget.context();
    final context = CompanionContext(
      conceptId: base.conceptId,
      lessonNumber: base.lessonNumber,
      question: base.question,
      lastGrade: base.lastGrade,
      hintsShown: base.hintsShown,
      difficulty: base.difficulty,
      answered: base.answered,
      mastery: base.mastery,
      difficultyChosen: base.difficultyChosen,
      examplesShown: _examplesShown,
    );
    final reply = CompanionEngine(widget.chapter).respond(action, context);
    if (action == CompanionAction.hint && reply.answered) {
      widget.onHintShown?.call();
    }
    if (action == CompanionAction.example && reply.answered) _examplesShown++;
    _address(action, context);
    setState(() => _reply = reply);
  }

  void _submitQuestion() {
    final text = _ask.text.trim();
    if (text.isEmpty) return;
    final context = widget.context();
    _address(null, context);
    setState(
      () => _reply = CompanionEngine(
        widget.chapter,
      ).ask(text, contextConceptId: context.conceptId),
    );
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
                for (final action in widget.chapter.companion.effectiveActions)
                  ActionChip(
                    key: ValueKey('companion-action-${action.name}'),
                    avatar: Icon(_icon(action), size: 18),
                    label: Text(
                      companionActionLabel(
                        context,
                        action,
                        widget.chapter.companion.labels,
                      ),
                    ),
                    onPressed: () => _act(action),
                  ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            TextField(
              key: const ValueKey('companion-ask'),
              controller: _ask,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submitQuestion(),
              decoration: InputDecoration(
                hintText: l10n.ceAskHint,
                hintMaxLines: 6,
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
              if (_addressedName case final firstName?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    switch (_moment) {
                      CompanionMoment.afterErrors =>
                        l10n.ceCompanionNameAfterErrors(firstName),
                      CompanionMoment.notableSuccess =>
                        l10n.ceCompanionNameSuccess(firstName),
                      _ => l10n.ceCompanionNameHello(firstName),
                    },
                    key: const ValueKey('companion-name-line'),
                    style: ContentText.label(size: 14),
                  ),
                ),
              CompanionReplyCard(
                modeLabels: widget.chapter.explanationLabels,
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
    CompanionAction.example => Icons.format_list_numbered_rounded,
    CompanionAction.hint => Icons.lightbulb_outline_rounded,
    CompanionAction.testMe => Icons.quiz_outlined,
    CompanionAction.whyWrong => Icons.help_outline_rounded,
  };
}
