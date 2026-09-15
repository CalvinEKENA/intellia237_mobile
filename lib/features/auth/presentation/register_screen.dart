import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/app_locale_controller.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_text_wordmark.dart';
import '../../parent/application/pending_child_link.dart';
import '../domain/app_role.dart';
import 'widgets/auth_choices.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/intellia_237_membrane.dart';
import 'widgets/living_pass.dart';
import 'widgets/pass_auth_progress.dart';
import 'widgets/school_head_access.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  AppRole? _selectedRole;

  void _continue() {
    if (_selectedRole != AppRole.parent) {
      // Un autre espace que parent abandonne tout code enfant retenu.
      ref.read(pendingChildLinkProvider.notifier).clear();
    }
    final route = switch (_selectedRole) {
      AppRole.student => AppRoutes.phoneRegistration(AppRole.student),
      // Le parent commence par le code de son enfant.
      AppRole.parent => AppRoutes.parentEntry,
      AppRole.teacher => AppRoutes.teacherRegistration,
      AppRole.admin || null => null,
    };
    if (route != null) context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedLanguage = ref.watch(appLocaleProvider).languageCode;
    return AuthExperienceScaffold(
      topBar: Row(
        children: [
          const Expanded(
            child: Intellia237TextWordmark(
              key: ValueKey('pass-cameroon-wordmark'),
              style: TextStyle(
                color: AuthExperienceColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SchoolHeadShield(),
          const SizedBox(width: 4),
          SegmentedButton<String>(
            key: const ValueKey('pass-language-selector'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'fr', label: Text('FR')),
              ButtonSegment(value: 'en', label: Text('EN')),
            ],
            selected: {selectedLanguage},
            onSelectionChanged: (selection) => unawaited(
              ref.read(appLocaleProvider.notifier).setLanguage(selection.first),
            ),
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
      pass: LivingPass(
        role: _selectedRole,
        phase: context.l10n.passChooseYourSpace,
        progress: _selectedRole == null
            ? PassAuthProgress.empty
            : PassAuthProgress.spaceChosen,
        // Choisir un espace n'est pas encore s'identifier.
        seal: PassSealStage.neutral,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            showBrand: false,
            eyebrow: context.l10n.passCreateAnAccount,
            title: context.l10n.passYourPlaceStartsHere,
            subtitle: context.l10n.passChooseYourSpaceYourPassTakes,
          ),
          const SizedBox(height: 23),
          AuthChoiceCard(
            key: const ValueKey('pass-role-student'),
            title: l10n.studentRole,
            description: l10n.studentRoleDescription,
            icon: Icons.school_outlined,
            isSelected: _selectedRole == AppRole.student,
            onTap: () => setState(() => _selectedRole = AppRole.student),
          ),
          const SizedBox(height: 10),
          AuthChoiceCard(
            key: const ValueKey('pass-role-parent'),
            title: l10n.parentRole,
            description: l10n.parentRoleDescription,
            icon: Icons.family_restroom_outlined,
            isSelected: _selectedRole == AppRole.parent,
            onTap: () => setState(() => _selectedRole = AppRole.parent),
          ),
          const SizedBox(height: 10),
          AuthChoiceCard(
            key: const ValueKey('pass-role-teacher'),
            title: l10n.teacherRole,
            description: l10n.teacherRoleDescription,
            icon: Icons.menu_book_outlined,
            isSelected: _selectedRole == AppRole.teacher,
            onTap: () => setState(() => _selectedRole = AppRole.teacher),
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            key: const ValueKey('pass-continue'),
            label: l10n.continueLabel,
            onTap: _selectedRole == null ? null : _continue,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(AppRoutes.authGateway),
            child: Text(l10n.existingAccount),
          ),
        ],
      ),
    );
  }
}
