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
import '../../../core/telemetry/startup_trace.dart';
import '../../../core/localization/app_locale_controller.dart';
import '../application/ai_companion_controller.dart';
import '../application/companion_engine_providers.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/companion_reply_actions.dart';
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
      StartupTrace.mark(StartupMilestone.companionUsable);
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
    // Suggestions selon ce que l'élève peut réellement faire (quiz, matière
    // en cours, priorité de révision), tirées de la banque de dialogues.
    final language = ref.watch(appLocaleProvider).languageCode;
    final bank = ref.watch(companionDialogueBankProvider(language)).valueOrNull;
    final quickPrompts = bank == null
        ? const <String>[]
        : ref
              .watch(deterministicCompanionEngineProvider)
              .suggestions(
                context: ref.watch(companionStudyContextProvider),
                bank: bank,
              );
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
            onQuickPrompt: _send,
          ),
        ),

        if (state.unavailable) ...[
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            l10n.companionLocalUnavailable(state.tutor.name),
            style: const TextStyle(fontSize: 12, color: Color(0xFFB42318)),
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
    _send(message);
  }

  /// Le rythme « Kira écrit… » disparaît quand les animations sont réduites.
  void _send(String message) {
    ref
        .read(aiCompanionControllerProvider.notifier)
        .send(message, instant: MediaQuery.disableAnimationsOf(context));
  }

  /// Descend jusqu'à la dernière réponse et ses actions. La liste ne
  /// connaît sa vraie hauteur qu'après avoir construit la dernière bulle :
  /// on vérifie donc la fin une fois le mouvement terminé.
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    void settle() {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels < position.maxScrollExtent - 1) {
        _scrollController.jumpTo(position.maxScrollExtent);
      }
    }

    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) => settle());
      return;
    }
    _scrollController
        .animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: IntelliaMotion.medium,
          curve: Curves.easeOut,
        )
        .then((_) => settle());
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
                      context.l10n.companionTopBarSubtitle(
                        state.tutor.levelLabel,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Tout est local : aucune pastille « en ligne » ou « hors ligne ».
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.65),
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
    // Aucun état réseau ni quota : le compagnon répond toujours, sur
    // l'appareil.
    final statusLabel = state.isSending
        ? context.l10n.companionStatusWriting(tutor.name)
        : context.l10n.companionStatusReady;

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
                      decoration: const BoxDecoration(
                        color: IntelliaColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.l10n.companionHeaderStatus(statusLabel),
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
                return Semantics(
                  liveRegion: true,
                  label: context.l10n.companionStatusWriting(state.tutor.name),
                  child: ExcludeSemantics(
                    child: TypingIndicatorBubble(tutor: state.tutor),
                  ),
                );
              }
              final message = state.messages[index];
              final bubble = ChatBubble(message: message, tutor: state.tutor);
              // Les actions ne valent que pour la dernière réponse : plus
              // haut dans le fil, elles pourraient ne plus être à jour.
              final isLast = index == state.messages.length - 1;
              if (!isLast || state.isSending || message.actions.isEmpty) {
                return bubble;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  bubble,
                  CompanionReplyActions(
                    actions: message.actions,
                    accentColor: state.tutor.accentColor,
                    onReply: onQuickPrompt,
                  ),
                ],
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
                      // Une suggestion longue revient à la ligne dans sa
                      // pastille, jamais hors de l'écran.
                      Flexible(
                        child: Text(
                          prompts[i],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: IntelliaColors.brandIndigo,
                          ),
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
