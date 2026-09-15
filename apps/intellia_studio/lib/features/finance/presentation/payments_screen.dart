import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../domain/finance_models.dart';

final paymentRequestsProvider = StateNotifierProvider<PaymentRequestsNotifier, List<StudioPaymentRequest>>((ref) {
  return PaymentRequestsNotifier();
});

class PaymentRequestsNotifier extends StateNotifier<List<StudioPaymentRequest>> {
  PaymentRequestsNotifier() : super([
    const StudioPaymentRequest(
      id: 'pay_req_01',
      parentId: 'usr_par_01',
      parentName: 'Mme Ekena Suzanne',
      establishmentId: 'est_douala_01',
      amountXaf: 5000,
      operator: PaymentOperator.orangeMoney,
      reference: 'OM-2026-98124',
      phoneNumber: '+237 699 01 23 45',
      status: PaymentRequestStatus.pending,
      createdAt: '2026-03-15 08:30',
    ),
    const StudioPaymentRequest(
      id: 'pay_req_02',
      parentId: 'usr_par_02',
      parentName: 'M. Kamga Jean',
      establishmentId: 'est_douala_01',
      amountXaf: 2500,
      operator: PaymentOperator.mtnMomo,
      reference: 'MTN-2026-44321',
      phoneNumber: '+237 677 89 12 34',
      status: PaymentRequestStatus.approved,
      createdAt: '2026-03-14 14:15',
      reviewedAt: '2026-03-14 15:00',
      reviewedByUid: 'usr_admin_01',
    ),
    const StudioPaymentRequest(
      id: 'pay_req_03',
      parentId: 'usr_par_04',
      parentName: 'Mme Noah Christine',
      establishmentId: 'est_douala_01',
      amountXaf: 5000,
      operator: PaymentOperator.orangeMoney,
      reference: 'OM-2026-11223',
      phoneNumber: '+237 695 44 33 22',
      status: PaymentRequestStatus.rejected,
      createdAt: '2026-03-13 11:20',
      reviewedAt: '2026-03-13 12:05',
      reviewedByUid: 'usr_admin_01',
      rejectionReason: 'Numéro de transaction introuvable sur le relevé Orange Money.',
    ),
  ]);

  void approve(String id) {
    state = [
      for (final req in state)
        if (req.id == id)
          StudioPaymentRequest(
            id: req.id,
            parentId: req.parentId,
            parentName: req.parentName,
            establishmentId: req.establishmentId,
            amountXaf: req.amountXaf,
            operator: req.operator,
            reference: req.reference,
            phoneNumber: req.phoneNumber,
            status: PaymentRequestStatus.approved,
            createdAt: req.createdAt,
            reviewedAt: DateTime.now().toIso8601String(),
            reviewedByUid: 'usr_admin_01',
          )
        else
          req,
    ];
  }

  void reject(String id, String reason) {
    state = [
      for (final req in state)
        if (req.id == id)
          StudioPaymentRequest(
            id: req.id,
            parentId: req.parentId,
            parentName: req.parentName,
            establishmentId: req.establishmentId,
            amountXaf: req.amountXaf,
            operator: req.operator,
            reference: req.reference,
            phoneNumber: req.phoneNumber,
            status: PaymentRequestStatus.rejected,
            createdAt: req.createdAt,
            reviewedAt: DateTime.now().toIso8601String(),
            reviewedByUid: 'usr_admin_01',
            rejectionReason: reason,
          )
        else
          req,
    ];
  }
}

final legacyRecordsProvider = Provider<List<LegacyFinancialRecord>>((ref) {
  return [
    const LegacyFinancialRecord(
      id: 'cred_old_01',
      collectionName: 'Credit',
      userId: 'usr_std_01',
      rawData: {'balance': 150, 'source': 'initial_grant'},
      classification: DataCollectionClassification.legacyRequiresClassification,
      timestamp: '2025-09-12',
    ),
    const LegacyFinancialRecord(
      id: 'tok_old_02',
      collectionName: 'tokenBalances',
      userId: 'usr_std_02',
      rawData: {'tokens': 500, 'updatedAt': '2025-11-04'},
      classification: DataCollectionClassification.legacyRequiresClassification,
      timestamp: '2025-11-04',
    ),
    const LegacyFinancialRecord(
      id: 'txn_old_03',
      collectionName: 'transactions',
      userId: 'usr_par_01',
      rawData: {'amount': 2500, 'type': 'sub_monthly', 'status': 'completed'},
      classification: DataCollectionClassification.observedInProduction,
      timestamp: '2025-12-10',
    ),
  ];
});

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(paymentRequestsProvider);
    final legacyRecords = ref.watch(legacyRecordsProvider);

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
                        'Validation des transferts Orange Money / MTN MoMo et registre des collections financières.',
                        style: TextStyle(color: StudioColors.textSecondaryLight),
                      ),
                    ],
                  ),
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
                Tab(text: 'File de Revue Mobile Money (Canonique)'),
                Tab(text: 'Collections Historiques & Réconciliation (Lecture Seule)'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Payment requests review
                  StudioDataTable<StudioPaymentRequest>(
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
                            Text(r.phoneNumber, style: const TextStyle(fontSize: 11, color: StudioColors.textSecondaryLight)),
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
                        cellBuilder: (r) => Text(r.reference, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
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
                                    tooltip: 'Approuver (Émettre Entitlement)',
                                    onPressed: () => _confirmApproval(context, ref, r),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel_outlined, color: StudioColors.error),
                                    tooltip: 'Rejeter avec motif',
                                    onPressed: () => _confirmRejection(context, ref, r),
                                  ),
                                ],
                              )
                            : const Text('Traité', style: TextStyle(fontSize: 12, color: StudioColors.textSecondaryLight)),
                      ),
                    ],
                  ),
                  // Tab 2: Legacy collections audit
                  StudioDataTable<LegacyFinancialRecord>(
                    items: legacyRecords,
                    filterPredicate: (rec, term) =>
                        rec.collectionName.toLowerCase().contains(term) ||
                        rec.userId.toLowerCase().contains(term),
                    columns: [
                      StudioTableColumn(
                        header: 'Collection Source',
                        flex: 2,
                        cellBuilder: (rec) => Text(rec.collectionName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      StudioTableColumn(
                        header: 'Document ID',
                        flex: 2,
                        cellBuilder: (rec) => Text(rec.id, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                      ),
                      StudioTableColumn(
                        header: 'User ID',
                        flex: 2,
                        cellBuilder: (rec) => Text(rec.userId),
                      ),
                      StudioTableColumn(
                        header: 'Données Brutes',
                        flex: 3,
                        cellBuilder: (rec) => Text(rec.rawData.toString(), style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                      ),
                      StudioTableColumn(
                        header: 'Classification',
                        flex: 2,
                        cellBuilder: (rec) => const StudioBadge(
                          label: 'HISTORIQUE (LECTURE SEULE)',
                          variant: StudioBadgeVariant.neutral,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmApproval(BuildContext context, WidgetRef ref, StudioPaymentRequest req) async {
    final reason = await ConfirmationDialog.show(
      context,
      title: 'Validation Paiement Mobile Money',
      message: 'Confirmez-vous la réception de ${req.formattedAmount} via ${req.operator.name} (Réf: ${req.reference}) ? '
          'Cette action émettra immédiatement un droit d\'accès pour le parent.',
      confirmLabel: 'Approuver et Activer',
      requireReason: false,
    );

    if (reason != null) {
      ref.read(paymentRequestsProvider.notifier).approve(req.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement approuvé. Entitlement émis avec succès.'),
            backgroundColor: StudioColors.success,
          ),
        );
      }
    }
  }

  void _confirmRejection(BuildContext context, WidgetRef ref, StudioPaymentRequest req) async {
    final reason = await ConfirmationDialog.show(
      context,
      title: 'Rejet du Paiement Mobile Money',
      message: 'Veuillez saisir le motif obligatoire du rejet (ex: transaction introuvable).',
      confirmLabel: 'Confirmer le Rejet',
      requireReason: true,
      reasonLabel: 'Motif du rejet (visible par l\'administration)',
      isDestructive: true,
    );

    if (reason != null) {
      ref.read(paymentRequestsProvider.notifier).reject(req.id, reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement rejeté avec motif enregistré.'),
            backgroundColor: StudioColors.error,
          ),
        );
      }
    }
  }
}
