import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../data/student_link_code_service.dart';

/// Carte « Mon code parent » : affiche le code de liaison de l'élève (généré à
/// la demande côté serveur) à partager avec un parent pour le suivi.
class StudentLinkCodeCard extends ConsumerWidget {
  const StudentLinkCodeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final codeAsync = ref.watch(studentLinkCodeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.family_restroom_rounded,
                  color: IntelliaColors.brandIndigo,
                ),
                const SizedBox(width: IntelliaSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.studentLinkCodeTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              l10n.studentLinkCodeBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            codeAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: IntelliaSpacing.sm),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => Row(
                children: [
                  Expanded(child: Text(l10n.studentLinkCodeError)),
                  TextButton(
                    onPressed: () => ref.invalidate(studentLinkCodeProvider),
                    child: Text(l10n.retryLabel),
                  ),
                ],
              ),
              data: (code) => _CodeRow(code: code),
            ),
            if (codeAsync.hasValue) ...[
              const SizedBox(height: IntelliaSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('student-link-code-rotate'),
                  onPressed: () => _confirmRotate(context, ref),
                  icon: const Icon(Icons.autorenew_rounded, size: 18),
                  label: Text(l10n.studentLinkCodeRotate),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRotate(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    // Capturés avant tout await : ce widget n'a pas de `mounted` à interroger.
    final messenger = ScaffoldMessenger.of(context);
    final rotatedMessage = l10n.studentLinkCodeRotated;
    final errorMessage = l10n.studentLinkCodeError;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.studentLinkCodeRotateConfirmTitle),
        content: Text(l10n.studentLinkCodeRotateConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            key: const ValueKey('student-link-code-rotate-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.studentLinkCodeRotate),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(studentLinkCodeServiceProvider).rotateLinkCode();
      ref.invalidate(studentLinkCodeProvider);
      messenger.showSnackBar(SnackBar(content: Text(rotatedMessage)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Container(
            key: const ValueKey('student-link-code-value'),
            padding: const EdgeInsets.symmetric(
              horizontal: IntelliaSpacing.md,
              vertical: IntelliaSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: IntelliaColors.brandIndigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(IntelliaRadii.small),
            ),
            child: Text(
              code,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
        const SizedBox(width: IntelliaSpacing.sm),
        IconButton.filledTonal(
          tooltip: l10n.studentLinkCodeCopy,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.studentLinkCodeCopied)));
          },
          icon: const Icon(Icons.copy_rounded),
        ),
      ],
    );
  }
}
