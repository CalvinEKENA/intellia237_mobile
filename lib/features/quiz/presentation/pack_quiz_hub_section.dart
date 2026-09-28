import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_companion_avatar.dart';
import '../../content_engine/application/subject_journey.dart';
import '../../content_engine/presentation/content_style.dart';
import '../../content_engine/presentation/learning_cards.dart';
import '../../content_engine/presentation/subject_identity.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../application/pack_quiz_providers.dart';
import '../application/pack_quiz_session.dart';
import '../domain/pack_quiz.dart';

/// Libellé d'un mode de quiz de pack.
String packQuizModeLabel(BuildContext context, PackQuizMode mode) =>
    switch (mode) {
      PackQuizMode.training => context.l10n.quizPackTraining,
      PackQuizMode.evaluation => context.l10n.quizPackEvaluation,
    };

/// Les quiz tirés des cours de la classe : par matière, par séquence, et la
/// révision mixte. Tout est sur l'appareil ; rien n'attend le réseau.
class PackQuizHubSection extends ConsumerWidget {
  const PackQuizHubSection({super.key});

  static const sectionKey = ValueKey('pack-quiz-section');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(packQuizCatalogProvider).valueOrNull;
    if (catalog == null || catalog.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final companion = ref.watch(quizCompanionProvider);
    final journeys = {
      for (final journey
          in ref.watch(subjectJourneysProvider).valueOrNull ??
              const <SubjectJourney>[])
        for (final chapter in journey.chapters) chapter.contentId: chapter,
    };
    final history =
        ref.watch(packQuizHistoryProvider).valueOrNull ??
        const <PackQuizHistoryEntry>[];
    final ink = Theme.of(context).colorScheme.onSurface;
    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.quizPackSectionTitle,
            style: ContentText.title(color: ink, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.quizPackSectionSubtitle,
          style: ContentText.body(
            color: ink.withValues(alpha: 0.72),
            size: 13.5,
          ),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        _CompanionLine(persona: companion),
        for (final subject in catalog.subjects) ...[
          const SizedBox(height: IntelliaSpacing.md),
          PackQuizSubjectCard(
            subject: subject,
            companion: companion,
            chapters: journeys,
          ),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.lg),
          _RecentSessions(history: history.take(5).toList()),
        ],
        const SizedBox(height: IntelliaSpacing.lg),
      ],
    );
  }
}

class _CompanionLine extends StatelessWidget {
  const _CompanionLine({required this.persona});

  final TutorPersona persona;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IntelliaCompanionAvatar(
        variant: persona.id == 'leo'
            ? CompanionVariant.leo
            : CompanionVariant.kira,
        size: CompanionSize.small,
      ),
      const SizedBox(width: IntelliaSpacing.xs),
      Expanded(
        child: Text(
          context.l10n.quizPackCompanionWith(persona.name),
          key: const ValueKey('pack-quiz-companion'),
          style: ContentText.label(color: persona.accentColor, size: 14),
        ),
      ),
    ],
  );
}

/// Une matière et ses quiz : le nombre réel de questions, la progression
/// de la matière, la révision mixte et chaque séquence dans ses deux modes.
class PackQuizSubjectCard extends StatelessWidget {
  const PackQuizSubjectCard({
    required this.subject,
    required this.companion,
    this.chapters = const {},
    super.key,
  });

  final PackQuizSubject subject;
  final TutorPersona companion;

  /// Parcours des séquences (notion à consolider), par identifiant.
  final Map<String, ChapterJourney> chapters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final identity = SubjectVisualIdentity.of(subject.key);
    final palette = identity.palette(learningBrightness(context));
    final name = subjectDisplayName(context, subject.key, subject.title);
    return LearningSurface(
      key: ValueKey('pack-quiz-subject-${subject.key}'),
      palette: palette,
      identity: identity,
      showMotif: true,
      padding: const EdgeInsets.all(IntelliaSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubjectBadge(identity: identity, palette: palette, size: 44),
              const SizedBox(width: IntelliaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: ContentText.title(
                        color: palette.textPrimary,
                        size: 21,
                      ),
                    ),
                    Text(
                      [
                        if (subject.levelLabel.isNotEmpty) subject.levelLabel,
                        l10n.quizPackQuestionCount(subject.questionCount),
                      ].join(' · '),
                      style: ContentText.body(
                        color: palette.textSecondary,
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: JourneyProgressBar(
                  value: subject.progress,
                  palette: palette,
                ),
              ),
              const SizedBox(width: IntelliaSpacing.sm),
              Text(
                l10n.ljProgressPercent((subject.progress * 100).round()),
                style: ContentText.label(color: palette.accent, size: 13),
              ),
            ],
          ),
          if (subject.mixed case final mixed?) ...[
            const SizedBox(height: IntelliaSpacing.md),
            _QuizSetRow(
              set: mixed,
              palette: palette,
              eyebrow: l10n.quizPackMixed,
              title: l10n.quizPackMixedBody,
            ),
          ],
          const SizedBox(height: IntelliaSpacing.md),
          Text(
            l10n.quizPackSequencesTitle.toUpperCase(),
            style: ContentText.eyebrow(color: palette.accent),
          ),
          for (final set in subject.sequences) ...[
            const SizedBox(height: IntelliaSpacing.xs),
            _QuizSetRow(
              set: set,
              palette: palette,
              eyebrow: set.curriculum == null
                  ? null
                  : positionLabel(context, set.curriculum!),
              title: set.title,
              focus: _focusText(context, chapters[set.contentId]),
            ),
          ],
        ],
      ),
    );
  }

  /// La notion à travailler en premier, d'après la maîtrise réelle.
  static String? _focusText(BuildContext context, ChapterJourney? chapter) {
    if (chapter == null) return null;
    final l10n = context.l10n;
    final focus = chapter.focus;
    if (focus == null) return l10n.ljPracticeAllMastered;
    return chapter.focusStarted
        ? l10n.ljPracticeFocus(focus.title)
        : l10n.ljPracticeFirst(focus.title);
  }
}

class _QuizSetRow extends StatelessWidget {
  const _QuizSetRow({
    required this.set,
    required this.palette,
    required this.title,
    this.eyebrow,
    this.focus,
  });

  final PackQuizSet set;
  final SubjectPalette palette;
  final String? eyebrow;
  final String title;
  final String? focus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: ValueKey('pack-quiz-set-${set.id}'),
      padding: const EdgeInsets.all(IntelliaSpacing.sm),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: palette.isDark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eyebrow case final text?)
            Text(
              text.toUpperCase(),
              style: ContentText.eyebrow(color: palette.accent),
            ),
          Text(
            title,
            style: ContentText.label(color: palette.textPrimary, size: 15),
          ),
          Text(
            l10n.quizPackQuestionCount(set.questionCount),
            style: ContentText.body(color: palette.textSecondary, size: 12.5),
          ),
          if (focus case final text?)
            Text(
              text,
              style: ContentText.body(
                color: palette.textSecondary,
                size: 12.5,
                weight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: IntelliaSpacing.xs),
          Wrap(
            spacing: IntelliaSpacing.xs,
            runSpacing: IntelliaSpacing.xs,
            children: [
              for (final mode in PackQuizMode.values)
                _ModeButton(set: set, mode: mode, palette: palette),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.set,
    required this.mode,
    required this.palette,
  });

  final PackQuizSet set;
  final PackQuizMode mode;
  final SubjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final label = packQuizModeLabel(context, mode);
    void open() => context.push(AppRoutes.packQuiz(set.id, mode.name));
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: IntelliaSpacing.md),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
      textStyle: WidgetStatePropertyAll(
        ContentText.label(size: 14, color: palette.accent),
      ),
    );
    final key = ValueKey('pack-quiz-start-${set.id}-${mode.name}');
    return mode == PackQuizMode.training
        ? FilledButton.icon(
            key: key,
            onPressed: open,
            style: style.copyWith(
              backgroundColor: WidgetStatePropertyAll(palette.accent),
              foregroundColor: WidgetStatePropertyAll(
                palette.isDark ? const Color(0xFF111827) : Colors.white,
              ),
            ),
            icon: const Icon(Icons.school_rounded, size: 18),
            label: Text(label),
          )
        : OutlinedButton.icon(
            key: key,
            onPressed: open,
            style: style.copyWith(
              foregroundColor: WidgetStatePropertyAll(palette.accent),
              side: WidgetStatePropertyAll(BorderSide(color: palette.accent)),
            ),
            icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
            label: Text(label),
          );
  }
}

class _RecentSessions extends StatelessWidget {
  const _RecentSessions({required this.history});

  final List<PackQuizHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ink = Theme.of(context).colorScheme.onSurface;
    final dates = MaterialLocalizations.of(context);
    return Column(
      key: const ValueKey('pack-quiz-recent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.quizPackRecentTitle,
          style: ContentText.label(color: ink, size: 16),
        ),
        for (final entry in history)
          Padding(
            padding: const EdgeInsets.only(top: IntelliaSpacing.xs),
            child: Text(
              '${l10n.quizPackRecentRow(entry.title, packQuizModeLabel(context, entry.mode), entry.score, entry.total)}'
              ' · ${dates.formatShortDate(entry.completedAt.toLocal())}',
              style: ContentText.body(
                color: ink.withValues(alpha: 0.78),
                size: 13.5,
              ),
            ),
          ),
      ],
    );
  }
}
