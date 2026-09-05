import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../domain/quiz_question.dart';
import 'question_card_shell.dart';

class ShortAnswerQuestionCard extends StatelessWidget {
  const ShortAnswerQuestionCard({
    required this.question,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final QuizQuestion question;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return QuestionCardShell(
      title: question.prompt,
      subtitle: context.l10n.shortAnswerInstruction,
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(hintText: context.l10n.yourAnswerHint),
      ),
    );
  }
}
