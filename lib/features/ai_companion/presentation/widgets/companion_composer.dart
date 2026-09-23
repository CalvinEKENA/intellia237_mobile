import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/tab_presentation.dart';

/// Composeur du compagnon : **écrire**.
///
/// Registre de décisions (V1, réduction des coûts) : la voix est retirée —
/// ni dictée, ni micro, ni lecture à voix haute. Le seul verbe à droite du
/// champ est « Envoyer », actif dès qu'un caractère utile est saisi.
///
/// « Montrer » n'est volontairement pas exposé tant que le tuteur ne sait pas
/// lire une image : offrir le geste sans la capacité reviendrait à promettre
/// une lecture qui n'aura pas lieu.
class CompanionComposer extends StatefulWidget {
  const CompanionComposer({
    required this.controller,
    required this.onSubmit,
    required this.enabled,
    required this.companionName,
    required this.accentColor,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool enabled;
  final String companionName;
  final Color accentColor;

  @override
  State<CompanionComposer> createState() => _CompanionComposerState();
}

class _CompanionComposerState extends State<CompanionComposer> {
  var _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final l10n = context.l10n;
    final enabled = widget.enabled;
    final canSend = enabled && _hasText;
    final accentColor = widget.accentColor;

    return Padding(
      padding: const EdgeInsets.only(top: IntelliaSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: IntelliaSpacing.md,
          vertical: IntelliaSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: s.fieldFill,
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          border: Border.all(color: s.surfaceBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (canSend) widget.onSubmit();
                },
                style: TextStyle(color: s.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.writeQuestionHint,
                  hintStyle: TextStyle(color: s.textTertiary, fontSize: 14),
                  border: InputBorder.none,
                  // Le thème remplit les champs d'un fond clair : sur la
                  // surface sombre du compagnon, le texte blanc y devenait
                  // invisible. Le champ écrit à même la surface.
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: IntelliaSpacing.sm),
            Semantics(
              button: true,
              enabled: canSend,
              label: l10n.companionSend,
              child: Tooltip(
                message: l10n.companionSend,
                child: InkResponse(
                  key: const ValueKey('companion-send'),
                  onTap: canSend ? widget.onSubmit : null,
                  radius: 26,
                  child: AnimatedContainer(
                    duration: IntelliaMotion.fast,
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: canSend ? accentColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: canSend
                            ? accentColor.withValues(alpha: 0)
                            : s.surfaceBorder,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: canSend ? Colors.white : s.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
