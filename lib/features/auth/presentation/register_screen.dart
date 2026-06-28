import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../domain/app_role.dart';
import 'widgets/auth_choices.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  AppRole? _selectedRole;

  void _continue() {
    final route = switch (_selectedRole) {
      AppRole.student => AppRoutes.studentRegistration,
      AppRole.parent => AppRoutes.parentRegistration,
      AppRole.teacher => AppRoutes.teacherRegistration,
      AppRole.admin => AppRoutes.adminRegistration,
      null => null,
    };
    if (route != null) context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AuthExperienceScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            eyebrow: 'Une expérience à votre mesure',
            title: 'Choisissez votre\nprofil.',
            subtitle:
                'Chaque espace propose des outils et un parcours adaptés.',
          ),
          const SizedBox(height: 26),
          ...AppRole.values.indexed.map((entry) {
            final role = entry.$2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  AuthChoiceCard(
                        title: role.label,
                        description: _description(role),
                        icon: _icon(role),
                        accent: _accent(role),
                        isSelected: _selectedRole == role,
                        onTap: () => setState(() => _selectedRole = role),
                      )
                      .animate(
                        target: reduceMotion ? 0 : 1,
                        delay: Duration(milliseconds: 90 * entry.$1),
                      )
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.05, end: 0),
            );
          }),
          const SizedBox(height: 14),
          AuthPrimaryButton(
            label: 'Continuer',
            onTap: _selectedRole == null ? null : _continue,
          ),
          const SizedBox(height: 22),
          Center(
            child: TextButton(
              onPressed: () => context.go(AppRoutes.login),
              style: TextButton.styleFrom(
                foregroundColor: AuthExperienceColors.gold,
              ),
              child: const Text('J’ai déjà un compte'),
            ),
          ),
        ],
      ),
    );
  }

  String _description(AppRole role) => switch (role) {
    AppRole.student => 'Apprendre, s’entraîner et progresser avec Kira ou Léo.',
    AppRole.parent => 'Suivre les progrès et accompagner avec sérénité.',
    AppRole.teacher => 'Préparer ses classes et partager ses ressources.',
    AppRole.admin => 'Piloter les accès après validation de votre demande.',
  };

  IconData _icon(AppRole role) => switch (role) {
    AppRole.student => Icons.school_rounded,
    AppRole.parent => Icons.family_restroom_rounded,
    AppRole.teacher => Icons.menu_book_rounded,
    AppRole.admin => Icons.admin_panel_settings_rounded,
  };

  Color _accent(AppRole role) => switch (role) {
    AppRole.student => AuthExperienceColors.indigo,
    AppRole.parent => AuthExperienceColors.purple,
    AppRole.teacher => const Color(0xFF35C8A0),
    AppRole.admin => AuthExperienceColors.champagne,
  };
}
