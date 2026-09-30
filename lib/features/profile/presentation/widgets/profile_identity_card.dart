import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/presentation/widgets/living_pass.dart' show passRoleLabel;
import '../../../learn/application/learn_providers.dart';
import '../../../mastery/application/mastery_providers.dart';
import '../edit_profile_screen.dart';
import 'profile_surfaces.dart';
import '../../widgets/profile_avatar.dart';

/// A personal INTELLIA PASS, not a subscription or verified-school badge.
/// The identity survives missing network data; no learning metric is fabricated.
class IntelliaProfileIdentityCard extends ConsumerWidget {
  const IntelliaProfileIdentityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final profile = ref.watch(editableProfileProvider).valueOrNull;
    final academic = ref.watch(studentAcademicContextProvider);
    final school = ref.watch(profileDeclaredEstablishmentProvider).valueOrNull;
    final name = auth.firstName?.trim();
    final displayName = name?.isNotEmpty == true
        ? name!
        : context.l10n.intelliaUser;
    final level = academic.valueOrNull;
    final details = level == null
        ? passRoleLabel(context, auth.role)
        : [
            level.displayClassLevel ?? level.classLevel,
            if (level.series?.isNotEmpty == true)
              '${context.l10n.seriesLabel} ${level.series}',
          ].join(' · ');
    return Container(
      key: const ValueKey('profile-identity-card'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFEDF9), Color(0xFFFEFDFC), Color(0xFFF2EFF8)],
        ),
        borderRadius: BorderRadius.circular(IntelliaRadii.extraLarge),
        border: Border.all(color: Colors.white),
        boxShadow: IntelliaShadows.premium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INTELLIA PASS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: IntelliaColors.brandIndigo,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, box) {
              final vertical =
                  box.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              final identity = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    key: const ValueKey('mastery-learner-name'),
                    style: IntelliaTypography.hero().copyWith(fontSize: 34),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details,
                    style: IntelliaTypography.caption().copyWith(
                      color: IntelliaColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (academic.hasError) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.loadErrorLabel,
                      style: IntelliaTypography.caption().copyWith(
                        color: IntelliaColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              );
              final avatar = ProfileAvatar(
                photoUrl: profile?.photoUrl,
                name: displayName,
                radius: 38,
              );
              if (vertical) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [avatar, const SizedBox(height: 16), identity],
                );
              }
              return Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 16),
                  avatar,
                ],
              );
            },
          ),
          if (school != null) ...[
            const SizedBox(height: 14),
            Text(
              context.l10n.masteryDeclaredSchool(school),
              style: IntelliaTypography.caption().copyWith(
                color: IntelliaColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0x195856D6)),
          const SizedBox(height: 8),
          CupertinoButton(
            key: const ValueKey('profile-edit-action'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.centerLeft,
            onPressed: () {
              profileSelectionHaptic(ref);
              context.push(AppRoutes.editProfile);
            },
            child: Row(
              children: [
                const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: IntelliaColors.brandIndigo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.editProfileTitle,
                    style: IntelliaTypography.body().copyWith(
                      color: IntelliaColors.brandIndigo,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: IntelliaColors.brandIndigo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
