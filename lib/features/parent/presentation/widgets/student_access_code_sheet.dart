import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../auth/presentation/widgets/student_access_code_reveal.dart';
import '../../../family_access/application/family_access_providers.dart';
import '../../../family_access/domain/family_access_models.dart';
import '../../application/parent_providers.dart';
import '../../domain/parent_child_profile.dart';

/// Code d'accès élève d'un enfant, depuis sa carte ou son profil.
///
/// Le serveur ne garde qu'une empreinte : le code n'est jamais « relu ». Le
/// parent en génère un nouveau, montré une seule fois, et l'ancien cesse
/// aussitôt de fonctionner.
Future<void> showStudentAccessCodeSheet(
  BuildContext context,
  ParentChildProfile child,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => StudentAccessCodeSheet(child: child),
  );
}

class StudentAccessCodeSheet extends ConsumerStatefulWidget {
  const StudentAccessCodeSheet({required this.child, super.key});

  final ParentChildProfile child;

  @override
  ConsumerState<StudentAccessCodeSheet> createState() =>
      _StudentAccessCodeSheetState();
}

class _StudentAccessCodeSheetState
    extends ConsumerState<StudentAccessCodeSheet> {
  bool _issuing = false;
  bool _failed = false;
  IssuedStudentAccessCode? _issued;

  Future<void> _generate() async {
    final child = widget.child;
    final hasActiveCode = child.access?.accessCode ?? false;
    if (hasActiveCode) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.studentAccessCodeReplaceTitle),
          content: Text(
            context.l10n.studentAccessCodeReplaceBody(child.firstName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancelLabel),
            ),
            FilledButton(
              key: const ValueKey('student-access-code-replace-confirm'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.studentAccessCodeReplaceConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _issuing = true;
      _failed = false;
    });
    try {
      final issued = await ref
          .read(familyAccessRepositoryProvider)
          .issueStudentAccessCode(child.id);
      if (!mounted) return;
      setState(() {
        _issuing = false;
        _issued = issued;
      });
      // L'état « code actif » de la carte suit le serveur.
      ref.invalidate(parentDashboardProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _issuing = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final child = widget.child;
    final issued = _issued;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        0,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: issued != null
            ? StudentAccessCodeReveal(
                key: const ValueKey('parent-student-access-code-issued'),
                studentFirstName: child.firstName,
                code: issued.code,
                continueLabel: l10n.studentAccessCodeDone,
                onContinue: () => Navigator.of(context).pop(),
              )
            : Column(
                key: const ValueKey('parent-student-access-code-sheet'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${l10n.childActionAccessCode} · ${child.firstName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.xs),
                  Text(
                    _statusLabel(context, child.access),
                    key: const ValueKey('parent-student-access-code-status'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  Text(l10n.studentAccessCodeSheetBody),
                  if (_failed) ...[
                    const SizedBox(height: IntelliaSpacing.sm),
                    Text(
                      l10n.studentAccessCodeIssueFailed,
                      key: const ValueKey('parent-student-access-code-failed'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: IntelliaSpacing.md),
                  FilledButton.icon(
                    key: const ValueKey('parent-student-access-code-generate'),
                    onPressed: _issuing ? null : _generate,
                    icon: _issuing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.key_rounded),
                    label: Text(l10n.studentAccessCodeGenerate),
                  ),
                ],
              ),
      ),
    );
  }
}

String _statusLabel(BuildContext context, ChildAccessMethods? access) {
  final l10n = context.l10n;
  if (access == null) return l10n.childAccessUnknown;
  if (!access.accessCode) return l10n.studentAccessCodeNone;
  final issuedAt = access.accessCodeIssuedAt;
  if (issuedAt == null) return l10n.studentAccessCodeActive;
  return l10n.studentAccessCodeActiveSince(
    MaterialLocalizations.of(context).formatMediumDate(issuedAt),
  );
}
