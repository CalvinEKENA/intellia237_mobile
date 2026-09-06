import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../application/listen_controller.dart';
import '../../../../core/widgets/tab_presentation.dart';
import '../../../tutor/domain/tutor_persona.dart';
import '../../domain/ai_message.dart';
import 'companion_rich_text.dart';

/// Un tour de conversation, dans la direction « Cahier · Ligne ».
///
/// Registre de décisions : la réponse du compagnon n'est plus enfermée dans une
/// bulle de verre à dégradé, et son portrait ne se répète plus à chaque
/// message — il reste dans l'en-tête. Le texte est posé sur le fond, tenu par
/// un simple fil d'encre vertical à la couleur de la persona. L'élève, lui,
/// garde une bulle discrète à droite.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    required this.tutor,
    this.showTimestamp = true,
    super.key,
  });

  final AIMessage message;

  /// Compagnon courant, utilisé seulement quand le message n'en porte pas.
  final TutorPersona tutor;

  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AIMessageRole.user;
    // Un message garde le compagnon qui l'a écrit : changer de persona ne
    // réécrit pas les réponses passées.
    final author = isUser
        ? tutor
        : TutorPersona.resolve(message.companionId, fallback: tutor);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.symmetric(vertical: IntelliaSpacing.sm),
        child: isUser
            ? _StudentTurn(message: message, showTimestamp: showTimestamp)
            : _CompanionTurn(
                message: message,
                author: author,
                showTimestamp: showTimestamp,
              ),
      ),
    );
  }
}

/// Horodatage discret, lisible sans dominer la ligne.
class _Timestamp extends StatelessWidget {
  const _Timestamp({required this.moment});

  final DateTime moment;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final local = moment.toLocal();
    final text =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(color: s.textTertiary, fontSize: 11, height: 1.2),
      ),
    );
  }
}

class _StudentTurn extends StatelessWidget {
  const _StudentTurn({required this.message, required this.showTimestamp});

  final AIMessage message;
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: IntelliaSpacing.md,
            vertical: IntelliaSpacing.sm,
          ),
          decoration: BoxDecoration(
            // Bulle discrète : une teinte d'encre, pas un dégradé de marque.
            color: s.fieldFill,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(color: s.surfaceBorder),
          ),
          child: Text(
            message.text,
            style: TextStyle(color: s.textPrimary, fontSize: 14, height: 1.5),
          ),
        ),
        if (showTimestamp) _Timestamp(moment: message.createdAt),
      ],
    );
  }
}

class _CompanionTurn extends ConsumerWidget {
  const _CompanionTurn({
    required this.message,
    required this.author,
    required this.showTimestamp,
  });

  final AIMessage message;
  final TutorPersona author;
  final bool showTimestamp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = TabSurface.of(context);
    final listen = ref.watch(listenControllerProvider);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fil d'encre : la seule marque de la persona dans le fil.
          Container(
            width: 2,
            decoration: BoxDecoration(
              color: author.accentColor.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: IntelliaSpacing.md),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CompanionRichText(
                  text: message.text,
                  accentColor: author.accentColor,
                  baseStyle: TextStyle(
                    color: s.textPrimary,
                    fontSize: 14.5,
                    height: 1.62,
                  ),
                ),
                Row(
                  children: [
                    // « Écouter » est disponible pour tous les paliers : la
                    // lecture à voix haute n'est pas une fonction premium.
                    _ListenAction(
                      speaking: listen.isSpeaking(message.id),
                      accent: author.accentColor,
                      onTap: () => ref
                          .read(listenControllerProvider.notifier)
                          .toggle(message.id, message.text),
                    ),
                    const Spacer(),
                    if (showTimestamp) _Timestamp(moment: message.createdAt),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton « Écouter » / « Pause » d'une réponse.
class _ListenAction extends StatelessWidget {
  const _ListenAction({
    required this.speaking,
    required this.accent,
    required this.onTap,
  });

  final bool speaking;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = speaking
        ? context.l10n.companionPauseListening
        : context.l10n.companionListen;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                speaking ? Icons.pause_rounded : Icons.volume_up_rounded,
                size: 15,
                color: accent,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Attente de réponse : trois points sur le fil d'encre, sans bulle.
class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({required this.tutor, super.key});

  final TutorPersona tutor;

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Une animation infinie ne doit pas tourner quand l'utilisateur a demandé
    // la réduction des mouvements.
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              decoration: BoxDecoration(
                color: widget.tutor.accentColor.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: IntelliaSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: IntelliaSpacing.sm),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      Opacity(
                        opacity: _dotOpacity(i),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: widget.tutor.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      if (i < 2) const SizedBox(width: 5),
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

  double _dotOpacity(int index) {
    if (!_controller.isAnimating) return 0.6;
    final phase = (_controller.value * 3 - index).clamp(0.0, 1.0);
    return 0.35 + 0.65 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
  }
}
