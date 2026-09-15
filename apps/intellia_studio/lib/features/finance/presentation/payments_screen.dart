import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/firestore_rest_client.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../../control_plane/control_plane_client.dart';
import '../domain/finance_models.dart';

final paymentRequestsProvider =
    StateNotifierProvider<PaymentRequestsNotifier, AsyncValue<List<StudioPaymentRequest>>>((ref) {
  final fs = ref.watch(firestoreRestClientProvider);
  final cp = ref.watch(controlPlaneClientProvider);
  return PaymentRequestsNotifier(fs, cp);
});

class PaymentRequestsNotifier extends StateNotifier<AsyncValue<List<StudioPaymentRequest>>> {
  PaymentRequestsNotifier(this._firestore, this._controlPlane)
      : super(const AsyncValue.loading()) {
    loadPayments();
  }

  final FirestoreRestClient _firestore;
  final ControlPlaneClient _controlPlane;

  Future<void> loadPayments() async {
    state = const AsyncValue.loading();
    try {
      // 1. Attempt to fetch via Cloud Function callable
      try {
        final res = await _controlPlane.listMobileMoneyPayments();
        final list = res.map((m) => StudioPaymentRequest.fromMap(m['id']?.toString() ?? '', m)).toList();
        state = AsyncValue.data(list);
        return;
      } catch (_) {
        // Fallback to bounded Firestore REST read on mobile_money_requests or payments
      }

      final docs = await _firestore.listDocuments('mobile_money_requests', pageSize: 50);
      final list = docs.map((d) => StudioPaymentRequest.fromFirestore(d)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> approve(String id) async {
    try {
      await _controlPlane.reviewMobileMoneyPayment(
        requestId: id,
        decision: 'approved',
      );
      await loadPayments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reject(String id, String reason) async {
    try {
      await _controlPlane.reviewMobileMoneyPayment(
        requestId: id,
        decision: 'rejected',
        reviewNote: reason,
      );
      await loadPayments();
    } catch (e) {
      rethrow;
    }
  }
}

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentRequestsProvider);

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paiements & Mobile Money', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      const Text(
                        'Validation des transferts Orange Money / MTN MoMo via reviewMobileMoneyPayment et réconciliation.',
                        style: TextStyle(color: StudioColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualiser la file',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => ref.read(paymentRequestsProvider.notifier).loadPayments(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: StudioColors.navyPrimary,
              indicatorColor: StudioColors.goldAccent,
              tabs: [
                Tab(text: 'File de Revue Mobile Money (reviewMobileMoneyPayment)'),
                Tab(text: 'Audit des Collections Financières Historiques'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Payment requests review
                  state.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: StudioColors.error, size: 48),
                          const SizedBox(height: 12),
                          Text('Erreur chargement file Mobile Money:\n$err',
                              textAlign: TextAlign.center, style: const TextStyle(color: StudioColors.error)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.read(paymentRequestsProvider.notifier).loadPayments(),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                    data: (requests) {
                      if (requests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 48, color: StudioColors.success),
                              const SizedBox(height: 12),
                              const Text(
                                'Aucune demande Mobile Money en attente de validation.',
                                style: TextStyle(color: StudioColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        );
                      }

                      return StudioDataTable<StudioPaymentRequest>(
                        items: requests,
                        filterPredicate: (r, term) =>
                            r.parentName.toLowerCase().contains(term) ||
                            r.reference.toLowerCase().contains(term) ||
                            r.phoneNumber.contains(term),
                        columns: [
                          StudioTableColumn(
                            header: 'Demandeur / Téléphone',
                            flex: 3,
                            cellBuilder: (r) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(r.parentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(r.phoneNumber,
                                    style: const TextStyle(fontSize: 11, color: StudioColors.textSecondaryLight)),
                              ],
                            ),
                          ),
                          StudioTableColumn(
                            header: 'Opérateur',
                            flex: 2,
                            cellBuilder: (r) => StudioBadge(
                              label: r.operator == PaymentOperator.orangeMoney ? 'ORANGE MONEY' : 'MTN MOMO',
                              variant: r.operator == PaymentOperator.orangeMoney
                                  ? StudioBadgeVariant.warning
                                  : StudioBadgeVariant.info,
                            ),
                          ),
                          StudioTableColumn(
                            header: 'Référence TX',
                            flex: 2,
                            cellBuilder: (r) => Text(r.reference,
                                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                          ),
                          StudioTableColumn(
                            header: 'Montant',
                            flex: 2,
                            cellBuilder: (r) => Text(
                              r.formattedAmount,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: StudioColors.navyPrimary),
                            ),
                          ),
                          StudioTableColumn(
                            header: 'Statut',
                            flex: 1,
                            cellBuilder: (r) => StudioBadge(
                              label: r.status.name.toUpperCase(),
                              variant: r.status == PaymentRequestStatus.approved
                                  ? StudioBadgeVariant.success
                                  : r.status == PaymentRequestStatus.pending
                                      ? StudioBadgeVariant.warning
                                      : StudioBadgeVariant.error,
                            ),
                          ),
                          StudioTableColumn(
                            header: 'Actions',
                            flex: 2,
                            cellBuilder: (r) => r.status == PaymentRequestStatus.pending
                                ? Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline, color: StudioColors.success),
                                        tooltip: 'Approuver (reviewMobileMoneyPayment)',
                                        onPressed: () => _confirmApproval(context, ref, r),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, color: StudioColors.error),
                                        tooltip: 'Rejeter',
                                        onPressed: () => _confirmRejection(context, ref, r),
                                      ),
                                    ],
                                  )
                                : const Text('Traité', style: TextStyle(color: StudioColors.textSecondaryLight)),
                          ),
                        ],
                      );
                    },
                  ),

                  // Tab 2: Historical Collections Read-only
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: StudioColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: StudioColors.info.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.history_rounded, color: StudioColors.navyPrimary, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Classification financière : les collections Credit, payments, subscriptions, tokenBalances et transactions sont issues d\'itérations antérieures du produit. Elles sont consultables en lecture seule à des fins de réconciliation.',
                                  style: TextStyle(fontSize: 12, color: StudioColors.navyPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            children: const [
                              ListTile(
                                leading: Icon(Icons.folder_outlined),
                                title: Text('Credit'),
                                subtitle: Text('Statut: LEGACY / HISTORIQUE — Soldes accordés par l\'ancienne logique de jetons'),
                                trailing: StudioBadge(label: 'LECTURE SEULE', variant: StudioBadgeVariant.neutral),
                              ),
                              Divider(),
                              ListTile(
                                leading: Icon(Icons.folder_outlined),
                                title: Text('payments'),
                                subtitle: Text('Statut: HISTORIQUE — Transactions et reçus de paiement antérieurs'),
                                trailing: StudioBadge(label: 'LECTURE SEULE', variant: StudioBadgeVariant.neutral),
                              ),
                              Divider(),
                              ListTile(
                                leading: Icon(Icons.folder_outlined),
                                title: Text('subscriptions'),
                                subtitle: Text('Statut: MIGRÉ VERS ENTITLEMENTS — Souscriptions préexistantes'),
                                trailing: StudioBadge(label: 'ARCHIVÉ', variant: StudioBadgeVariant.neutral),
                              ),
                              Divider(),
                              ListTile(
                                leading: Icon(Icons.folder_outlined),
                                title: Text('tokenBalances'),
                                subtitle: Text('Statut: DÉPRÉCIÉ — Précédent système d\'unités d\'IA'),
                                trailing: StudioBadge(label: 'DÉPRÉCIÉ', variant: StudioBadgeVariant.neutral),
                              ),
                              Divider(),
                              ListTile(
                                leading: Icon(Icons.folder_outlined),
                                title: Text('transactions'),
                                subtitle: Text('Statut: JOURNAL HISTORIQUE — Relevé de tous les flux entrants/sortants'),
                                trailing: StudioBadge(label: 'AUDITABLE', variant: StudioBadgeVariant.neutral),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmApproval(BuildContext context, WidgetRef ref, StudioPaymentRequest req) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Validation de paiement Mobile Money',
      message:
          'Confirmez-vous la réception du paiement de ${req.formattedAmount} (Réf: ${req.reference}) pour ${req.parentName} ? Cette action appellera reviewMobileMoneyPayment et activera les droits.',
      confirmLabel: 'Approuver sur le serveur',
    );
    if (confirmed != null) {
      try {
        await ref.read(paymentRequestsProvider.notifier).approve(req.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Paiement ${req.reference} approuvé avec succès.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Échec: $e'), backgroundColor: StudioColors.error),
          );
        }
      }
    }
  }

  Future<void> _confirmRejection(BuildContext context, WidgetRef ref, StudioPaymentRequest req) async {
    final reason = await ConfirmationDialog.show(
      context,
      title: 'Rejet de la demande de paiement',
      message: 'Veuillez saisir le motif du rejet pour ${req.parentName} (${req.reference}).',
      requireReason: true,
      reasonLabel: 'Motif du rejet (transmis au parent)',
      confirmLabel: 'Rejeter',
      isDestructive: true,
    );
    if (reason != null && reason.trim().isNotEmpty) {
      try {
        await ref.read(paymentRequestsProvider.notifier).reject(req.id, reason.trim());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Demande rejetée: $reason')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Échec: $e'), backgroundColor: StudioColors.error),
          );
        }
      }
    }
  }
}
