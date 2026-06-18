import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/liquid_background.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailCtrl.text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _emailSent = success;
    });

    if (!success) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Impossible d\'envoyer l\'email. Vérifiez l\'adresse.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      body: LiquidBackground(
        primaryColor: AppColors.brandDeep,
        secondaryColor: AppColors.brand,
        tertiaryColor: AppColors.accent,
        child: SafeArea(
          child: Column(
            children: [
              // ── Retour ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Retour',
                    ),
                  ],
                ),
              ),

              // ── Carte glass centrée ───────────────────────────
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: AnimatedSwitcher(
                      duration: AppMotion.cinematic,
                      switchInCurve: AppMotion.emphasizedDecelerate,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.95, end: 1.0)
                              .animate(animation),
                          child: child,
                        ),
                      ),
                      child: _emailSent
                          ? _SuccessCard(email: _emailCtrl.text.trim())
                          : _FormCard(
                              formKey: _formKey,
                              emailCtrl: _emailCtrl,
                              isLoading: _isLoading,
                              onSubmit: _submit,
                              onBack: () => context.pop(),
                            ),
                    ),
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
// Carte formulaire
// ─────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.emailCtrl,
    required this.isLoading,
    required this.onSubmit,
    required this.onBack,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _JewelPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: AppGradients.heroNavy,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppShadows.glow(AppColors.brand, intensity: 0.4),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 32,
              color: Colors.white,
            ),
          ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'Mot de passe\noublié ?',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Entrez votre email et nous vous enverrons\nun lien de réinitialisation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.60),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          Form(
            key: formKey,
            child: AuthTextField(
              controller: emailCtrl,
              label: 'Adresse email',
              hint: 'exemple@edunova.cm',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofocus: true,
              enabled: !isLoading,
              isDark: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'L\'email est requis';
                if (!RegExp(
                  r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$',
                ).hasMatch(v.trim())) {
                  return 'Entrez un email valide';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity,
            child: GradientButton(
              onPressed: isLoading ? null : onSubmit,
              gradient: AppGradients.heroNavy,
              isLoading: isLoading,
              child: const Text(
                'Envoyer le lien',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          TextButton(
            onPressed: onBack,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.60),
            ),
            child: const Text('Retour à la connexion'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────
// État succès
// ─────────────────────────────────────────────────────────────

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return _JewelPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône succès animée
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: AppMotion.slow,
            curve: AppMotion.spring,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            ),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.40),
                  width: 1.5,
                ),
                boxShadow: AppShadows.glow(AppColors.accent, intensity: 0.30),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                size: 36,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Email envoyé !',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Un lien de réinitialisation a été envoyé à',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.60),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Vérifiez votre boîte de réception et vos spams.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.45),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),

          SizedBox(
            width: double.infinity,
            child: GradientButton(
              onPressed: () => context.pop(),
              gradient: AppGradients.heroTeal,
              child: const Text(
                'Retour à la connexion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Panel glassmorphism partagé
// ─────────────────────────────────────────────────────────────

class _JewelPanel extends StatelessWidget {
  const _JewelPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x1AFFFFFF), Color(0x0AFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: child,
        ),
      ),
    );
  }
}
