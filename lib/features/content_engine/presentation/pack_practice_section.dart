import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/subject_journey.dart';
import 'content_style.dart';
import 'learning_cards.dart';
import 'subject_identity.dart';

/// « S'entraîner » : les exercices corrigés des packs de la classe, par
/// matière puis par séquence, avec la notion à consolider.
///
/// Hors ligne comme en ligne ; invisible sans pack pour la classe.
class PackPracticeSection extends ConsumerWidget {
  const PackPracticeSection({super.key});

  static const sectionKey = ValueKey('pack-practice-section');

  /// Étape « S'entraîner » d'une leçon (0 comprendre … 4 formaliser).
  static const practiceStep = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeys = ref.watch(subjectJourneysProvider).valueOrNull;
    final practised = [
      for (final journey in journeys ?? const <SubjectJourney>[])
        (
          journey,
          [
            for (final chapter in journey.chapters)
              if (chapter.scoredQuestions > 0) chapter,
          ],
        ),
    ].where((entry) => entry.$2.isNotEmpty).toList();
    if (practised.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final brightness = learningBrightness(context);
    final neutral = SubjectVisualIdentity.of(
      practised.first.$1.key,
    ).palette(brightness);
    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.ljPracticeTitle,
            style: ContentText.title(color: neutral.textPrimary, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.ljPracticeSubtitle,
          style: ContentText.body(color: neutral.textSecondary, size: 13.5),
        ),
        for (final (journey, chapters) in practised) ...[
          const SizedBox(height: IntelliaSpacing.md),
          _SubjectLine(journey: journey, brightness: brightness),
          for (final chapter in chapters)
            Padding(
              padding: const EdgeInsets.only(top: IntelliaSpacing.sm),
              child: PracticeSequenceCard(
                journey: chapter,
                onTap: () {
                  ref
                      .read(learningRecentsProvider.notifier)
                      .visited(journey.key, chapter.contentId);
                  context.push(
                    AppRoutes.contentLesson(
                      chapter.contentId,
                      chapter.focusLesson ??
                          chapter.chapter.lessons.first.number,
                      step: practiceStep,
                    ),
                  );
                },
              ),
            ),
        ],
        const SizedBox(height: IntelliaSpacing.lg),
      ],
    );
  }
}

class _SubjectLine extends StatelessWidget {
  const _SubjectLine({required this.journey, required this.brightness});

  final SubjectJourney journey;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final identity = SubjectVisualIdentity.of(journey.key);
    final palette = identity.palette(brightness);
    return Row(
      key: ValueKey('practice-subject-${journey.key}'),
      children: [
        SubjectBadge(identity: identity, palette: palette, size: 30),
        const SizedBox(width: IntelliaSpacing.sm),
        Expanded(
          child: Text(
            subjectDisplayName(
              context,
              journey.subject.key,
              journey.subject.title,
            ),
            style: ContentText.label(color: palette.accent, size: 15),
          ),
        ),
      ],
    );
  }
}
