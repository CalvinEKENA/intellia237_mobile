import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../application/content_providers.dart';
import '../application/practice_session.dart';
import '../domain/chapter.dart';
import '../domain/mastery.dart';
import 'content_style.dart';
import 'widgets/practice_panel.dart';

/// Défis d'intégration : les situations complètes du chapitre.
class ContentIntegrationScreen extends ConsumerWidget {
  const ContentIntegrationScreen({required this.contentId, super.key});

  final String contentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync = ref.watch(contentChapterProvider(contentId));
    return Scaffold(
      backgroundColor: ContentPalette.paper,
      appBar: AppBar(
        backgroundColor: ContentPalette.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ContentPalette.ink,
        title: Text(
          context.l10n.ceIntegrationTitle,
          style: ContentText.label(size: 17),
        ),
      ),
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          child: IntelliaStateView(
            kind: IntelliaStateKind.comingSoon,
            title: context.l10n.ceUnavailableTitle,
            message: context.l10n.ceLoadError,
          ),
        ),
        data: (chapter) => chapter.isPlayable
            ? _IntegrationBody(chapter: chapter)
            : Padding(
                padding: const EdgeInsets.all(IntelliaSpacing.lg),
                child: IntelliaStateView(
                  kind: IntelliaStateKind.comingSoon,
                  title: context.l10n.ceUnavailableTitle,
                  message: context.l10n.ceUnavailableBody,
                ),
              ),
      ),
    );
  }
}

class _IntegrationBody extends ConsumerStatefulWidget {
  const _IntegrationBody({required this.chapter});
  final Chapter chapter;

  @override
  ConsumerState<_IntegrationBody> createState() => _IntegrationBodyState();
}

class _IntegrationBodyState extends ConsumerState<_IntegrationBody> {
  late final PracticeSession _session = PracticeSession(
    chapter: widget.chapter,
    lessonNumber: 0,
    questionsOverride: widget.chapter.integrationQuestions,
    recorder: (question, correct) => ref
        .read(learnerContentControllerProvider.notifier)
        .recordAnswer(
          chapter: widget.chapter,
          question: question,
          correct: correct,
        ),
  );

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preference =
        (ref.watch(learnerContentControllerProvider).valueOrNull ??
                LearnerContentSnapshot.empty)
            .preference;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.sm,
        IntelliaSpacing.lg,
        IntelliaSpacing.xxl,
      ),
      children: [
        Text(
          context.l10n.ceIntegrationBody,
          style: ContentText.body(color: ContentPalette.inkSoft),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        PracticePanel(
          session: _session,
          preference: preference,
          showDifficulty: false,
          onAcceptExplanation: (mode) => ref
              .read(learnerContentControllerProvider.notifier)
              .chooseExplanation(mode, chapter: widget.chapter),
        ),
      ],
    );
  }
}
