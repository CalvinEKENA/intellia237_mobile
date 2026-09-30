import '../../auth/domain/app_role.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../../student_home/application/personal_goal_providers.dart';
import '../../student_home/presentation/widgets/weekly_goal_card.dart';
import '../../rewards/domain/haptic_pattern.dart';
import '../application/user_preferences_controller.dart';
import '../../legal/presentation/legal_links.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/widgets/living_pass.dart' show passRoleLabel;
import 'widgets/profile_surfaces.dart';
import 'widgets/account_deletion_tile.dart';
import '../data/email_verification_service.dart';

final emailVerificationServiceProvider = Provider<EmailVerificationService>((
  ref,
) {
  return EmailVerificationService();
});

final emailVerificationStatusProvider = FutureProvider<EmailVerificationStatus>(
  (ref) {
    return ref.watch(emailVerificationServiceProvider).status();
  },
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);
    final controller = ref.read(userPreferencesProvider.notifier);
    final auth = ref.watch(authControllerProvider);
    final l10n = context.l10n;
    const palette = TabPalette(TabPresentationMode.embeddedLight);

    return TabSurface(
      palette: palette,
      child: Scaffold(
        backgroundColor: IntelliaColors.backgroundPremium,
        appBar: AppBar(
          backgroundColor: IntelliaColors.backgroundPremium,
          scrolledUnderElevation: 0,
          title: Text(l10n.settingsTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          children: [
            Text(l10n.settingsDescription, style: IntelliaTypography.body()),
            const SizedBox(height: IntelliaSpacing.md),
            IntelliaProfileSection(
              title: l10n.readingComfortSection,
              children: [
                IntelliaProfileTile(
                  leading: const Icon(Icons.text_fields_rounded),
                  title: Text(l10n.textSizeLabel),
                  stackTrailing: true,
                  subtitle: CupertinoSlider(
                    value: preferences.textScale,
                    min: 0.9,
                    max: 1.5,
                    divisions: 6,
                    onChanged: controller.setTextScale,
                  ),
                  trailing: Text('${(preferences.textScale * 100).round()} %'),
                ),
                IntelliaProfileSwitch(
                  icon: Icons.animation_rounded,
                  title: l10n.reduceMotionLabel,
                  subtitle: l10n.reduceMotionDescription,
                  value: preferences.reduceMotion,
                  onChanged: controller.setReduceMotion,
                ),
                // Vibrations pédagogiques : trois choix lisibles en entier,
                // même en grand texte (pas de segments qui se tronquent).
                IntelliaProfileTile(
                  leading: const Icon(Icons.vibration_rounded),
                  title: Text(l10n.hapticsLabel),
                  subtitle: Text(l10n.hapticsDescription),
                ),
                for (final (mode, label) in [
                  (HapticMode.on, l10n.hapticsOn),
                  (HapticMode.reduced, l10n.hapticsReduced),
                  (HapticMode.off, l10n.hapticsOff),
                ])
                  IntelliaProfileTile(
                    key: ValueKey('haptics-${mode.name}'),
                    title: Text(label),
                    selected: preferences.haptics == mode,
                    trailing: Icon(
                      preferences.haptics == mode
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: IntelliaColors.brandIndigo,
                    ),
                    onTap: () => controller.setHaptics(mode),
                  ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            IntelliaProfileSection(
              title: l10n.dataRemindersSection,
              children: [
                IntelliaProfileTile(
                  leading: const Icon(Icons.flag_rounded),
                  title: Text(l10n.weeklyGoalTitle),
                  subtitle: Text(switch (ref
                      .watch(personalGoalControllerProvider)
                      .valueOrNull
                      ?.goal) {
                    null => l10n.weeklyGoalUnset,
                    final goal => l10n.weeklyGoalSummary(
                      goal.sessionsPerWeek,
                      goal.minutesPerSession,
                    ),
                  }),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showPersonalGoalSheet(context, ref),
                ),
                IntelliaProfileSwitch(
                  icon: Icons.data_saver_on_rounded,
                  title: l10n.dataSaverLabel,
                  subtitle: l10n.dataSaverDescription,
                  value: preferences.dataSaver,
                  onChanged: controller.setDataSaver,
                ),
                IntelliaProfileSwitch(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.learningRemindersLabel,
                  subtitle: l10n.learningRemindersDescription,
                  value: preferences.notifications,
                  onChanged: controller.setNotifications,
                ),
                if (preferences.notifications)
                  IntelliaProfileTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: Text(l10n.reminderTimeLabel),
                    subtitle: Text(
                      TimeOfDay(
                        hour: preferences.reminderHour,
                        minute: preferences.reminderMinute,
                      ).format(context),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        _chooseReminderTime(context, controller, preferences),
                  ),
                IntelliaProfileSwitch(
                  icon: Icons.monitor_heart_outlined,
                  title: l10n.anonymousDiagnosticsLabel,
                  subtitle: l10n.anonymousDiagnosticsDescription,
                  value: preferences.diagnostics,
                  onChanged: controller.setDiagnostics,
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            IntelliaProfileSection(
              title: l10n.privacySection,
              children: [
                IntelliaProfileTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.personalDataTitle),
                  subtitle: Text(l10n.personalDataDescription),
                ),
                const AccountDeletionTile(),
                const LegalLinks(showEducationalData: true),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            IntelliaProfileSection(
              title: '${l10n.accountSection} · ${l10n.stepSecurity}',
              children: [
                if ((auth.email ?? '').trim().isNotEmpty)
                  _EmailVerificationTile(
                    status: ref.watch(emailVerificationStatusProvider),
                  ),
                IntelliaProfileTile(
                  leading: const Icon(Icons.phone_android_rounded),
                  title: Text(l10n.addPhoneTitle),
                  subtitle: Text(l10n.addPhoneDescription),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('${AppRoutes.phoneAuth}?mode=link'),
                ),
                if (auth.role == AppRole.student)
                  IntelliaProfileTile(
                    key: const ValueKey('settings-parent-space'),
                    leading: const Icon(Icons.family_restroom_rounded),
                    title: Text(l10n.authParentSpace),
                    subtitle: Text(l10n.authParentProofContinue),
                    trailing: const Icon(Icons.lock_outline_rounded),
                    onTap: () => context.push(AppRoutes.parentAccess),
                  ),
                if (auth.isMultiRole)
                  IntelliaProfileTile(
                    key: const ValueKey('role-switch-action'),
                    leading: const Icon(Icons.swap_horiz_rounded),
                    title: Text(l10n.authSwitchSpace),
                    subtitle: Text(
                      '${l10n.authSpaceCurrent} : ${passRoleLabel(context, auth.role)}\n'
                      '${l10n.authSwitchSpaceHint}',
                    ),
                    onTap: () => context.push(AppRoutes.roleChooser),
                  ),
                IntelliaProfileTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: Text(l10n.editProfileTitle),
                  subtitle: Text(l10n.editProfileDescription),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                IntelliaProfileTile(
                  destructive: true,
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(l10n.signOutTitle),
                  subtitle: Text(l10n.signOutDescription),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _confirmSignOut(context, ref),
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseReminderTime(
    BuildContext context,
    UserPreferencesController controller,
    UserPreferences preferences,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: preferences.reminderHour,
        minute: preferences.reminderMinute,
      ),
      helpText: context.l10n.chooseReminderTime,
      cancelText: context.l10n.cancelLabel,
      confirmText: context.l10n.confirmLabel,
    );
    if (selected == null) return;
    await controller.setReminderTime(
      hour: selected.hour,
      minute: selected.minute,
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: profileDialogAnimation(context, ref),
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(context.l10n.signOutQuestion),
        content: Text(context.l10n.signOutDescription),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancelLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.signOutTitle),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

class _EmailVerificationTile extends ConsumerWidget {
  const _EmailVerificationTile({required this.status});

  final AsyncValue<EmailVerificationStatus> status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return status.when(
      loading: () => IntelliaProfileTile(
        leading: const Icon(Icons.mark_email_unread_outlined),
        title: Text(context.l10n.emailVerificationTitle),
        subtitle: const LinearProgressIndicator(),
      ),
      error: (_, _) => IntelliaProfileTile(
        leading: const Icon(Icons.mark_email_unread_outlined),
        title: Text(context.l10n.emailVerificationTitle),
        subtitle: Text(context.l10n.statusUnavailable),
        trailing: IconButton(
          tooltip: context.l10n.refreshLabel,
          onPressed: () => ref.invalidate(emailVerificationStatusProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
      data: (value) => IntelliaProfileTile(
        leading: Icon(
          value.isVerified
              ? Icons.verified_rounded
              : Icons.mark_email_unread_outlined,
          color: value.isVerified ? IntelliaColors.success : null,
        ),
        title: Text(
          value.isVerified
              ? context.l10n.emailVerifiedTitle
              : context.l10n.verifyEmailTitle,
        ),
        subtitle: Text(
          value.isVerified
              ? value.email
              : context.l10n.emailRecoveryDescription,
        ),
        stackTrailing: true,
        trailing: value.isVerified
            ? null
            : TextButton(
                onPressed: () => _send(context, ref),
                child: Text(context.l10n.resendLabel),
              ),
      ),
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(emailVerificationServiceProvider).send();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.emailVerificationSent),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on EmailVerificationException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
