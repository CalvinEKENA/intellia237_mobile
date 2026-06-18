import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/liquid_background.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';
import 'widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signInWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    // Écoute des erreurs
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(next.error!)),
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
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      resizeToAvoidBottomInset: true,
      body: LiquidBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: _JewelCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Badge logo ─────────────────────────────
                      _LogoBadge(),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Titre ──────────────────────────────────
                      Text(
                        'Bon retour !',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Connectez-vous pour continuer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Email ──────────────────────────────────
                      AuthTextField(
                        controller: _emailCtrl,
                        label: 'Adresse email',
                        hint: 'exemple@edunova.cm',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        isDark: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'L\'email est requis';
                          }
                          if (!RegExp(
                            r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$',
                          ).hasMatch(v.trim())) {
                            return 'Entrez un email valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Mot de passe ───────────────────────────
                      AuthTextField(
                        controller: _passwordCtrl,
                        label: 'Mot de passe',
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        enabled: !isLoading,
                        isDark: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Le mot de passe est requis';
                          }
                          return null;
                        },
                      ),

                      // ── Mot de passe oublié ────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.push(AppRoutes.forgotPassword),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                          ),
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Bouton connexion ───────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          onPressed: isLoading ? null : _submit,
                          gradient: AppGradients.heroNavy,
                          isLoading: isLoading,
                          child: const Text(
                            'Se connecter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Séparateur ─────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              'Pas encore de compte ?',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Créer un compte ────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () => context.push(AppRoutes.register),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                          child: const Text(
                            'Créer un compte',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Carte glassmorphism principale
// ─────────────────────────────────────────────────────────────

class _JewelCard extends StatelessWidget {
  const _JewelCard({required this.child});

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
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Badge logo EduNova
// ─────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppGradients.heroNavy,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.glow(AppColors.brand, intensity: 0.4),
          ),
          child: Center(
            child: Image.asset(
              'assets/icons/icone.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => const Icon(
                Icons.school_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'EduNova',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
