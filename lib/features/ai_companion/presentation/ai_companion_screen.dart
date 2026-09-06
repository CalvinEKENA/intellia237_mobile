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

    final content = Column(
      children: [
        // ── Chat area ────────────────────────────────────────
        Expanded(
          child: _GlassChatContainer(
            scrollController: _scrollController,
            state: state,
            quickPromptsVisible: _quickPromptsVisible,
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
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          112,
        ),
        child: Column(
          children: [
            _CompanionHeader(state: state),
            const SizedBox(height: IntelliaSpacing.md),
            Expanded(child: content),
          ],
        ),
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
                  child: content,
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
              ? Padding(
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
              return ChatBubble(
                message: state.messages[index],
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
