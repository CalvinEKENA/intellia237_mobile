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
  var _focused = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
    _focus.addListener(() {
      if (_focus.hasFocus != _focused) {
        setState(() => _focused = _focus.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focus.dispose();
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

    // Registre (retour appareil, 24/09/2026) : le champ était trop pâle et
    // le bouton gris. Le champ se détache désormais sur un fond blanc, bordé
    // et éclairé à la couleur du compagnon ; le bouton est un disque en
    // dégradé, teinté même avant la saisie, lumineux dès qu'on peut envoyer.
    final borderColor = accentColor.withValues(
      alpha: !enabled ? 0.20 : (_focused ? 0.85 : 0.45),
    );
    return Padding(
      padding: const EdgeInsets.only(top: IntelliaSpacing.sm),
      child: AnimatedContainer(
        key: const ValueKey('companion-composer'),
        duration: IntelliaMotion.fast,
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: BoxDecoration(
          color: s.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: _focused ? 2 : 1.6),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: _focused ? 0.22 : 0.12),
              blurRadius: _focused ? 22 : 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Icon(
                Icons.edit_note_rounded,
                size: 22,
                color: accentColor.withValues(alpha: enabled ? 0.9 : 0.4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                cursorColor: accentColor,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (canSend) widget.onSubmit();
                },
                style: TextStyle(
                  color: s.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: l10n.writeQuestionHint,
                  hintStyle: TextStyle(
                    color: s.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  // Le thème remplit les champs d'un fond clair : le champ
                  // écrit à même la surface du composeur.
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              enabled: canSend,
              label: l10n.companionSend,
              child: Tooltip(
                message: l10n.companionSend,
                child: _SendButton(
                  accent: accentColor,
                  active: canSend,
                  enabled: enabled,
                  onTap: canSend ? widget.onSubmit : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton d'envoi : disque en dégradé à la couleur du compagnon.
class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.accent,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final Color accent;
  final bool active;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    // Deuxième teinte du dégradé : plus lumineuse, vers le violet de marque.
    final glow = Color.lerp(accent, IntelliaColors.brandPurple, 0.55)!;
    final active = widget.active;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      key: const ValueKey('companion-send'),
      onTap: widget.onTap,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed && !reduced ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: IntelliaMotion.fast,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: active
                  ? [accent, glow]
                  : [
                      accent.withValues(alpha: widget.enabled ? 0.16 : 0.08),
                      glow.withValues(alpha: widget.enabled ? 0.16 : 0.08),
                    ],
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: glow.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: Icon(
            Icons.send_rounded,
            size: 21,
            color: active
                ? Colors.white
                : accent.withValues(alpha: widget.enabled ? 0.75 : 0.35),
          ),
        ),
      ),
    );
  }
}
