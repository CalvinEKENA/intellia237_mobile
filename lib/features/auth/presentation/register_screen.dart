import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_scaffold.dart';
import '../../../core/widgets/intellia_buttons.dart';
import '../../../core/widgets/intellia_card.dart';
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
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(IntelliaRadii.small),
            ),
            margin: const EdgeInsets.all(IntelliaSpacing.md),
          ),
        );
      return;
    }

    final route = switch (role) {
      AppRole.student => AppRoutes.studentRegistration,
      AppRole.parent => AppRoutes.parentRegistration,
      AppRole.teacher => AppRoutes.teacherRegistration,
      AppRole.admin => AppRoutes.adminRegistration,
    };

    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IntelliaScaffold(
      usePremiumBackground: true,
      showTopHalo: true,
      appBar: AppBar(
        leading: IntelliaIconButton(
          icon: Icons.arrow_back_rounded,
          backgroundColor: Colors.transparent,
          onTap: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: IntelliaSpacing.lg,
          vertical: IntelliaSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: IntelliaSpacing.md),

            Text(
              'Quel est\nvotre profil ?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
                height: 1.15,
                color: isDark
                    ? IntelliaColors.textPrimaryDark
                    : IntelliaColors.textPrimary,
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              'Choisissez votre profil pour accéder à une expérience personnalisée.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? IntelliaColors.textSecondaryDark
                    : IntelliaColors.textSecondary,
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: IntelliaSpacing.xl),

            // Role selection cards
            ...AppRole.values.indexed.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: IntelliaSpacing.md),
                child:
                    _RoleCard(
                          role: entry.$2,
                          isSelected: _selectedRole == entry.$2,
                          onTap: () => setState(() => _selectedRole = entry.$2),
                        )
                        .animate(delay: (200 + entry.$1 * 100).ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.04, end: 0),
              ),
            ),

            const SizedBox(height: IntelliaSpacing.xl),

            // Continue CTA
            IntelliaPrimaryButton(
              onTap: _selectedRole != null ? _continue : null,
              child: const Text('Continuer'),
            ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: IntelliaSpacing.xl),
          ],
        ),
      ),
    );
  }
}

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
    AppRole.parent => Icons.family_restroom_rounded,
    AppRole.teacher => Icons.menu_book_rounded,
    AppRole.admin => Icons.admin_panel_settings_rounded,
  };

  String get _label => switch (role) {
    AppRole.student => 'Élève',
    AppRole.parent => 'Parent',
    AppRole.teacher => 'Enseignant',
    AppRole.admin => 'Administrateur',
  };

  String get _description => switch (role) {
    AppRole.student => 'Prépare ton BEPC, Probatoire ou Baccalauréat',
    AppRole.parent => 'Suivez les progrès de vos enfants',
    AppRole.teacher => 'Gérez vos classes et contenus',
    AppRole.admin => 'Administrez la plateforme',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final roleColor = switch (role) {
      AppRole.student => IntelliaColors.brandIndigo,
      AppRole.parent => IntelliaColors.brandPurple,
      AppRole.teacher => IntelliaColors.success,
      AppRole.admin => IntelliaColors.error,
    };

    final roleGradient = switch (role) {
      AppRole.student => IntelliaGradients.leo,
      AppRole.parent => IntelliaGradients.kira,
      AppRole.teacher => const LinearGradient(
        colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
      ),
      AppRole.admin => const LinearGradient(
        colors: [Color(0xFFBE123C), Color(0xFFF43F5E)],
      ),
    };

    return IntelliaCard(
      variant: isSelected
          ? IntelliaCardVariant.elevated
          : IntelliaCardVariant.solid,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IntelliaRadii.large),
            border: isSelected
                ? Border.all(color: roleColor, width: 2.0)
                : Border.all(color: theme.colorScheme.outline, width: 0.8),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      roleColor.withValues(alpha: 0.15),
                      roleColor.withValues(alpha: 0.05),
                    ],
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: IntelliaSpacing.md,
            vertical: IntelliaSpacing.sm,
          ),
          child: Row(
            children: [
              // Icon Badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: roleGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, size: 26, color: Colors.white),
              ),
              const SizedBox(width: IntelliaSpacing.md),

              // Title and Description
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label,
                      style: TextStyle(
                        color: isDark
                            ? IntelliaColors.textPrimaryDark
                            : IntelliaColors.textPrimary,
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _description,
                      style: TextStyle(
                        color: isDark
                            ? IntelliaColors.textSecondaryDark
                            : IntelliaColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Check selector icon
              AnimatedOpacity(
                duration: IntelliaMotion.fast,
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: roleColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
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
