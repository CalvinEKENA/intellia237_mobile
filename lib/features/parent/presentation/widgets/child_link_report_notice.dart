import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/pending_child_link.dart';
import 'add_child_button.dart';

/// Compte rendu, dans l'espace parent, des codes enfants reliés à l'entrée.
///
/// Une réussite s'annonce une fois ; l'enfant est déjà dans le tableau de
/// bord. Un échec reste visible jusqu'à ce que le parent agisse : réessayer
/// quand l'échec est temporaire, sinon saisir un autre code. Le message ne
/// dit jamais si un élève existe derrière un code refusé.
class ChildLinkReportNotice extends ConsumerStatefulWidget {
  const ChildLinkReportNotice({super.key});

  @override
  ConsumerState<ChildLinkReportNotice> createState() =>
      _ChildLinkReportNoticeState();
}

class _ChildLinkReportNoticeState extends ConsumerState<ChildLinkReportNotice> {
  ChildLinkReport? _announced;
  bool _retrying = false;

  static String? _successMessage(
    AppLocalizations l10n,
    ChildLinkReport report,
  ) {
    final count = report.linkedNames.length + report.alreadyLinkedNames.length;
    if (count == 0) return null;
    if (count > 1) return l10n.childLinkBatchSuccess(count);
    return report.linkedNames.isNotEmpty
        ? l10n.addChildSuccess(report.linkedNames.single)
        : l10n.addChildAlready(report.alreadyLinkedNames.single);
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await ref.read(pendingChildLinkProvider.notifier).linkPending();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final report = ref.watch(
      pendingChildLinkProvider.select((link) => link.report),
    );
    if (report == null) return const SizedBox.shrink();

    if (!identical(report, _announced)) {
      _announced = report;
      final message = _successMessage(l10n, report);
      if (message != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.maybeOf(
            context,
          )?.showSnackBar(SnackBar(content: Text(message)));
          if (!report.hasFailure) {
            ref.read(pendingChildLinkProvider.notifier).dismissReport();
          }
        });
      }
    }
    final failureCode = report.failureCode;
    if (failureCode == null) return const SizedBox.shrink();

    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('parent-child-link-report'),
        margin: const EdgeInsets.fromLTRB(
          IntelliaSpacing.md,
          IntelliaSpacing.sm,
          IntelliaSpacing.md,
          0,
        ),
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        decoration: BoxDecoration(
          color: IntelliaColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          border: Border.all(
            color: IntelliaColors.error.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.link_off_rounded, color: IntelliaColors.error),
            const SizedBox(width: IntelliaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.childLinkReportFailedTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(childLinkErrorMessage(l10n, failureCode)),
                  const SizedBox(height: IntelliaSpacing.sm),
                  if (report.canRetry)
                    FilledButton.tonalIcon(
                      key: const ValueKey('parent-child-link-retry'),
                      onPressed: _retrying ? null : _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.retryLabel),
                    )
                  else
                    OutlinedButton.icon(
                      key: const ValueKey('parent-child-link-add'),
                      onPressed: () {
                        ref
                            .read(pendingChildLinkProvider.notifier)
                            .dismissReport();
                        showAddChildDialog(context, ref);
                      },
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text(l10n.addChildTitle),
                    ),
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('parent-child-link-dismiss'),
              tooltip: l10n.closeLabel,
              onPressed: () =>
                  ref.read(pendingChildLinkProvider.notifier).clear(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
