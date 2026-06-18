import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/quiz_question.dart';
import 'question_card_shell.dart';

class TrueFalseQuestionCard extends StatelessWidget {
  const TrueFalseQuestionCard({
    required this.question,
    required this.selectedValue,
    required this.onSelected,
    super.key,
  });

  final QuizQuestion question;
  final bool? selectedValue;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return QuestionCardShell(
      title: question.prompt,
      subtitle: 'Vrai ou faux',
      child: Row(
        children: [
          Expanded(
            child: _ChoiceButton(
              label: 'Vrai',
              selected: selectedValue == true,
              onTap: () => onSelected(true),
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ChoiceButton(
              label: 'Faux',
              selected: selectedValue == false,
              onTap: () => onSelected(false),
              color: const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
          border: Border.all(
            color: selected
                ? color
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: selected ? color : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
