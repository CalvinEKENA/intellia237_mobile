import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../application/mobile_money_providers.dart';
import '../domain/mobile_money_models.dart';
import 'mobile_money_localization.dart';

class MobileMoneyAdminQueueScreen extends ConsumerWidget {
  const MobileMoneyAdminQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(adminMobileMoneyQueueProvider);
    return queue.when(
      loading: () => IntelliaStateView(
        kind: IntelliaStateKind.loading,
        title: context.l10n.loadingPayments,
      ),
      error: (error, stackTrace) => IntelliaStateView(
        kind: IntelliaStateKind.errorRetryable,
        title: context.l10n.paymentQueueUnavailable,
        message: mobileMoneyErrorMessage(context, error),
        primaryLabel: context.l10n.retryLabel,
        onPrimary: () => ref.invalidate(adminMobileMoneyQueueProvider),
      ),
      data: (requests) => RefreshIndicator(
        onRefresh: () async =>
            ref.refresh(adminMobileMoneyQueueProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            IntelliaSpacing.md,
            IntelliaSpacing.lg,
            132,
          ),
          children: [
            Text(
              context.l10n.mobileMoneyApprovalTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(context.l10n.mobileMoneyAdminDescription),
            const SizedBox(height: IntelliaSpacing.md),
            if (requests.isEmpty)
              const _EmptyQueueCard()
            else
              for (final request in requests) ...[
                _PaymentReviewCard(request: request),
                const SizedBox(height: IntelliaSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

class _EmptyQueueCard extends StatelessWidget {
  const _EmptyQueueCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            Text(
              context.l10n.noPendingPaymentRequest,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentReviewCard extends ConsumerStatefulWidget {
  const _PaymentReviewCard({required this.request});

  final AdminPaymentRequest request;

  @override
  ConsumerState<_PaymentReviewCard> createState() => _PaymentReviewCardState();
}

class _PaymentReviewCardState extends ConsumerState<_PaymentReviewCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.parentName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  formatXaf(request.amountXaf),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(request.offerTitle),
            const Divider(height: IntelliaSpacing.lg),
            _DetailLine(
              label: context.l10n.operatorLabel,
              value: request.operatorLabel,
            ),
            _DetailLine(
              label: context.l10n.payerPhoneShort,
              value: request.payerPhone,
            ),
            _DetailLine(
              label: context.l10n.referenceLabel,
              value: request.transactionReference,
              emphasize: true,
            ),
            const SizedBox(height: IntelliaSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _reject(request),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(context.l10n.rejectLabel),
                  ),
                ),
                const SizedBox(width: IntelliaSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _approve(request),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(context.l10n.confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(AdminPaymentRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.paymentVerifiedQuestion),
        content: Text(
          context.l10n.paymentVerificationWarning(
            formatXaf(request.amountXaf),
            request.transactionReference,
            request.operatorLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.paymentVerifiedLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _review(request.requestId, approved: true);
    }
  }

  Future<void> _reject(AdminPaymentRequest request) async {
    final controller = TextEditingController();
    final note = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.rejectPaymentRequest),
        content: TextField(
          controller: controller,
          maxLength: 280,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.l10n.rejectionReasonOptional,
            hintText: context.l10n.rejectionReasonHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(context.l10n.confirmRejection),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note != null) {
      await _review(request.requestId, approved: false, reviewNote: note);
    }
  }

  Future<void> _review(
    String requestId, {
    required bool approved,
    String? reviewNote,
  }) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(mobileMoneyActionsProvider)
          .review(
            requestId: requestId,
            approved: approved,
            reviewNote: reviewNote,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? context.l10n.paymentApprovedAndActivated
                : context.l10n.paymentRequestRejected,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mobileMoneyErrorMessage(context, error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: IntelliaSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 116, child: Text(label)),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
