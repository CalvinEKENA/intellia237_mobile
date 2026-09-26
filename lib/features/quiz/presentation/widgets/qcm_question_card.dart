import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/academics/choice_order.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../domain/quiz_question.dart';

class QcmQuestionCard extends StatelessWidget {
  const QcmQuestionCard({
    required this.question,
    required this.selectedIndex,
    required this.onSelected,
    required this.attemptKey,
    super.key,
  });

  final QuizQuestion question;

  /// Index d'origine de la proposition choisie (jamais sa place à l'écran).
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  /// Tentative en cours : l'ordre affiché en dépend et ne bouge pas avant
  /// la fin de la tentative.
  final String attemptKey;

  static const _letters = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question prompt
        ClipRRect(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(IntelliaSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x22FFFFFF), Color(0x0EFFFFFF)],
                ),
                borderRadius: BorderRadius.circular(IntelliaRadii.medium),
                border: Border.all(color: IntelliaColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: IntelliaSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: IntelliaColors.brandIndigo.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      context.l10n.singleAnswerQcm,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: IntelliaColors.brandIndigo,
                      ),
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  Text(
                    question.prompt,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: IntelliaSpacing.lg),

        // Propositions mélangées : la lettre suit la place à l'écran, la
        // réponse transmise reste l'index d'origine.
        for (final (position, index) in choiceOrder(
          question.options.length,
          questionId: question.id,
          attemptKey: attemptKey,
        ).indexed) ...[
          _GlassPillOption(
            letter: position < _letters.length
                ? _letters[position]
                : '${position + 1}',
            label: question.options[index],
            selected: selectedIndex == index,
            onTap: () {
              HapticFeedback.mediumImpact();
              onSelected(index);
            },
            index: position,
          ),
          if (position < question.options.length - 1)
            const SizedBox(height: IntelliaSpacing.sm),
        ],
      ],
    );
  }
}

class _GlassPillOption extends StatelessWidget {
  const _GlassPillOption({
    required this.letter,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.index,
  });

  final String letter;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
          button: true,
          selected: selected,
          excludeSemantics: true,
          label: context.l10n.quizOptionA11y(
            letter,
            label,
            selected ? context.l10n.selectedA11y : '',
          ),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: IntelliaMotion.fast,
              curve: IntelliaMotion.emphasizedDecelerate,
              constraints: const BoxConstraints(minHeight: 80),
              transform: Matrix4.diagonal3Values(
                selected ? 1.02 : 1.0,
                selected ? 1.02 : 1.0,
                1.0,
              ),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(IntelliaRadii.medium),
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0x221451E1), Color(0x141451E1)],
                      )
                    : const LinearGradient(
                        colors: [Color(0x14FFFFFF), Color(0x0AFFFFFF)],
                      ),
                border: Border.all(
                  color: selected
                      ? IntelliaColors.brandIndigo
                      : Colors.white.withValues(alpha: 0.15),
                  width: selected ? 1.8 : 1.0,
                ),
                boxShadow: selected
                    ? AppShadows.glow(
                        IntelliaColors.brandIndigo,
                        intensity: 0.20,
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: IntelliaSpacing.md,
                  vertical: IntelliaSpacing.sm,
                ),
                child: Row(
                  children: [
                    // Letter badge
                    AnimatedContainer(
                      duration: IntelliaMotion.fast,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: selected ? AppGradients.heroNavy : null,
                        color: selected
                            ? null
                            : Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: IntelliaSpacing.md),

                    // Option text
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.80),
                          height: 1.4,
                        ),
                      ),
                    ),

                    // Check indicator
                    if (selected)
                      Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              gradient: AppGradients.heroNavy,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0.0, 0.0),
                            end: const Offset(1.0, 1.0),
                            duration: 200.ms,
                            curve: IntelliaMotion.spring,
                          )
                          .fadeIn(duration: 150.ms),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 100 + index * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.04, end: 0);
  }
}
