import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/presentation/widgets/student_access_code_reveal.dart';
import '../../family_access/application/family_access_providers.dart';
import '../../family_access/domain/family_access_models.dart';

/// Récupération de l'accès d'un élève par la direction de SON école ou par la
/// super-administration.
///
/// Le serveur vérifie l'autorisation (direction de la même école, ou
/// super-administration) et journalise l'émission. Le code précédent est
/// invalidé : aucun code existant n'est jamais « retrouvé ».
Future<void> showStudentAccessRecoverySheet(
  BuildContext context, {
  required String studentId,
  required String studentName,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _StudentAccessRecoverySheet(
      studentId: studentId,
      studentName: studentName,
    ),
  );
}

class _StudentAccessRecoverySheet extends ConsumerStatefulWidget {
  const _StudentAccessRecoverySheet({
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;

  @override
  ConsumerState<_StudentAccessRecoverySheet> createState() =>
      _StudentAccessRecoverySheetState();
}

class _StudentAccessRecoverySheetState
    extends ConsumerState<_StudentAccessRecoverySheet> {
  bool _issuing = false;
  bool _failed = false;
  IssuedStudentAccessCode? _issued;

  Future<void> _issue() async {
    setState(() {
      _issuing = true;
      _failed = false;
    });
    try {
      final issued = await ref
          .read(familyAccessRepositoryProvider)
          .issueStudentAccessCode(widget.studentId);
      if (!mounted) return;
      setState(() {
        _issuing = false;
        _issued = issued;
      });
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
    final issued = _issued;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        0,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: issued != null
            ? StudentAccessCodeReveal(
                key: const ValueKey('admin-student-access-code-issued'),
                studentFirstName: widget.studentName,
                code: issued.code,
                continueLabel: l10n.studentAccessCodeDone,
                onContinue: () => Navigator.of(context).pop(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.adminStudentAccessRecoveryTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.xs),
                  Text(
                    widget.studentName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  Text(l10n.adminStudentAccessRecoveryBody),
                  if (_failed) ...[
                    const SizedBox(height: IntelliaSpacing.sm),
                    Text(
                      l10n.studentAccessCodeIssueFailed,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: IntelliaSpacing.md),
                  FilledButton.icon(
                    key: const ValueKey('admin-student-access-code-generate'),
                    onPressed: _issuing ? null : _issue,
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
