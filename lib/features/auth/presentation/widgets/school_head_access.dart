import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../auth/domain/app_role.dart';
import 'auth_controls.dart';
import 'auth_experience_scaffold.dart';
import 'living_pass.dart';

/// L'entrée discrète de la direction d'établissement.
///
/// Un bouclier plutôt qu'un bouton : l'écran d'entrée appartient aux élèves et
/// aux familles, et la direction sait où regarder.
class SchoolHeadShield extends StatelessWidget {
  const SchoolHeadShield({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('school-head-shield'),
    tooltip: context.l10n.schoolHeadShieldTooltip,
    onPressed: () => showSchoolHeadAccessSheet(context),
    visualDensity: VisualDensity.compact,
    icon: const Icon(
      Icons.shield_outlined,
      size: 20,
      color: AuthExperienceColors.textTertiary,
    ),
  );
}

Future<void> showSchoolHeadAccessSheet(BuildContext context) {
  // Le routeur est saisi avant l'ouverture : la feuille se referme d'abord,
  // puis la navigation part depuis l'écran qui l'a ouverte.
  final router = GoRouter.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AuthExperienceColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _SchoolHeadAccessSheet(
      onRoute: (route) {
        Navigator.of(sheetContext).pop();
        router.push(route);
      },
    ),
  );
}

class _SchoolHeadAccessSheet extends StatelessWidget {
  const _SchoolHeadAccessSheet({required this.onRoute});

  final ValueChanged<String> onRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('school-head-sheet'),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AuthExperienceColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AuthExperienceColors.indigo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.schoolHeadSheetEyebrow,
                    style: const TextStyle(
                      fontFamily: 'CampaignBody',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: AuthExperienceColors.indigo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(l10n.schoolHeadSheetTitle, style: passDisplay(size: 38)),
            const SizedBox(height: 12),
            Text(
              l10n.schoolHeadSheetBody,
              style: const TextStyle(
                fontFamily: 'CampaignBody',
                fontSize: 14,
                height: 1.5,
                color: AuthExperienceColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              key: const ValueKey('school-staff-teacher'),
              label: l10n.authStaffTeacher,
              icon: Icons.cast_for_education_rounded,
              onTap: () => onRoute(AppRoutes.emailSignIn(AppRole.teacher)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('school-staff-direction'),
              onPressed: () => onRoute(AppRoutes.emailSignIn(AppRole.admin)),
              icon: const Icon(Icons.school_outlined),
              label: Text(l10n.authStaffDirection, textAlign: TextAlign.center),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('school-staff-administration'),
              onPressed: () => onRoute(
                '${AppRoutes.emailSignIn(AppRole.admin)}&scope=global',
              ),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: Text(
                l10n.authStaffAdministration,
                textAlign: TextAlign.center,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
