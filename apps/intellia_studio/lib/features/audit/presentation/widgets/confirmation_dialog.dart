import 'package:flutter/material.dart';
import '../../../../core/theme/studio_theme.dart';

class ConfirmationDialog extends StatefulWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.requireReason = false,
    this.reasonLabel = 'Motif obligatoire de l\'opération',
    this.confirmLabel = 'Confirmer',
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final bool requireReason;
  final String reasonLabel;
  final String confirmLabel;
  final bool isDestructive;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String message,
    bool requireReason = false,
    String reasonLabel = 'Motif obligatoire',
    String confirmLabel = 'Confirmer',
    bool isDestructive = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: title,
        message: message,
        requireReason: requireReason,
        reasonLabel: reasonLabel,
        confirmLabel: confirmLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(
            widget.isDestructive
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            color: widget.isDestructive
                ? StudioColors.error
                : StudioColors.navyPrimary,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.title, style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.message,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              if (widget.requireReason) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: widget.reasonLabel,
                    hintText:
                        'Ex: Demande de transfert validée par la direction...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 3) {
                      return 'Veuillez saisir un motif d\'au moins 3 caractères.';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDestructive
                ? StudioColors.error
                : StudioColors.navyPrimary,
          ),
          onPressed: () {
            if (widget.requireReason && !_formKey.currentState!.validate()) {
              return;
            }
            Navigator.pop(context, _reasonController.text.trim());
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
