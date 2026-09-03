import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/app_locale_controller.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_text_wordmark.dart';
import '../domain/app_role.dart';
import 'widgets/auth_choices.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  AppRole? _selectedRole;

  void _continue() {
    final role = _selectedRole;
    final route = switch (role) {
      AppRole.student || AppRole.parent => AppRoutes.phoneRegistration(role!),
      AppRole.teacher => AppRoutes.teacherRegistration,
      // Administration remains an internal, authorised route. It is never
      // proposed in the public INTELLIA PASS entry experience.
      AppRole.admin || null => null,
    };
    if (route != null) context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedLanguage = ref.watch(appLocaleProvider).languageCode;

    return AuthExperienceScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SegmentedButton<String>(
              key: const ValueKey('pass-language-selector'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'fr', label: Text('FR')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {selectedLanguage},
              onSelectionChanged: (selection) {
                unawaited(
                  ref
                      .read(appLocaleProvider.notifier)
                      .setLanguage(selection.first),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AuthHeader(
            eyebrow: l10n.passEyebrow,
            title: l10n.passTitle,
            titleWidget: _PassTitle(title: l10n.passTitle),
            subtitle: l10n.passSubtitle,
          ),
          const SizedBox(height: 26),
          AuthChoiceCard(
            key: const ValueKey('pass-role-student'),
            title: l10n.studentRole,
            description: l10n.studentRoleDescription,
            icon: Icons.school_rounded,
            accent: AuthExperienceColors.indigo,
            isSelected: _selectedRole == AppRole.student,
            onTap: () => setState(() => _selectedRole = AppRole.student),
          ),
          const SizedBox(height: 12),
          AuthChoiceCard(
            key: const ValueKey('pass-role-parent'),
            title: l10n.parentRole,
            description: l10n.parentRoleDescription,
            icon: Icons.family_restroom_rounded,
            accent: AuthExperienceColors.purple,
            isSelected: _selectedRole == AppRole.parent,
            onTap: () => setState(() => _selectedRole = AppRole.parent),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.professionalAccess.toUpperCase(),
            style: const TextStyle(
              color: AuthExperienceColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 9),
          Semantics(
            label: l10n.chooseIdentityA11y(l10n.teacherRole),
            button: true,
            child: OutlinedButton.icon(
              key: const ValueKey('pass-role-teacher'),
              onPressed: () => setState(() => _selectedRole = AppRole.teacher),
              icon: const Icon(Icons.menu_book_rounded),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${l10n.teacherRole} — ${l10n.teacherRoleDescription}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _selectedRole == AppRole.teacher
                    ? AuthExperienceColors.gold
                    : AuthExperienceColors.textPrimary,
                side: BorderSide(
                  color: _selectedRole == AppRole.teacher
                      ? AuthExperienceColors.gold
                      : AuthExperienceColors.border,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            label: l10n.continueLabel,
            onTap: _selectedRole == null ? null : _continue,
          ),
          const SizedBox(height: 22),
          Center(
            child: TextButton(
              onPressed: () => context.go(AppRoutes.login),
              style: TextButton.styleFrom(
                foregroundColor: AuthExperienceColors.gold,
              ),
              child: Text(l10n.existingAccount),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassTitle extends StatelessWidget {
  const _PassTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final parts = title.split('INTELLIA237');
    return Semantics(
      label: title,
      header: true,
      child: ExcludeSemantics(
        child: Intellia237TextWordmark(
          key: const ValueKey('pass-cameroon-wordmark'),
          prefix: parts.first,
          suffix: parts.length > 1 ? parts.last : '',
          wordmarkColor: AuthExperienceColors.indigo,
          maxLines: 2,
          style: const TextStyle(
            color: AuthExperienceColors.textPrimary,
            fontSize: 30,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
