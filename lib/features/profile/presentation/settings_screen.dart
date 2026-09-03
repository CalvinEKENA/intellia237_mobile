import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../../student_home/application/personal_goal_providers.dart';
import '../../student_home/presentation/widgets/weekly_goal_card.dart';
import '../application/user_preferences_controller.dart';
import '../../legal/presentation/legal_links.dart';
import '../../auth/application/auth_controller.dart';
import '../data/account_deletion_service.dart';
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
        backgroundColor: IntelliaColors.backgroundPrimary,
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: ListView(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          children: [
            _Section(
              title: l10n.readingComfortSection,
              children: [
                ListTile(
                  leading: const Icon(Icons.text_fields_rounded),
                  title: Text(l10n.textSizeLabel),
                  subtitle: Slider(
                    value: preferences.textScale,
                    min: 0.9,
                    max: 1.5,
                    divisions: 6,
                    label: '${(preferences.textScale * 100).round()} %',
                    onChanged: controller.setTextScale,
                  ),
                  trailing: Text('${(preferences.textScale * 100).round()} %'),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.animation_rounded),
                  title: Text(l10n.reduceMotionLabel),
                  subtitle: Text(l10n.reduceMotionDescription),
                  value: preferences.reduceMotion,
                  onChanged: controller.setReduceMotion,
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            _Section(
              title: l10n.dataRemindersSection,
              children: [
                ListTile(
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
                SwitchListTile(
                  secondary: const Icon(Icons.data_saver_on_rounded),
                  title: Text(l10n.dataSaverLabel),
                  subtitle: Text(l10n.dataSaverDescription),
                  value: preferences.dataSaver,
                  onChanged: controller.setDataSaver,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none_rounded),
                  title: Text(l10n.learningRemindersLabel),
                  subtitle: Text(l10n.learningRemindersDescription),
                  value: preferences.notifications,
                  onChanged: controller.setNotifications,
                ),
                if (preferences.notifications)
                  ListTile(
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
                SwitchListTile(
                  secondary: const Icon(Icons.monitor_heart_outlined),
                  title: Text(l10n.anonymousDiagnosticsLabel),
                  subtitle: Text(l10n.anonymousDiagnosticsDescription),
                  value: preferences.diagnostics,
                  onChanged: controller.setDiagnostics,
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            _Section(
              title: l10n.privacySection,
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.personalDataTitle),
                  subtitle: Text(l10n.personalDataDescription),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: Text(l10n.deleteAccountTitle),
                  subtitle: Text(l10n.deleteAccountDescription),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _requestAccountDeletion(context, ref),
                ),
                const LegalLinks(showEducationalData: true),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            _Section(
              title: l10n.accountSection,
              children: [
                if ((auth.email ?? '').trim().isNotEmpty)
                  _EmailVerificationTile(
                    status: ref.watch(emailVerificationStatusProvider),
                  ),
                ListTile(
                  leading: const Icon(Icons.phone_android_rounded),
                  title: Text(l10n.addPhoneTitle),
                  subtitle: Text(l10n.addPhoneDescription),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('${AppRoutes.phoneAuth}?mode=link'),
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: Text(l10n.editProfileTitle),
                  subtitle: Text(l10n.editProfileDescription),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                ListTile(
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

  Future<void> _requestAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteRequestQuestion),
        content: Text(context.l10n.deleteRequestBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.sendRequestLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await AccountDeletionService().requestDeletion();
      await ref.read(authControllerProvider.notifier).signOut();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.deleteRequestError)));
    }
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
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.signOutQuestion),
        content: Text(context.l10n.signOutDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
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
      loading: () => ListTile(
        leading: const Icon(Icons.mark_email_unread_outlined),
        title: Text(context.l10n.emailVerificationTitle),
        subtitle: const LinearProgressIndicator(),
      ),
      error: (_, _) => ListTile(
        leading: const Icon(Icons.mark_email_unread_outlined),
        title: Text(context.l10n.emailVerificationTitle),
        subtitle: Text(context.l10n.statusUnavailable),
        trailing: IconButton(
          tooltip: context.l10n.refreshLabel,
          onPressed: () => ref.invalidate(emailVerificationStatusProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
      data: (value) => ListTile(
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = TabSurface.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.md,
              IntelliaSpacing.md,
              IntelliaSpacing.md,
              IntelliaSpacing.xs,
            ),
            child: Text(
              title,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
