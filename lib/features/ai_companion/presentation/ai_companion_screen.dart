import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/ai_companion_controller.dart';
import '../domain/ai_companion_reply.dart';
import '../domain/ai_message.dart';
import '../../interactive_learning/domain/interactive_block.dart';
import '../../interactive_learning/presentation/interactive_block_view.dart';
import '../../tutor/domain/tutor_persona.dart';
import 'widgets/chat_bubble.dart';
import '../application/listen_controller.dart';
import 'widgets/companion_composer.dart';
import 'widgets/companion_history_sheet.dart';

class AICompanionScreen extends ConsumerStatefulWidget {
  const AICompanionScreen({super.key, this.embedded = false, this.topic});

  final bool embedded;
  final String? topic;

  @override
  ConsumerState<AICompanionScreen> createState() => _AICompanionScreenState();
}

class _AICompanionScreenState extends ConsumerState<AICompanionScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _quickPromptsVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(aiCompanionControllerProvider.notifier)
            .setLessonContext(widget.topic);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCompanionControllerProvider);
    final l10n = context.l10n;
    final quickPrompts = [
      l10n.companionPromptExplain,
      l10n.companionPromptSummarize,
      l10n.companionPromptExample,
      l10n.companionPromptQuestions,
    ];
    ref.listen<AICompanionState>(aiCompanionControllerProvider, (
      previous,
      next,
    ) {
      if (next.messages.length != (previous?.messages.length ?? 0)) {
        // Hide quick prompts once first message is sent
        if (_quickPromptsVisible && next.messages.isNotEmpty) {
          setState(() => _quickPromptsVisible = false);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    // La bande de suggestions est un confort : elle s'efface quand la hauteur
    // restante ne suffit plus à la conversation et au composeur.
    Widget buildContent({required bool compact}) => Column(
      children: [
        // ── Chat area ────────────────────────────────────────
        Expanded(
          child: _GlassChatContainer(
            scrollController: _scrollController,
            state: state,
            quickPromptsVisible: _quickPromptsVisible && !compact,
            quickPrompts: quickPrompts,
            onQuickPrompt: (prompt) {
              ref.read(aiCompanionControllerProvider.notifier).send(prompt);
            },
          ),
        ),

        // ── Error ─────────────────────────────────────────────
        if (state.errorMessage != null) ...[
          const SizedBox(height: IntelliaSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  _localizedCompanionError(context, state),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ),
              if (state.lastFailedMessage != null)
                TextButton.icon(
                  onPressed: state.isSending
                      ? null
                      : () => ref
                            .read(aiCompanionControllerProvider.notifier)
                            .retryLastMessage(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.retryLabel),
                ),
            ],
          ),
        ],
        if (state.lessonContext != null) ...[
          const SizedBox(height: IntelliaSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: const Icon(Icons.menu_book_rounded, size: 16),
              label: Text(
                l10n.companionContext(state.lessonContext!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        const SizedBox(height: IntelliaSpacing.sm),

        // ── Composer ─────────────────────────────────────────
        CompanionComposer(
          controller: _controller,
          onSubmit: _sendCurrentInput,
          enabled: !state.isSending,
          companionName: state.tutor.name,
          accentColor: state.tutor.accentColor,
        ),
      ],
    );

    if (widget.embedded) {
      // La réserve du bas dégage la barre de navigation. Elle ne peut pas être
      // une constante : à l'ouverture du clavier la coquille rétrécit déjà le
      // corps — et en absorbe l'encoche, donc `viewInsets` y vaut zéro — si
      // bien qu'exiger malgré tout 112 points faisait réclamer à la colonne
      // plus de hauteur qu'il n'en restait. C'est le débordement observé.
      //
      // La conversation passe donc avant la réserve : celle-ci n'est servie
      // que sur ce qui excède une hauteur de travail décente.
      return LayoutBuilder(
        builder: (context, constraints) {
          const navReserve = 112.0;
          // En dessous de cette hauteur, l'écran ne peut plus porter à la fois
          // le portrait, les suggestions, la conversation et le composeur.
          const roomForEverything = 520.0;
          final available = constraints.maxHeight;
          final compact = available.isFinite && available < roomForEverything;

          // Quand la place manque, la réserve de navigation et le portrait
          // s'effacent : ce sont des agréments, alors que la conversation et
          // le composeur sont la fonction même de l'écran. Tout revient dès
          // que le clavier se referme.
          final reserve = compact ? IntelliaSpacing.sm : navReserve;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              IntelliaSpacing.lg,
              compact ? IntelliaSpacing.sm : IntelliaSpacing.lg,
              IntelliaSpacing.lg,
              reserve,
            ),
            child: Column(
              children: [
                if (!compact) ...[
                  _CompanionHeader(state: state),
                  const SizedBox(height: IntelliaSpacing.md),
                ],
                Expanded(child: buildContent(compact: compact)),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      body: LiquidBackground(
        primaryColor: IntelliaColors.success,
        secondaryColor: IntelliaColors.brandIndigo,
        tertiaryColor: IntelliaColors.warning,
        child: SafeArea(
          child: Column(
            children: [
              _GlassTopBar(
                state: state,
                onClose: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    IntelliaSpacing.lg,
                    0,
                    IntelliaSpacing.lg,
                    IntelliaSpacing.lg,
                  ),
                  child: buildContent(compact: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendCurrentInput() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    _controller.clear();
    // Un nouvel envoi interrompt proprement la lecture en cours ; elle ne
    // reprend jamais d'elle-même.
    unawaited(ref.read(listenControllerProvider.notifier).stop());
    ref.read(aiCompanionControllerProvider.notifier).send(message);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: IntelliaMotion.medium,
      curve: Curves.easeOut,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar — glass with tutor info
// ─────────────────────────────────────────────────────────────

class _GlassTopBar extends StatelessWidget {
  const _GlassTopBar({required this.state, this.onClose});

  final AICompanionState state;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            IntelliaSpacing.sm,
            IntelliaSpacing.lg,
            IntelliaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            border: Border(
              bottom: BorderSide(color: IntelliaColors.glassBorder, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              if (onClose != null) ...[
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: IntelliaSpacing.md),
              ],
              // Tutor Photo badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: state.tutor.accentColor.withValues(alpha: 0.40),
                    width: 1.5,
                  ),
                  image: DecorationImage(
                    image: AssetImage(state.tutor.imagePath),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: AppShadows.glow(
                    state.tutor.accentColor,
                    intensity: 0.25,
                  ),
                ),
              ),
              const SizedBox(width: IntelliaSpacing.sm),

              // Title info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.tutor.name,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tuteur Personnel • ${state.tutor.levelLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // État honnête : aucune fausse pastille « en ligne ».
              Icon(
                state.errorMessage == null
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.cloud_off_rounded,
                size: 18,
                color: state.errorMessage == null
                    ? Colors.white.withValues(alpha: 0.65)
                    : const Color(0xFFFFB4AB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Companion header — light embedded (avatar + name + level + status)
// ─────────────────────────────────────────────────────────────

class _CompanionHeader extends StatelessWidget {
  const _CompanionHeader({required this.state});

  final AICompanionState state;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final tutor = state.tutor;
    final statusLabel = state.isSending
        ? context.l10n.companionStatusThinking
        : switch (state.errorKind) {
            AICompanionFailureKind.quotaExhausted =>
              context.l10n.companionStatusQuota,
            AICompanionFailureKind.studyReserveExhausted =>
              context.l10n.studyReserveStatusDepleted,
            AICompanionFailureKind.authorizationProfile =>
              context.l10n.companionStatusProfile,
            AICompanionFailureKind.network =>
              context.l10n.companionStatusNetwork,
            null => context.l10n.companionStatusReady,
            _ => context.l10n.companionStatusUnavailable,
          };

    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.sm),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        border: Border.all(color: s.surfaceBorder),
        boxShadow: IntelliaShadows.card(Colors.black),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: tutor.accentColor.withValues(alpha: 0.45),
                width: 1.5,
              ),
              image: DecorationImage(
                image: AssetImage(tutor.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: IntelliaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tutor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: s.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: state.errorMessage == null
                            ? IntelliaColors.success
                            : IntelliaColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Tuteur • $statusLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: s.textTertiary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Accès à l'historique : les fils précédents doivent être
          // retrouvables sans passer par un menu caché.
          IconButton(
            key: const ValueKey('companion-history-button'),
            onPressed: () => CompanionHistorySheet.show(context),
            tooltip: context.l10n.companionHistoryTitle,
            icon: Icon(Icons.history_rounded, color: s.textSecondary, size: 22),
          ),
        ],
      ),
    );
  }
}

String _localizedCompanionError(BuildContext context, AICompanionState state) {
  final name = state.tutor.name;
  return switch (state.errorKind) {
    AICompanionFailureKind.quotaExhausted => context.l10n.companionQuotaReached(
      name,
    ),
    AICompanionFailureKind.studyReserveExhausted =>
      context.l10n.companionStudyReserveDepleted(name),
    AICompanionFailureKind.authorizationProfile =>
      context.l10n.companionProfileSync(name),
    AICompanionFailureKind.invalidRequest =>
      context.l10n.companionInvalidRequest(name),
    AICompanionFailureKind.network => context.l10n.companionNetworkUnavailable(
      name,
    ),
    AICompanionFailureKind.invalidResponse =>
      context.l10n.companionInvalidResponse(name),
    AICompanionFailureKind.serviceUnavailable ||
    AICompanionFailureKind.appCheck ||
    AICompanionFailureKind.unknown => context.l10n.companionServiceUnavailable(
      name,
    ),
    null => state.errorMessage ?? '',
  };
}

// ─────────────────────────────────────────────────────────────
// Glass chat container with messages + quick prompts
// ─────────────────────────────────────────────────────────────

class _GlassChatContainer extends StatelessWidget {
  const _GlassChatContainer({
    required this.scrollController,
    required this.state,
    required this.quickPromptsVisible,
    required this.quickPrompts,
    required this.onQuickPrompt,
  });

  final ScrollController scrollController;
  final AICompanionState state;
  final bool quickPromptsVisible;
  final List<String> quickPrompts;
  final ValueChanged<String> onQuickPrompt;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final inner = Column(
      children: [
        // Quick prompts — hidden after first message
        AnimatedSize(
          duration: IntelliaMotion.medium,
          curve: IntelliaMotion.emphasizedDecelerate,
          child: quickPromptsVisible
              ? ConstrainedBox(
                  // À très grande échelle de texte, la bande de suggestions
                  // pourrait à elle seule dépasser la conversation : elle
                  // défile plutôt que de pousser la colonne.
                  constraints: const BoxConstraints(maxHeight: 132),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      IntelliaSpacing.md,
                      IntelliaSpacing.md,
                      IntelliaSpacing.md,
                      0,
                    ),
                    child: _QuickPromptChips(
                      prompts: quickPrompts,
                      onTap: onQuickPrompt,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(IntelliaSpacing.sm),
            itemCount: state.messages.length + (state.isSending ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.messages.length) {
                return TypingIndicatorBubble(tutor: state.tutor);
              }
              final message = state.messages[index];
              final block = message.block;
              if (block == null) {
                return ChatBubble(message: message, tutor: state.tutor);
              }
              return _MessageWithActivity(
                message: message,
                block: block,
                tutor: state.tutor,
              );
            },
          ),
        ),
      ],
    );

    // Embedded clair : surface opaque + ombre douce (pas de BackdropFilter dans
    // une conversation scrollable). Autonome sombre : glass conservé.
    if (!s.useGlass) {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: s.surface,
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          border: Border.all(color: s.surfaceBorder),
          boxShadow: IntelliaShadows.card(Colors.black),
        ),
        child: inner,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(IntelliaRadii.large),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(IntelliaRadii.large),
            border: Border.all(color: IntelliaColors.glassBorder),
          ),
          child: inner,
        ),
      ),
    );
  }
}

/// Réponse du compagnon suivie de l'activité qu'il propose.
///
/// Gardée vivante au défilement : remonter dans la conversation ne remet pas
/// l'exercice à zéro. Le bloc est rendu hors de la bulle pour ne pas hériter
/// de sa hauteur intrinsèque.
class _MessageWithActivity extends ConsumerStatefulWidget {
  const _MessageWithActivity({
    required this.message,
    required this.block,
    required this.tutor,
  });

  final AIMessage message;
  final InteractiveLearningBlock block;
  final TutorPersona tutor;

  @override
  ConsumerState<_MessageWithActivity> createState() =>
      _MessageWithActivityState();
}

class _MessageWithActivityState extends ConsumerState<_MessageWithActivity>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final author = TutorPersona.resolve(
      widget.message.companionId,
      fallback: widget.tutor,
    );
    final controller = ref.read(aiCompanionControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChatBubble(message: widget.message, tutor: widget.tutor),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
              child: InteractiveBlockView(
                block: widget.block,
                companion: ExerciseCompanion(
                  id: author.id,
                  name: author.name,
                  avatarAsset: author.imagePath,
                ),
                onOutcome: controller.recordActivityOutcome,
                onContinue: () {
                  if (ref.read(aiCompanionControllerProvider).isSending) {
                    return;
                  }
                  unawaited(
                    controller.continueAfterActivity(
                      context.l10n.ilbContinueMessage,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Quick prompt chips — gold glass pills
// ─────────────────────────────────────────────────────────────

class _QuickPromptChips extends StatelessWidget {
  const _QuickPromptChips({required this.prompts, required this.onTap});

  final List<String> prompts;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: IntelliaSpacing.xs,
      runSpacing: IntelliaSpacing.xs,
      children: [
        for (int i = 0; i < prompts.length; i++)
          GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap(prompts[i]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: IntelliaSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: IntelliaColors.brandIndigo.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: IntelliaColors.brandIndigo.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.forum_outlined,
                        size: 12,
                        color: IntelliaColors.brandIndigo,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        prompts[i],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: IntelliaColors.brandIndigo,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(delay: Duration(milliseconds: i * 60))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.05, end: 0),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Glass pill composer — text field + gradient send button
// ─────────────────────────────────────────────────────────────
