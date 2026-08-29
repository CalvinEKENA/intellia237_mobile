import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
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
    const palette = TabPalette(TabPresentationMode.embeddedLight);

    return TabSurface(
      palette: palette,
      child: Scaffold(
        backgroundColor: IntelliaColors.backgroundPrimary,
        appBar: AppBar(title: const Text('Paramètres')),
        body: ListView(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          children: [
            _Section(
              title: 'Confort de lecture',
              children: [
                ListTile(
                  leading: const Icon(Icons.text_fields_rounded),
                  title: const Text('Taille du texte'),
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
                  title: const Text('Réduire les animations'),
                  subtitle: const Text(
                    'Remplace les mouvements décoratifs par des transitions sobres.',
                  ),
                  value: preferences.reduceMotion,
                  onChanged: controller.setReduceMotion,
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            _Section(
              title: 'Données et rappels',
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_rounded),
                  title: const Text('Mon objectif de la semaine'),
                  subtitle: Text(switch (ref
                      .watch(personalGoalControllerProvider)
                      .valueOrNull
                      ?.goal) {
                    null => 'Non défini — choisis ton rythme.',
                    final goal =>
                      '${goal.sessionsPerWeek} séances par semaine · '
                          '~${goal.minutesPerSession} min',
                  }),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showPersonalGoalSheet(context, ref),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.data_saver_on_rounded),
                  title: const Text('Économie de données'),
                  subtitle: const Text(
                    'Privilégie les contenus légers et limite les effets coûteux.',
                  ),
                  value: preferences.dataSaver,
                  onChanged: controller.setDataSaver,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Rappels d’apprentissage'),
                  subtitle: const Text(
                    'Un rappel au maximum par jour, activé seulement après ton autorisation système.',
                  ),
                  value: preferences.notifications,
                  onChanged: controller.setNotifications,
                ),
                if (preferences.notifications)
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Heure du rappel'),
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
                  title: const Text('Diagnostics anonymes'),
                  subtitle: const Text(
                    'Aide à repérer les pannes et parcours bloqués. Aucun message au compagnon, réponse libre, nom ou e-mail n’est collecté.',
                  ),
                  value: preferences.diagnostics,
                  onChanged: controller.setDiagnostics,
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            _Section(
              title: 'Confidentialité',
              children: [
                const ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Données personnelles'),
                  subtitle: Text(
                    'Intellia237 ne doit jamais envoyer les conversations pédagogiques dans les outils de mesure.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Suppression du compte'),
                  subtitle: const Text(
                    'Envoyer une demande de suppression sécurisée.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _requestAccountDeletion(context, ref),
                ),
                const LegalLinks(showEducationalData: true),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.md),
            _Section(
              title: 'Compte',
              children: [
                _EmailVerificationTile(
                  status: ref.watch(emailVerificationStatusProvider),
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Modifier mon profil'),
                  subtitle: const Text('Nom, téléphone et photo de profil.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Se déconnecter'),
                  subtitle: const Text(
                    'Tes données synchronisées seront disponibles à ta prochaine connexion.',
                  ),
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
        title: const Text('Demander la suppression ?'),
        content: const Text(
          'La demande sera enregistrée pour vérification et traitement sécurisé. Cette action te déconnectera.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Envoyer la demande'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d’envoyer la demande maintenant. Réessaie plus tard.',
          ),
        ),
      );
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
      helpText: 'Choisir l’heure du rappel',
      cancelText: 'Annuler',
      confirmText: 'Valider',
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
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Tes données synchronisées resteront disponibles à ta prochaine connexion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Se déconnecter'),
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
      loading: () => const ListTile(
        leading: Icon(Icons.mark_email_unread_outlined),
        title: Text('Vérification de l’adresse e-mail'),
        subtitle: LinearProgressIndicator(),
      ),
      error: (_, _) => ListTile(
        leading: const Icon(Icons.mark_email_unread_outlined),
        title: const Text('Vérification de l’adresse e-mail'),
        subtitle: const Text('Statut momentanément indisponible.'),
        trailing: IconButton(
          tooltip: 'Actualiser',
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
          value.isVerified ? 'Adresse e-mail vérifiée' : 'Vérifie ton e-mail',
        ),
        subtitle: Text(
          value.isVerified
              ? value.email
              : 'Protège ton compte et facilite sa récupération.',
        ),
        trailing: value.isVerified
            ? null
            : TextButton(
                onPressed: () => _send(context, ref),
                child: const Text('Renvoyer'),
              ),
      ),
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(emailVerificationServiceProvider).send();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'E-mail envoyé. Ouvre le lien reçu puis actualise ce statut.',
          ),
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
