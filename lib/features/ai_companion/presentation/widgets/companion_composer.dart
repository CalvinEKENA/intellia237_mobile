import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/tab_presentation.dart';
import '../../application/dictation_controller.dart';
import '../../application/listen_controller.dart';
import '../../domain/dictation_session.dart';

/// Composeur du compagnon : **écrire ou parler**.
///
/// Registre de décisions : un seul verbe accompagne le champ. Au repos il
/// propose « Parler » ; dès qu'un caractère utile est saisi, il devient
/// « Envoyer ». Pas de trombone, pas de barre d'icônes, pas de « mode vocal » :
/// l'élève ne raisonne pas en type de fichier.
///
/// « Montrer » n'est volontairement pas exposé tant que le backend ne sait pas
/// exploiter une image : offrir le geste sans la capacité reviendrait à
/// promettre une lecture qui n'aura pas lieu.
class CompanionComposer extends ConsumerStatefulWidget {
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
  ConsumerState<CompanionComposer> createState() => _CompanionComposerState();
}

class _CompanionComposerState extends ConsumerState<CompanionComposer> {
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

  Future<void> _onSpeak() async {
    HapticFeedback.selectionClick();
    // Dicter et écouter ne peuvent pas coexister : la lecture s'arrête avant
    // que le micro ne s'ouvre.
    unawaited(ref.read(listenControllerProvider.notifier).stop());
    final notifier = ref.read(dictationControllerProvider.notifier);
    await notifier.start();
  }

  void _acceptTranscript() {
    final dictation = ref.read(dictationControllerProvider);
    final transcript = dictation.transcript.trim();
    if (transcript.isEmpty) return;
    // La transcription rejoint le champ normal : elle reste corrigeable, et
    // rien n'est envoyé tant que l'élève ne le décide pas.
    final existing = widget.controller.text.trim();
    widget.controller.text = existing.isEmpty
        ? transcript
        : '$existing $transcript';
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    ref.read(dictationControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final dictation = ref.watch(dictationControllerProvider);
    ref.listen<DictationState>(dictationControllerProvider, (previous, next) {
      // Dès que la dictée aboutit, le texte rejoint le champ pour correction.
      if (next.status == DictationStatus.ready &&
          previous?.status != DictationStatus.ready) {
        _acceptTranscript();
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dictation.isListening)
          _DictationStrip(
            state: dictation,
            accentColor: widget.accentColor,
            onCancel: () =>
                ref.read(dictationControllerProvider.notifier).cancel(),
            onStop: () => ref.read(dictationControllerProvider.notifier).stop(),
          )
        else if (dictation.status != DictationStatus.idle)
          _DictationNotice(
            status: dictation.status,
            companionName: widget.companionName,
            onDismiss: () =>
                ref.read(dictationControllerProvider.notifier).reset(),
          ),
        const SizedBox(height: IntelliaSpacing.sm),
        _Field(
          controller: widget.controller,
          enabled: widget.enabled && !dictation.isListening,
          hasText: _hasText,
          accentColor: widget.accentColor,
          onSubmit: widget.onSubmit,
          onSpeak: _onSpeak,
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.enabled,
    required this.hasText,
    required this.accentColor,
    required this.onSubmit,
    required this.onSpeak,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool hasText;
  final Color accentColor;
  final VoidCallback onSubmit;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final l10n = context.l10n;
    // Un seul verbe à droite du champ : « Parler » devient « Envoyer ».
    final sending = hasText;
    final label = sending ? l10n.companionSend : l10n.companionSpeak;

    return Container(
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
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (enabled && hasText) onSubmit();
              },
              style: TextStyle(color: s.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.writeQuestionHint,
                hintStyle: TextStyle(color: s.textTertiary, fontSize: 14),
                border: InputBorder.none,
                // Le thème remplit les champs d'un fond clair : sur la surface
                // sombre du compagnon, le texte blanc y devenait invisible.
                // Le champ écrit à même la surface.
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: IntelliaSpacing.sm),
          Semantics(
            button: true,
            label: label,
            child: Tooltip(
              message: label,
              child: InkResponse(
                onTap: enabled ? (sending ? onSubmit : onSpeak) : null,
                radius: 26,
                child: AnimatedContainer(
                  duration: IntelliaMotion.fast,
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: enabled
                        ? (sending ? accentColor : Colors.transparent)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: enabled
                          ? accentColor.withValues(alpha: sending ? 0 : 0.55)
                          : s.surfaceBorder,
                    ),
                  ),
                  child: Icon(
                    sending
                        ? Icons.arrow_upward_rounded
                        : Icons.mic_none_rounded,
                    size: 20,
                    color: enabled
                        ? (sending ? Colors.white : accentColor)
                        : s.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau de dictée : fil d'encre réactif au son, chronomètre, Annuler/Arrêter.
///
/// Volontairement compact — la dictée est une manière d'écrire, pas une
/// session vocale qui prendrait la moitié de l'écran.
class _DictationStrip extends StatelessWidget {
  const _DictationStrip({
    required this.state,
    required this.accentColor,
    required this.onCancel,
    required this.onStop,
  });

  final DictationState state;
  final Color accentColor;
  final VoidCallback onCancel;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final l10n = context.l10n;
    final seconds = state.elapsed.inSeconds;

    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                l10n.companionListening,
                style: TextStyle(
                  color: s.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (state.isNearingLimit)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    l10n.companionDictationNearEnd,
                    style: TextStyle(color: s.textTertiary, fontSize: 11),
                  ),
                ),
              Text(
                '0:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: s.textSecondary,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          _InkThread(level: state.soundLevel, color: accentColor),
          if (state.transcript.isNotEmpty) ...[
            const SizedBox(height: IntelliaSpacing.sm),
            Text(
              state.transcript,
              style: TextStyle(
                color: s.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: IntelliaSpacing.sm),
          Row(
            children: [
              TextButton(
                onPressed: onCancel,
                child: Text(l10n.companionDictationCancel),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onStop,
                child: Text(l10n.companionDictationStop),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fil d'encre horizontal dont l'épaisseur suit le niveau sonore.
///
/// Le langage visuel d'INTELLIA est l'encre : pas de forme d'onde
/// d'enregistreur, qui parlerait d'un fichier audio à conserver.
class _InkThread extends StatelessWidget {
  const _InkThread({required this.level, required this.color});

  final double level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 1.5 + level * 5,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.35 + level * 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// États non nominaux de la dictée. « Parler » reste visible dans tous les cas.
class _DictationNotice extends StatelessWidget {
  const _DictationNotice({
    required this.status,
    required this.companionName,
    required this.onDismiss,
  });

  final DictationStatus status;
  final String companionName;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final l10n = context.l10n;
    final message = switch (status) {
      DictationStatus.needsPermission => l10n.companionMicRationale(
        companionName,
      ),
      DictationStatus.permissionDenied => l10n.companionMicDenied,
      DictationStatus.unavailable => l10n.companionMicUnavailable,
      DictationStatus.failed => l10n.companionDictationFailed,
      _ => null,
    };
    if (message == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        color: s.surfaceMuted,
        borderRadius: BorderRadius.circular(IntelliaRadii.small),
        border: Border.all(color: s.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: s.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
          ),
        ],
      ),
    );
  }
}
