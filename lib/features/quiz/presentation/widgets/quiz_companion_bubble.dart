import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/intellia_companion_avatar.dart';
import '../../../content_engine/presentation/content_style.dart';
import '../../../tutor/domain/tutor_persona.dart';
import '../../domain/quiz_companion_narrator.dart';
import '../quiz_narration_text.dart';

/// Kira ou Léo, en une ligne : un avatar et une bulle courte au-dessus de
/// la question. Une présence, jamais une conversation.
class QuizCompanionBubble extends StatelessWidget {
  const QuizCompanionBubble({
    required this.persona,
    required this.narration,
    this.detail,
    super.key,
  });

  static const bubbleKey = ValueKey('quiz-companion-line');

  final TutorPersona persona;
  final QuizNarration narration;

  /// Texte du pack montré avec la réplique (un indice), jamais écrit par
  /// le compagnon.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final line = quizNarrationText(l10n, narration);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.quizPackCompanionA11y(persona.name, line),
      child: ExcludeSemantics(
        child: Row(
          key: bubbleKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntelliaCompanionAvatar(
              variant: persona.id == 'leo'
                  ? CompanionVariant.leo
                  : CompanionVariant.kira,
              size: CompanionSize.small,
            ),
            const SizedBox(width: IntelliaSpacing.xs),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: IntelliaSpacing.sm,
                  vertical: IntelliaSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: persona.accentColor.withValues(
                    alpha: dark ? 0.22 : 0.09,
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    topLeft: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line,
                      style: ContentText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: dark ? Colors.white : ContentPalette.ink,
                      ),
                    ),
                    if (detail case final text?) ...[
                      const SizedBox(height: 4),
                      Text(
                        text,
                        key: const ValueKey('quiz-companion-detail'),
                        style: ContentText.body(
                          size: 14,
                          color: dark
                              ? Colors.white.withValues(alpha: 0.85)
                              : ContentPalette.inkSoft,
                        ),
                      ),
                    ],
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
