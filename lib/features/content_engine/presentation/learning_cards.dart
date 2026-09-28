import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_pressable.dart';
import '../application/subject_journey.dart';
import '../domain/chapter.dart';
import 'content_style.dart';
import 'subject_identity.dart';

/// Rayon des cartes d'apprentissage : généreux, jamais anguleux.
const kLearningCardRadius = 26.0;

/// Surface premium commune : fond net, voile très léger de la matière,
/// profondeur à peine perceptible en clair et aucune ombre en sombre.
class LearningSurface extends StatelessWidget {
  const LearningSurface({
    required this.palette,
    required this.child,
    this.identity,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(IntelliaSpacing.lg),
    this.showMotif = false,
    super.key,
  });

  final SubjectPalette palette;
  final SubjectVisualIdentity? identity;
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final bool showMotif;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kLearningCardRadius);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: radius,
        border: Border.all(color: palette.border),
        boxShadow: palette.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0B0F172A),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.tint, palette.tint.withValues(alpha: 0)],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
            if (showMotif && identity != null)
              Positioned(
                top: 0,
                right: 0,
                width: 170,
                height: 120,
                child: SubjectMotifBackdrop(
                  identity: identity!,
                  palette: palette,
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IntelliaPressable(onTap: onTap, scaleFactor: 0.985, child: card),
    );
  }
}

/// Barre de progression fine, aux extrémités arrondies.
class JourneyProgressBar extends StatelessWidget {
  const JourneyProgressBar({
    required this.value,
    required this.palette,
    this.height = 6,
    super.key,
  });

  final double value;
  final SubjectPalette palette;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    value: '${(value * 100).round()} %',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            backgroundColor: palette.track,
            valueColor: AlwaysStoppedAnimation(palette.accent),
          ),
        ),
      ),
    ),
  );
}

/// Libellé d'un état de parcours.
String journeyStatusLabel(BuildContext context, JourneyStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    JourneyStatus.notStarted => l10n.ljStatusNotStarted,
    JourneyStatus.inProgress => l10n.ljStatusInProgress,
    JourneyStatus.completed => l10n.ljStatusCompleted,
    JourneyStatus.toReview => l10n.ljStatusToReview,
  };
}

/// Pastille d'état : un point de couleur et un mot, jamais la couleur seule.
class JourneyStatusChip extends StatelessWidget {
  const JourneyStatusChip({
    required this.status,
    required this.palette,
    super.key,
  });

  final JourneyStatus status;
  final SubjectPalette palette;

  Color get _color => switch (status) {
    JourneyStatus.notStarted => palette.textSecondary,
    JourneyStatus.inProgress => palette.accent,
    JourneyStatus.completed =>
      palette.isDark ? const Color(0xFF7FD6A4) : const Color(0xFF1E7A4F),
    JourneyStatus.toReview =>
      palette.isDark ? const Color(0xFFF2C46B) : const Color(0xFF94600A),
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      key: ValueKey('journey-status-${status.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              journeyStatusLabel(context, status),
              style: ContentText.label(color: color, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille d'icône de la matière.
class SubjectBadge extends StatelessWidget {
  const SubjectBadge({
    required this.identity,
    required this.palette,
    this.size = 48,
    super.key,
  });

  final SubjectVisualIdentity identity;
  final SubjectPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: palette.accent.withValues(alpha: palette.isDark ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(size * 0.34),
    ),
    alignment: Alignment.center,
    child: Icon(identity.icon, color: palette.accent, size: size * 0.52),
  );
}

/// « 2 séquences », « 2 units » ou « 3 chapitres », selon le programme.
String subjectPartsLabel(BuildContext context, Subject subject) {
  final l10n = context.l10n;
  final count = subject.chapters.length;
  final first = subject.chapters.firstOrNull?.curriculum;
  if (first?.isSequence ?? false) return l10n.ljSequenceCount(count);
  if (first?.isUnit ?? false) return l10n.ljUnitCount(count);
  return l10n.ljChapterCount(count);
}

/// Une matière de la classe, dans Apprendre.
class SubjectCard extends StatelessWidget {
  const SubjectCard({required this.journey, required this.onTap, super.key});

  final SubjectJourney journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final identity = SubjectVisualIdentity.of(journey.key);
    final palette = identity.palette(learningBrightness(context));
    final subject = journey.subject;
    final name = subjectDisplayName(context, subject.key, subject.title);
    final progress = journey.progress;
    final last = journey.lastVisited;
    return LearningSurface(
      key: ValueKey('subject-card-${journey.key}'),
      palette: palette,
      identity: identity,
      showMotif: true,
      semanticLabel: l10n.ljOpenSubject(name),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubjectBadge(identity: identity, palette: palette),
              const Spacer(),
              Text(
                l10n.ljProgressPercent(progress.percent),
                style: ContentText.math(color: palette.accent, size: 22),
              ),
            ],
          ),
          const SizedBox(height: IntelliaSpacing.md),
          Text(
            name,
            style: ContentText.title(color: palette.textPrimary, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            [
              subject.levelLabel,
              subjectPartsLabel(context, subject),
              l10n.ceLessonCount(journey.lessonCount),
            ].where((part) => part.isNotEmpty).join(' · '),
            style: ContentText.body(color: palette.textSecondary, size: 13.5),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          JourneyProgressBar(value: progress.progress, palette: palette),
          const SizedBox(height: IntelliaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ljConceptsMastered(progress.mastered, progress.total),
                  style: ContentText.body(
                    color: palette.textSecondary,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              // L'appel est implicite : toute la carte ouvre la matière.
              Icon(
                Icons.arrow_forward_rounded,
                color: palette.accent,
                size: 20,
              ),
            ],
          ),
          if (last != null) ...[
            const SizedBox(height: IntelliaSpacing.md),
            Divider(height: 1, color: palette.border),
            const SizedBox(height: IntelliaSpacing.sm),
            Row(
              key: ValueKey('subject-resume-${journey.key}'),
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: palette.accent,
                  size: 20,
                ),
                const SizedBox(width: IntelliaSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.ljResume(last.entry.curriculum.chapterTitle),
                    style: ContentText.label(color: palette.accent, size: 13.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Une séquence (ou unit, ou chapitre) dans l'écran de la matière.
class SequenceCard extends StatelessWidget {
  const SequenceCard({
    required this.journey,
    required this.onTap,
    this.lastVisited = false,
    super.key,
  });

  final ChapterJourney journey;
  final VoidCallback onTap;
  final bool lastVisited;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final curriculum = journey.entry.curriculum;
    final identity = SubjectVisualIdentity.of(curriculum.subjectKey);
    final palette = identity.palette(learningBrightness(context));
    final progress = journey.progress;
    return LearningSurface(
      key: ValueKey('local-chapter-${journey.contentId}'),
      palette: palette,
      identity: identity,
      semanticLabel: curriculum.chapterTitle,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(
                    alpha: palette.isDark ? 0.2 : 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${curriculum.chapterNumber}',
                  style: ContentText.math(color: palette.accent, size: 18),
                ),
              ),
              const SizedBox(width: IntelliaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      positionLabel(context, curriculum).toUpperCase(),
                      style: ContentText.eyebrow(color: palette.accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      curriculum.chapterTitle,
                      style: ContentText.title(
                        color: palette.textPrimary,
                        size: 20,
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              JourneyStatusChip(status: progress.status, palette: palette),
              Text(
                l10n.ceLessonCount(journey.entry.lessonCount),
                style: ContentText.body(
                  color: palette.textSecondary,
                  size: 13,
                  weight: FontWeight.w600,
                ),
              ),
              if (lastVisited)
                Text(
                  '· ${l10n.ljLastVisited}',
                  key: const ValueKey('sequence-last-visited'),
                  style: ContentText.body(
                    color: palette.textSecondary,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: JourneyProgressBar(
                  value: progress.progress,
                  palette: palette,
                ),
              ),
              const SizedBox(width: IntelliaSpacing.sm),
              Text(
                l10n.ljProgressPercent(progress.percent),
                style: ContentText.label(color: palette.accent, size: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Une leçon d'une séquence : numéro, notions, maîtrise et état.
class LessonCard extends StatelessWidget {
  const LessonCard({
    required this.chapter,
    required this.journey,
    required this.unlocked,
    required this.onTap,
    super.key,
  });

  final Chapter chapter;
  final LessonJourney journey;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final identity = SubjectVisualIdentity.of(chapter.curriculum.subjectKey);
    final palette = identity.palette(learningBrightness(context));
    final lesson = journey.lesson;
    final progress = journey.progress;
    final concepts = [
      for (final concept in chapter.conceptsForLesson(lesson.number))
        if (concept.title != lesson.title) concept.title,
    ];
    return LearningSurface(
      key: ValueKey('content-lesson-${lesson.number}'),
      palette: palette,
      semanticLabel: '${l10n.ceLessonLabel(lesson.number)}, ${lesson.title}',
      padding: const EdgeInsets.all(IntelliaSpacing.md + 2),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MasteryRing(
            score: progress.percent,
            color: unlocked ? palette.accent : palette.textSecondary,
            child: unlocked
                ? Text(
                    '${lesson.number}',
                    style: ContentText.math(
                      color: palette.textPrimary,
                      size: 16,
                    ),
                  )
                : Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: palette.textSecondary,
                  ),
          ),
          const SizedBox(width: IntelliaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ceLessonLabel(lesson.number).toUpperCase(),
                  style: ContentText.eyebrow(color: palette.accent),
                ),
                const SizedBox(height: 3),
                Text(
                  lesson.title,
                  style: ContentText.label(
                    color: palette.textPrimary,
                    size: 16,
                  ),
                ),
                if (concepts.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    concepts.join(' · '),
                    style: ContentText.body(
                      color: palette.textSecondary,
                      size: 13,
                    ),
                  ),
                ],
                const SizedBox(height: IntelliaSpacing.sm),
                Wrap(
                  spacing: IntelliaSpacing.xs,
                  runSpacing: IntelliaSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    JourneyStatusChip(
                      status: progress.status,
                      palette: palette,
                    ),
                    Text(
                      unlocked
                          ? l10n.ceMasteryPercent(progress.percent)
                          : l10n.ceLessonRecommendedAfter(
                              chapter.mastery.unlockNextLessonAt,
                            ),
                      style: ContentText.body(
                        color: palette.textSecondary,
                        size: 12.5,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
        ],
      ),
    );
  }
}

/// La synthèse d'une séquence (`lesson: 0`) : jamais « Leçon 0 ».
class SynthesisCard extends StatelessWidget {
  const SynthesisCard({
    required this.chapter,
    required this.title,
    required this.onTap,
    super.key,
  });

  final Chapter chapter;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final identity = SubjectVisualIdentity.of(chapter.curriculum.subjectKey);
    final dark = learningBrightness(context) == Brightness.dark;
    // Une surface d'encre, même en clair : la synthèse se distingue des
    // leçons sans couleur criarde.
    final palette = identity.palette(Brightness.dark);
    return LearningSurface(
      key: const ValueKey('content-integration-entry'),
      palette: SubjectPalette(
        brightness: Brightness.dark,
        accent: palette.accent,
        tint: palette.tint,
        surface: dark ? const Color(0xFF26262B) : const Color(0xFF14161F),
        border: palette.border,
        textPrimary: palette.textPrimary,
        textSecondary: palette.textSecondary,
        track: palette.track,
      ),
      identity: identity,
      showMotif: true,
      semanticLabel: title,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: IntelliaFlag.yellowOnInk.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_mosaic_rounded,
              color: IntelliaFlag.yellowOnInk,
            ),
          ),
          const SizedBox(width: IntelliaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ContentText.title(color: Colors.white, size: 21),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.ceIntegrationBody,
                  style: ContentText.body(
                    color: Colors.white.withValues(alpha: 0.78),
                    size: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: IntelliaSpacing.xs),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

/// Une séquence dans « S'entraîner » : pratiquer, consolider, se tester.
///
/// Volontairement différente de la carte d'Apprendre : une jauge
/// d'exercices faits, la notion à consolider et un appel à l'action.
class PracticeSequenceCard extends StatelessWidget {
  const PracticeSequenceCard({
    required this.journey,
    required this.onTap,
    super.key,
  });

  final ChapterJourney journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final curriculum = journey.entry.curriculum;
    final identity = SubjectVisualIdentity.of(curriculum.subjectKey);
    final palette = identity.palette(learningBrightness(context));
    final total = journey.scoredQuestions;
    final done = journey.answeredScored;
    final ratio = total == 0 ? 0.0 : done / total;
    final focus = journey.focus;
    final focusText = focus == null
        ? l10n.ljPracticeAllMastered
        : journey.focusStarted
        ? l10n.ljPracticeFocus(focus.title)
        : l10n.ljPracticeFirst(focus.title);
    return LearningSurface(
      key: ValueKey('practice-${journey.contentId}'),
      palette: palette,
      semanticLabel: '${l10n.ljPracticeGo}, ${curriculum.chapterTitle}',
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Le rail de la matière : l'identité sans aplat.
            Container(width: 5, color: palette.accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(IntelliaSpacing.md + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: ratio,
                                  strokeWidth: 4,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: palette.track,
                                  valueColor: AlwaysStoppedAnimation(
                                    palette.accent,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.track_changes_rounded,
                                color: palette.accent,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: IntelliaSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                positionLabel(
                                  context,
                                  curriculum,
                                ).toUpperCase(),
                                style: ContentText.eyebrow(
                                  color: palette.accent,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                curriculum.chapterTitle,
                                style: ContentText.label(
                                  color: palette.textPrimary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                [
                                  l10n.ljPracticeExercises(total),
                                  l10n.ljPracticeDone(done, total),
                                ].join(' · '),
                                style: ContentText.body(
                                  color: palette.textSecondary,
                                  size: 12.5,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: IntelliaSpacing.sm),
                    Wrap(
                      spacing: IntelliaSpacing.xs,
                      runSpacing: IntelliaSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        JourneyStatusChip(
                          status: journey.progress.status,
                          palette: palette,
                        ),
                        Text(
                          focusText,
                          key: const ValueKey('practice-focus'),
                          style: ContentText.body(
                            color: palette.textPrimary,
                            size: 13,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: IntelliaSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.ljPracticeGo,
                            textAlign: TextAlign.end,
                            style: ContentText.label(
                              color: palette.accent,
                              size: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: palette.accent,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
