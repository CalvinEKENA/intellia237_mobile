import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/cameroon_phone_number.dart';
import '../application/admin_account_management_service.dart';
import 'attach_school_sheet.dart';

class AccountManagementMenu extends ConsumerStatefulWidget {
  const AccountManagementMenu({
    required this.accountId,
    required this.name,
    required this.status,
    this.onChanged,
    super.key,
  });
  final String accountId;
  final String name;
  final String status;
  final VoidCallback? onChanged;

  @override
  ConsumerState<AccountManagementMenu> createState() =>
      _AccountManagementMenuState();
}

class _AccountManagementMenuState extends ConsumerState<AccountManagementMenu> {
  bool _busy = false;

  Future<void> _execute(String action) async {
    if (_busy) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _AccountDecisionDialog(action: action, name: widget.name),
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(adminAccountManagementProvider).execute({
        'action': action,
        'accountId': widget.accountId,
        'reason': reason,
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminAccountUpdated)));
      widget.onChanged?.call();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountReviewFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.isSuperAdmin || auth.userId == widget.accountId) {
      return const SizedBox.shrink();
    }
    if (_busy) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final actions = widget.status == 'deleted'
        ? ['restore']
        : [
            if (widget.status == 'suspended') 'reactivate',
            if (widget.status.isEmpty || widget.status == 'active') 'suspend',
            'delete',
          ];
    return PopupMenuButton<String>(
      key: ValueKey('manage-account-${widget.accountId}'),
      tooltip: context.l10n.adminManageProfile,
      onSelected: _execute,
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            child: Text(_actionLabel(context.l10n, action)),
          ),
      ],
      icon: const Icon(Icons.more_vert_rounded),
    );
  }
}

String _actionLabel(AppLocalizations l10n, String action) => switch (action) {
  'suspend' => l10n.adminSuspendProfile,
  'reactivate' => l10n.adminReactivateProfile,
  'restore' => l10n.adminRestoreProfile,
  _ => l10n.adminDeleteProfile,
};

class _AccountDecisionDialog extends StatefulWidget {
  const _AccountDecisionDialog({required this.action, required this.name});
  final String action;
  final String name;
  @override
  State<_AccountDecisionDialog> createState() => _AccountDecisionDialogState();
}

class _AccountDecisionDialogState extends State<_AccountDecisionDialog> {
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(_actionLabel(context.l10n, widget.action)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(
          widget.action == 'delete'
              ? context.l10n.adminDeleteProfileBody
              : context.l10n.adminAccountDecisionBody,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _reason,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: context.l10n.adminDecisionReason,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancelLabel),
      ),
      FilledButton(
        onPressed: _reason.text.trim().length < 3
            ? null
            : () => Navigator.pop(context, _reason.text.trim()),
        child: Text(context.l10n.confirmLabel),
      ),
    ],
  );
}

class CreateStudentButton extends ConsumerWidget {
  const CreateStudentButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(authControllerProvider).isSuperAdmin) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        key: const ValueKey('admin-create-student'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(context.l10n.adminCreateStudent),
        onPressed: () async {
          final schoolId = await showAttachSchoolSheet(context);
          if (schoolId == null || !context.mounted) return;
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (_) => _CreateStudentSheet(schoolId: schoolId),
          );
        },
      ),
    );
  }
}

class _CreateStudentSheet extends ConsumerStatefulWidget {
  const _CreateStudentSheet({required this.schoolId});
  final String schoolId;
  @override
  ConsumerState<_CreateStudentSheet> createState() =>
      _CreateStudentSheetState();
}

class _CreateStudentSheetState extends ConsumerState<_CreateStudentSheet> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  late final String _requestId = _newRequestId();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_first, _last, _phone, _email]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(adminAccountManagementProvider).execute({
        'action': 'createStudent',
        'requestId': _requestId,
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        // Le téléphone de l'élève est facultatif : sans lui, l'élève entre
        // avec son code d'accès INTELLIA.
        if (_phone.text.trim().isNotEmpty)
          'phoneNumber': CameroonPhoneNumber.normalize(_phone.text),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        'establishmentId': widget.schoolId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminStudentCreated)));
      Navigator.pop(context);
    } on FirebaseFunctionsException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.code == 'already-exists'
              ? l10n.adminStudentContactExists
              : l10n.accountReviewFailed,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = l10n.accountReviewFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_busy,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.adminCreateStudent,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(l10n.adminCreateStudentBody),
              const SizedBox(height: 20),
              for (final entry in [
                (_first, l10n.adminStudentFirstName),
                (_last, l10n.adminStudentLastName),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: entry.$1,
                    enabled: !_busy,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: entry.$2,
                      counterText: '',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.adminFieldRequired
                        : null,
                  ),
                ),
              TextFormField(
                controller: _phone,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.adminStudentPhoneOptional,
                  hintText: '+237 6…',
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return null;
                  try {
                    CameroonPhoneNumber.normalize(value ?? '');
                    return null;
                  } catch (_) {
                    return l10n.phoneErrorInvalidNumber;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.adminStudentEmailOptional,
                ),
                validator: (value) =>
                    (value ?? '').trim().isNotEmpty &&
                        !RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(value!.trim())
                    ? l10n.adminInvalidEmail
                    : null,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.adminCreateStudent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _newRequestId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
