import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../student_home/data/student_link_code_service.dart';

/// Code de liaison parent d'un élève, montré à un adulte de confiance : un
/// parent déjà lié (pour un second responsable), la direction de l'école de
/// l'élève, la super-administration.
///
/// Ce code relie un responsable ; il n'ouvre jamais l'espace de l'élève. Le
/// serveur vérifie qui le demande.
Future<void> showGuardianLinkCodeSheet(
  BuildContext context, {
  required String studentId,
  required String studentName,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        _GuardianLinkCodeSheet(studentId: studentId, studentName: studentName),
  );
}

class _GuardianLinkCodeSheet extends ConsumerStatefulWidget {
  const _GuardianLinkCodeSheet({
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;

  @override
  ConsumerState<_GuardianLinkCodeSheet> createState() =>
      _GuardianLinkCodeSheetState();
}

class _GuardianLinkCodeSheetState
    extends ConsumerState<_GuardianLinkCodeSheet> {
  String? _code;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load(
      () => ref
          .read(studentLinkCodeServiceProvider)
          .ensureLinkCodeFor(widget.studentId),
    );
  }

  Future<void> _load(Future<String> Function() fetch) async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final code = await fetch();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _code = code.isEmpty ? null : code;
        _failed = code.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _rotate() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.guardianLinkCodeRotate),
        content: Text(l10n.guardianLinkCodeRotateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            key: const ValueKey('guardian-link-code-rotate-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.guardianLinkCodeRotate),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _load(
      () => ref
          .read(studentLinkCodeServiceProvider)
          .rotateLinkCodeFor(widget.studentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final code = _code;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        0,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
      ),
      child: Column(
        key: const ValueKey('guardian-link-code-sheet'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${l10n.childActionLinkCode} · ${widget.studentName}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          Text(l10n.guardianLinkCodeBody(widget.studentName)),
          const SizedBox(height: IntelliaSpacing.md),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_failed || code == null)
            Text(
              l10n.guardianLinkCodeUnavailable,
              style: TextStyle(color: theme.colorScheme.error),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    key: const ValueKey('guardian-link-code-value'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.studentAccessCodeCopy,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!context.mounted) return;
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(content: Text(l10n.studentAccessCodeCopied)),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          const SizedBox(height: IntelliaSpacing.md),
          OutlinedButton.icon(
            key: const ValueKey('guardian-link-code-rotate'),
            onPressed: _loading ? null : _rotate,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.guardianLinkCodeRotate),
          ),
        ],
      ),
    );
  }
}
