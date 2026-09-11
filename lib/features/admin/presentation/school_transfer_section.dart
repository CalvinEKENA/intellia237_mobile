import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/admin_providers.dart';
import '../domain/account_school_record.dart';
import 'admin_presentation_localization.dart';
import 'attach_school_sheet.dart';

/// Changer un compte d'école : erreur à l'inscription, déménagement, mutation.
///
/// Registre de décisions : seule l'administration générale le fait. Un
/// déplacement exige un motif, gardé pour l'audit ; le serveur retire le
/// compte des classes de son ancienne école. Une direction d'établissement
/// n'ajoute ni ne retire jamais un élève.
class SchoolTransferSection extends ConsumerStatefulWidget {
  const SchoolTransferSection({super.key});

  @override
  ConsumerState<SchoolTransferSection> createState() =>
      _SchoolTransferSectionState();
}

class _SchoolTransferSectionState extends ConsumerState<SchoolTransferSection> {
  final _query = TextEditingController();
  bool _searching = false;
  List<AccountSchoolRecord>? _results;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final failure = context.l10n.accountReviewFailed;
    setState(() => _searching = true);
    try {
      final results = await ref.read(adminActionsProvider).searchAccounts(query);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _change(AccountSchoolRecord record) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(adminActionsProvider);
    final establishmentId = await showAttachSchoolSheet(
      context,
      body: record.hasSchool
          ? l10n.schoolTransferMoveBody
          : l10n.schoolTransferAttachBody,
      initialName: record.declaredSchoolName.isEmpty
          ? null
          : record.declaredSchoolName,
      initialCity: record.declaredSchoolCity.isEmpty
          ? null
          : record.declaredSchoolCity,
    );
    if (establishmentId == null || !mounted) return;
    if (establishmentId == record.establishmentId) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.schoolTransferSameSchool)),
      );
      return;
    }

    String? reason;
    if (record.hasSchool) {
      reason = await showDialog<String>(
        context: context,
        builder: (_) => const _TransferReasonDialog(),
      );
      if (reason == null) return;
    }
    try {
      await actions.changeAccountEstablishment(
        accountId: record.id,
        establishmentId: establishmentId,
        reason: reason,
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.schoolTransferDone)));
      await _search();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountReviewFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results = _results;
    return Column(
      key: const ValueKey('school-transfer'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.schoolTransferTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        Text(
          l10n.schoolTransferBody,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('school-transfer-query'),
                controller: _query,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: l10n.schoolTransferQueryLabel,
                  hintText: l10n.schoolTransferQueryHint,
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: IntelliaSpacing.sm),
            FilledButton(
              key: const ValueKey('school-transfer-search'),
              onPressed: _searching ? null : _search,
              child: Text(l10n.schoolTransferSearch),
            ),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        if (_searching)
          const Padding(
            padding: EdgeInsets.all(IntelliaSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (results != null && results.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              child: Text(l10n.schoolTransferNoResult),
            ),
          )
        else
          for (final record in results ?? const <AccountSchoolRecord>[])
            _AccountCard(record: record, onChange: _change),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.record, required this.onChange});

  final AccountSchoolRecord record;
  final ValueChanged<AccountSchoolRecord> onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final contact = [
      adminRoleLabel(context, record.role),
      if (record.email.isNotEmpty) record.email,
      if (record.phone.isNotEmpty) record.phone,
    ].join(' · ');
    final declared = record.declaredSchoolCity.isEmpty
        ? record.declaredSchoolName
        : '${record.declaredSchoolName} (${record.declaredSchoolCity})';

    return Card(
      key: ValueKey('school-transfer-record-${record.id}'),
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: IntelliaSpacing.sm),
                FilledButton.tonal(
                  key: ValueKey('school-transfer-change-${record.id}'),
                  onPressed: () => onChange(record),
                  child: Text(
                    record.hasSchool
                        ? l10n.schoolTransferMove
                        : l10n.attachStaffAction,
                  ),
                ),
              ],
            ),
            Text(contact, style: theme.textTheme.bodySmall),
            const SizedBox(height: IntelliaSpacing.xxs),
            Text(
              record.hasSchool
                  ? l10n.schoolTransferCurrentSchool(
                      record.establishmentName.isEmpty
                          ? record.establishmentId!
                          : record.establishmentName,
                    )
                  : l10n.reviewNoSchool,
            ),
            if (record.declaredSchoolName.isNotEmpty)
              Text(
                l10n.schoolTransferDeclared(declared),
                style: theme.textTheme.bodySmall,
              ),
            if (record.children.isNotEmpty) ...[
              const SizedBox(height: IntelliaSpacing.sm),
              Text(l10n.schoolTransferChildren, style: theme.textTheme.labelLarge),
              for (final child in record.children)
                Padding(
                  padding: const EdgeInsets.only(top: IntelliaSpacing.xs),
                  child: _AccountCard(record: child, onChange: onChange),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransferReasonDialog extends StatefulWidget {
  const _TransferReasonDialog();

  @override
  State<_TransferReasonDialog> createState() => _TransferReasonDialogState();
}

class _TransferReasonDialogState extends State<_TransferReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ready = _reason.text.trim().length >= 5;
    return AlertDialog(
      title: Text(l10n.schoolTransferReasonTitle),
      content: TextField(
        key: const ValueKey('school-transfer-reason'),
        controller: _reason,
        autofocus: true,
        maxLength: 280,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(hintText: l10n.schoolTransferReasonHint),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          key: const ValueKey('school-transfer-reason-confirm'),
          onPressed: ready
              ? () => Navigator.of(context).pop(_reason.text.trim())
              : null,
          child: Text(l10n.schoolTransferConfirm),
        ),
      ],
    );
  }
}
