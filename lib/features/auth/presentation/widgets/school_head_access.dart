import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/localization_extensions.dart';
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

  static const _note = TextStyle(
    fontFamily: 'CampaignBody',
    fontSize: 12,
    height: 1.4,
    color: AuthExperienceColors.textTertiary,
  );

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
              key: const ValueKey('school-head-email'),
              label: l10n.schoolHeadContinueEmail,
              icon: Icons.alternate_email_rounded,
              onTap: () => onRoute(AppRoutes.emailLogin),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('school-head-phone'),
              onPressed: () => onRoute(AppRoutes.login),
              icon: const Icon(Icons.phone_iphone_rounded),
              label: Text(l10n.schoolHeadContinuePhone),
              style: OutlinedButton.styleFrom(
                foregroundColor: AuthExperienceColors.textPrimary,
                side: const BorderSide(color: AuthExperienceColors.border),
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.schoolHeadPhoneNote,
              textAlign: TextAlign.center,
              style: _note,
            ),
            const SizedBox(height: 14),
            TextButton(
              key: const ValueKey('school-head-request'),
              onPressed: () => onRoute(AppRoutes.adminRegistration),
              child: Text(l10n.schoolHeadRequestAccess),
            ),
          ],
        ),
      ),
    );
  }
}
