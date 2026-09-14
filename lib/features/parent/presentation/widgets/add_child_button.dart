import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/parent_preview.dart';
import '../../application/parent_providers.dart';
import '../../data/child_link_service.dart';

/// Traduit un code d'erreur de liaison stable en message FR/EN. Le service ne
/// renvoie qu'un code ; l'UI choisit la langue.
String childLinkErrorMessage(AppLocalizations l10n, String code) =>
    switch (code) {
      'not-found' => l10n.childLinkErrorNotFound,
      'invalid-argument' => l10n.childLinkErrorInvalid,
      'permission-denied' => l10n.childLinkErrorPermission,
      'unauthenticated' => l10n.childLinkErrorUnauthenticated,
      'resource-exhausted' => l10n.childLinkErrorTooMany,
      _ => l10n.childLinkErrorGeneric,
    };

/// Bouton « Ajouter un enfant » : ouvre une saisie de code de liaison, appelle
/// le callable serveur, puis rafraîchit immédiatement le tableau de bord.
///
/// Masqué pendant la prévisualisation Parent : un super-administrateur ne
/// rattache pas d'enfant à son propre compte depuis l'espace prévisualisé.
class AddChildButton extends ConsumerWidget {
  const AddChildButton({this.expanded = false, super.key});

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(parentPreviewControllerProvider).active) {
      return const SizedBox.shrink();
    }
    final label = Text(context.l10n.addChildTitle);
    const icon = Icon(Icons.person_add_alt_1_outlined);
    void open() => _showAddChildDialog(context, ref);

    return expanded
        ? FilledButton.icon(
            key: const ValueKey('parent-add-child'),
            onPressed: open,
            icon: icon,
            label: label,
          )
        : OutlinedButton.icon(
            key: const ValueKey('parent-add-child'),
            onPressed: open,
            icon: icon,
            label: label,
          );
  }
}

Future<void> _showAddChildDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AddChildDialog(parentRef: ref),
  );
}

class _AddChildDialog extends StatefulWidget {
  const _AddChildDialog({required this.parentRef});

  /// Ref de l'écran parent : c'est lui qui possède `parentDashboardProvider`,
  /// donc c'est lui qu'il faut invalider pour rafraîchir la liste.
  final WidgetRef parentRef;

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = context.l10n.addChildCodeLabel);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      final result = await widget.parentRef
          .read(childLinkServiceProvider)
          .linkChildByCode(code);
      // Rafraîchissement immédiat du tableau de bord parent.
      widget.parentRef.invalidate(parentDashboardProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyLinked
                ? l10n.addChildAlready(result.firstName)
                : l10n.addChildSuccess(result.firstName),
          ),
        ),
      );
    } on ChildLinkException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = childLinkErrorMessage(l10n, error.code);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.addChildTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('parent-add-child-code'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            enabled: !_submitting,
            onSubmitted: (_) => _submitting ? null : _submit(),
            decoration: InputDecoration(
              labelText: l10n.addChildCodeLabel,
              errorText: _error,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          Text(
            l10n.addChildCodeHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          key: const ValueKey('parent-add-child-submit'),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.addChildSubmit),
        ),
      ],
    );
  }
}
