import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../data/account_deletion_service.dart';

/// Demande de suppression : programme la suppression à J+7, affiche
/// l'échéance et permet d'annuler tant que le traitement n'a pas commencé.
class AccountDeletionTile extends ConsumerWidget {
  const AccountDeletionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final deletion =
        ref.watch(accountDeletionStateProvider).valueOrNull ??
        AccountDeletionState.none;
    final dueAt = deletion.dueAt;
    final subtitle = deletion.isScheduled && dueAt != null
        ? l10n.deleteScheduledSubtitle(_formatDate(context, dueAt))
        : deletion.isInProgress
        ? l10n.deleteInProgressSubtitle
        : l10n.deleteAccountDescription;
    return ListTile(
      leading: const Icon(Icons.delete_outline_rounded),
      title: Text(l10n.deleteAccountTitle),
      subtitle: Text(subtitle),
      trailing: deletion.isInProgress
          ? null
          : const Icon(Icons.chevron_right_rounded),
      onTap: deletion.isInProgress
          ? null
          : deletion.isScheduled
          ? () => _cancel(context, ref)
          : () => _request(context, ref),
    );
  }

  static String _formatDate(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date.toLocal());

  Future<void> _request(BuildContext context, WidgetRef ref) async {
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
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      final dueAt = await ref
          .read(accountDeletionServiceProvider)
          .requestDeletion();
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            dueAt == null
                ? l10n.deleteAccountDescription
                : l10n.deleteScheduledConfirmation(_formatDate(context, dueAt)),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.deleteRequestError)));
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.cancelDeletionQuestion),
        content: Text(context.l10n.cancelDeletionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.cancelDeletionAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(accountDeletionServiceProvider).cancelDeletion();
      messenger.showSnackBar(SnackBar(content: Text(l10n.cancelDeletionDone)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cancelDeletionError)));
    }
  }
}
