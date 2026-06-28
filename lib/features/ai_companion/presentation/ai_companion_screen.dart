import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../application/ai_companion_controller.dart';
import 'widgets/chat_bubble.dart';

class AICompanionScreen extends ConsumerStatefulWidget {
  const AICompanionScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<AICompanionScreen> createState() => _AICompanionScreenState();
}

class _AICompanionScreenState extends ConsumerState<AICompanionScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _quickPromptsVisible = true;

  static const _quickPrompts = [
    'Explique ce concept',
    'Résume en points clés',
    'Donne un exemple concret',
    'Pose-moi 3 questions',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCompanionControllerProvider);
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
            quickPrompts: _quickPrompts,
            onQuickPrompt: (prompt) {
              ref.read(aiCompanionControllerProvider.notifier).send(prompt);
            },
          ),
        ),

        // ── Error ─────────────────────────────────────────────
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              state.errorMessage!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),

        // ── Composer ─────────────────────────────────────────
        _GlassComposer(
          controller: _controller,
          onSubmit: _sendCurrentInput,
          enabled: !state.isSending,
          accentColor: state.tutor.accentColor,
        ),
      ],
    );

    if (widget.embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          112,
        ),
        child: Column(
          children: [
            _CompanionHeader(state: state),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      body: LiquidBackground(
        primaryColor: AppColors.accent,
        secondaryColor: AppColors.brand,
        tertiaryColor: AppColors.gold,
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
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
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
    ref.read(aiCompanionControllerProvider.notifier).send(message);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: AppMotion.medium,
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
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            border: Border(
              bottom: BorderSide(color: AppColors.glassBorder, width: 0.8),
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
                const SizedBox(width: AppSpacing.md),
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
              const SizedBox(width: AppSpacing.sm),

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

              // Online indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.glow(AppColors.accent, intensity: 0.6),
                ),
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
    final statusLabel = state.isSending ? 'réfléchit…' : 'Disponible';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
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
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tutor.name,
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
                      decoration: const BoxDecoration(
                        color: IntelliaColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tuteur • $statusLabel',
                      style: TextStyle(fontSize: 12, color: s.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: tutor.gradientColors),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              tutor.levelLabel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
          duration: AppMotion.medium,
          curve: AppMotion.emphasizedDecelerate,
          child: quickPromptsVisible
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
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
            padding: const EdgeInsets.all(AppSpacing.sm),
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: s.surfaceBorder),
          boxShadow: IntelliaShadows.card(Colors.black),
        ),
        child: inner,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.glassBorder),
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
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (int i = 0; i < prompts.length; i++)
          GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap(prompts[i]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
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
                        Icons.auto_awesome_rounded,
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

class _GlassComposer extends StatelessWidget {
  const _GlassComposer({
    required this.controller,
    required this.onSubmit,
    required this.enabled,
    required this.accentColor,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool enabled;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);

    final field = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: s.useGlass ? Colors.white.withValues(alpha: 0.08) : s.fieldFill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
              onSubmitted: (_) => onSubmit(),
              style: TextStyle(color: s.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Écris ta question…',
                hintStyle: TextStyle(color: s.textTertiary, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Send button — gradient circle
          GestureDetector(
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    onSubmit();
                  }
                : null,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: enabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accentColor, AppColors.brand],
                      )
                    : null,
                color: enabled ? null : s.surfaceMuted,
                shape: BoxShape.circle,
                boxShadow: enabled
                    ? AppShadows.glow(accentColor, intensity: 0.40)
                    : null,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 18,
                color: enabled ? Colors.white : s.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );

    if (!s.useGlass) return field;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: field,
      ),
    );
  }
}
