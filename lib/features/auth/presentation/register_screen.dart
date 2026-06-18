import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/liquid_background.dart';
import '../domain/app_role.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  AppRole? _selectedRole;

  void _continue() {
    final role = _selectedRole;
    if (role == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('Sélectionnez un profil pour continuer.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      return;
    }

    final route = switch (role) {
      AppRole.student => AppRoutes.studentRegistration,
      AppRole.parent  => AppRoutes.parentRegistration,
      AppRole.teacher => AppRoutes.teacherRegistration,
      AppRole.admin   => AppRoutes.adminRegistration,
    };

    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Barre supérieure ──────────────────────────────
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
                    const Spacer(),
                    Text(
                      'Choix du parcours',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Contenu scrollable ────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // Titre
                      Text(
                        'Quel est\nvotre profil ?',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(
                            begin: 0.1,
                            end: 0,
                          ),

                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Choisissez votre profil pour accéder\nà une expérience personnalisée.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                      ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: AppSpacing.xl),

                      // Cartes de rôle
                      ...AppRole.values.indexed.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _RoleCard(
                            role: entry.$2,
                            isSelected: _selectedRole == entry.$2,
                            onTap: () =>
                                setState(() => _selectedRole = entry.$2),
                          ).animate(delay: (200 + entry.$1 * 100).ms)
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: 0.06, end: 0),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Bouton continuer
                      SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          onPressed: _selectedRole != null ? _continue : null,
                          gradient: _selectedRole != null
                              ? AppGradients.forRole(_selectedRole!)
                              : AppGradients.heroNavy,
                          child: const Text(
                            'Continuer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: AppSpacing.xl),
                    ],
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
// Carte de rôle immersive (largeur full, hauteur 96dp)
// ─────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final AppRole role;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon => switch (role) {
    AppRole.student => Icons.school_rounded,
    AppRole.parent  => Icons.family_restroom_rounded,
    AppRole.teacher => Icons.menu_book_rounded,
    AppRole.admin   => Icons.admin_panel_settings_rounded,
  };

  String get _label => switch (role) {
    AppRole.student => 'Élève',
    AppRole.parent  => 'Parent',
    AppRole.teacher => 'Enseignant',
    AppRole.admin   => 'Administrateur',
  };

  String get _description => switch (role) {
    AppRole.student =>
      'Prépare ton BEPC, Probatoire ou Baccalauréat',
    AppRole.parent  => 'Suivez les progrès de vos enfants',
    AppRole.teacher => 'Gérez vos classes et contenus',
    AppRole.admin   => 'Administrez la plateforme',
  };

  @override
  Widget build(BuildContext context) {
    final roleColor = AppRoleColors.byRole(role);
    final gradient = AppGradients.forRole(role);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.emphasizedDecelerate,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: LinearGradient(
            colors: [
              gradient.colors.first.withValues(
                alpha: isSelected ? 0.30 : 0.08,
              ),
              gradient.colors.last.withValues(
                alpha: isSelected ? 0.20 : 0.04,
              ),
            ],
          ),
          border: Border.all(
            color: isSelected
                ? roleColor.withValues(alpha: 0.80)
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? AppShadows.glow(roleColor, intensity: 0.20)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Icône badge
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? gradient
                          : LinearGradient(
                              colors: [
                                roleColor.withValues(alpha: 0.20),
                                roleColor.withValues(alpha: 0.10),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _icon,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Texte
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.60),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Check icon
                  AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: roleColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
