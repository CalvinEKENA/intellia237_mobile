import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../tutor/domain/tutor_persona.dart';
import '../../domain/ai_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, required this.tutor, super.key});

  final AIMessage message;
  final TutorPersona tutor;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AIMessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: isUser
            ? _UserBubble(text: message.text)
            : _AiBubble(text: message.text, tutor: tutor),
      ),
    )
        .animate()
        .slideY(
          begin: 0.3,
          end: 0,
          duration: AppMotion.medium,
          curve: AppMotion.emphasizedDecelerate,
        )
        .fadeIn(duration: AppMotion.medium);
  }
}

// ─────────────────────────────────────────────────────────────
// User bubble — gradient pill (brand → accent), right-aligned
// ─────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.accent],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: AppShadows.glow(AppColors.brand, intensity: 0.20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AI bubble — glass panel with tutor avatar, left-aligned
// ─────────────────────────────────────────────────────────────

class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.text, required this.tutor});

  final String text;
  final TutorPersona tutor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x1EFFFFFF), Color(0x0CFFFFFF)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            border: Border.all(
              color: AppColors.glassBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tutor Avatar
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tutor.accentColor.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  image: DecorationImage(
                    image: AssetImage(tutor.imagePath),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: AppShadows.glow(tutor.accentColor, intensity: 0.15),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.6,
                  ),
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
// Typing indicator — 3 bouncing dots with tutor accent
// ─────────────────────────────────────────────────────────────

class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({required this.tutor, super.key});

  final TutorPersona tutor;

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _anims = _ctrls
        .map(
          (c) => Tween<double>(begin: 0, end: -8).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut),
          ),
        )
        .toList();

    _startBouncing();
  }

  void _startBouncing() async {
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _ctrls[i].forward(from: 0).then((_) => _ctrls[i].reverse());
        await Future.delayed(const Duration(milliseconds: 150));
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 3; i++) ...[
              AnimatedBuilder(
                animation: _anims[i],
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _anims[i].value),
                  child: child,
                ),
                child: Container(
                  width: 7,
                  height: 7,
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
    ).animate().fadeIn(duration: AppMotion.fast);
  }
}
