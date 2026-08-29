import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../application/mobile_money_providers.dart';
import '../data/mobile_money_repository.dart';
import '../domain/mobile_money_models.dart';

class MobileMoneyAdminQueueScreen extends ConsumerWidget {
  const MobileMoneyAdminQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(adminMobileMoneyQueueProvider);
    return queue.when(
      loading: () => const IntelliaStateView(
        kind: IntelliaStateKind.loading,
        title: 'Chargement des paiements',
      ),
      error: (error, stackTrace) => IntelliaStateView(
        kind: IntelliaStateKind.errorRetryable,
        title: 'File indisponible',
        message: error is MobileMoneyException
            ? error.message
            : 'Impossible de charger les demandes de paiement.',
        primaryLabel: 'Réessayer',
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
              'Validation Mobile Money',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            const Text(
              'Comparez chaque référence avec le portail de l’opérateur avant toute décision. Intellia237 ne prélève aucune somme.',
            ),
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
              'Aucune demande en attente',
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
            _DetailLine(label: 'Opérateur', value: request.operatorLabel),
            _DetailLine(label: 'Téléphone payeur', value: request.payerPhone),
            _DetailLine(
              label: 'Référence',
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
                    label: const Text('Rejeter'),
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
                    label: const Text('Valider'),
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
        title: const Text('Paiement vérifié ?'),
        content: Text(
          'Confirmez uniquement si ${formatXaf(request.amountXaf)} et la référence ${request.transactionReference} apparaissent dans le portail ${request.operatorLabel}. Cette action activera l’accès.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Paiement vérifié'),
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
        title: const Text('Rejeter la demande'),
        content: TextField(
          controller: controller,
          maxLength: 280,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motif visible par le parent (facultatif)',
            hintText: 'Ex. référence introuvable',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Confirmer le rejet'),
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
            approved ? 'Paiement validé et accès activé.' : 'Demande rejetée.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is MobileMoneyException
                ? error.message
                : 'Décision non enregistrée.',
          ),
        ),
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
