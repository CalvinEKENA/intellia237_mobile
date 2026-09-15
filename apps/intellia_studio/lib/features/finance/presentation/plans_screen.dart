import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../domain/finance_models.dart';

final plansProvider = StateNotifierProvider<PlansNotifier, List<StudioSubscriptionPlan>>((ref) {
  return PlansNotifier();
});

class PlansNotifier extends StateNotifier<List<StudioSubscriptionPlan>> {
  PlansNotifier() : super([
    const StudioSubscriptionPlan(
      id: 'plan_cahier_mensuel',
      name: 'Formule Cahier',
      priceXaf: 2500,
      billingPeriod: 'Mensuel',
      features: ['Cours complets', 'Résumés PDF', 'Exercices corrigés'],
      isProvisionedInFirestore: false,
      establishmentId: 'est_douala_01',
    ),
    const StudioSubscriptionPlan(
      id: 'plan_atelier_mensuel',
      name: 'Formule Atelier',
      priceXaf: 5000,
      billingPeriod: 'Mensuel',
      features: ['Tout Cahier', 'FLOW interactif', 'Compagnon IA Kira (Réserve 600k)', 'Quiz illimités'],
      isProvisionedInFirestore: false,
      establishmentId: 'est_douala_01',
    ),
    const StudioSubscriptionPlan(
      id: 'plan_bibliotheque_annuel',
      name: 'Formule Bibliothèque',
      priceXaf: 45000,
      billingPeriod: 'Annuel',
      features: ['Accès intégral illimité', 'Toutes classes', 'Compagnon Léo & Kira', 'Support prioritaire'],
      isProvisionedInFirestore: false,
      establishmentId: 'est_douala_01',
    ),
  ]);

  void markProvisioned(String id) {
    state = [
      for (final p in state)
        if (p.id == id)
          StudioSubscriptionPlan(
            id: p.id,
            name: p.name,
            priceXaf: p.priceXaf,
            billingPeriod: p.billingPeriod,
            features: p.features,
            isProvisionedInFirestore: true,
            establishmentId: p.establishmentId,
          )
        else
          p,
    ];
  }
}

final entitlementsProvider = StateNotifierProvider<EntitlementsNotifier, List<StudioEntitlement>>((ref) {
  return EntitlementsNotifier();
});

class EntitlementsNotifier extends StateNotifier<List<StudioEntitlement>> {
  EntitlementsNotifier() : super([
    const StudioEntitlement(
      id: 'ent_parent_01_est_douala_01',
      parentId: 'usr_par_01',
      establishmentId: 'est_douala_01',
      offerId: 'plan_atelier_mensuel',
      status: EntitlementStatus.active,
      startsAt: '2026-03-01',
      endsAt: '2026-04-01',
    ),
    const StudioEntitlement(
      id: 'ent_parent_02_est_douala_01',
      parentId: 'usr_par_02',
      establishmentId: 'est_douala_01',
      offerId: 'plan_cahier_mensuel',
      status: EntitlementStatus.active,
      startsAt: '2026-02-15',
      endsAt: '2026-03-15',
    ),
    const StudioEntitlement(
      id: 'ent_parent_03_est_douala_01',
      parentId: 'usr_par_03',
      establishmentId: 'est_douala_01',
      offerId: 'plan_atelier_mensuel',
      status: EntitlementStatus.expired,
      startsAt: '2026-01-01',
      endsAt: '2026-02-01',
    ),
  ]);
}

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    final entitlements = ref.watch(entitlementsProvider);

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
                      Text('Plans & Abonnements', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      const Text(
                        'Grille tarifaire XAF, audit du provisionnement Firestore et droits d\'accès (Entitlements).',
                        style: TextStyle(color: StudioColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Schema notice banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                border: Border.all(color: Colors.amber.shade700),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Information Architecture Firestore : La collection mobile_money_offers/{establishmentId} '
                      'n\'est pas encore provisionnée en production. Le Studio utilise les données de repli du code '
                      'et permet le provisionnement supervisé sans écriture sauvage.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: StudioColors.navyPrimary,
              indicatorColor: StudioColors.goldAccent,
              tabs: [
                Tab(text: 'Grille des Formules (Offres XAF)'),
                Tab(text: 'Registre des Droits (Entitlements Parents)'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Plans Grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final plan in plans)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: plan.name.contains('Atelier')
                                      ? StudioColors.goldAccent
                                      : StudioColors.borderLight,
                                  width: plan.name.contains('Atelier') ? 2 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          plan.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        StudioBadge(
                                          label: plan.billingPeriod.toUpperCase(),
                                          variant: StudioBadgeVariant.info,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      plan.formattedPrice,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: StudioColors.navyPrimary,
                                      ),
                                    ),
                                    const Divider(height: 24),
                                    const Text('Inclus dans cette formule :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    for (final feat in plan.features) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: StudioColors.success, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(feat, style: const TextStyle(fontSize: 12))),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: plan.isProvisionedInFirestore
                                            ? StudioColors.success.withValues(alpha: 0.1)
                                            : StudioColors.warning.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            plan.isProvisionedInFirestore ? Icons.cloud_done : Icons.cloud_off,
                                            size: 16,
                                            color: plan.isProvisionedInFirestore ? StudioColors.success : StudioColors.warning,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              plan.isProvisionedInFirestore
                                                  ? 'Provisionné dans Firestore'
                                                  : 'Non provisionné (Repli local)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: plan.isProvisionedInFirestore ? StudioColors.success : StudioColors.warning,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (!plan.isProvisionedInFirestore)
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.tonal(
                                          onPressed: () {
                                            ref.read(plansProvider.notifier).markProvisioned(plan.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Offre ${plan.name} provisionnée avec succès.')),
                                            );
                                          },
                                          child: const Text('Provisionner l\'Offre'),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Tab 2: Entitlements table
                  StudioDataTable<StudioEntitlement>(
                    items: entitlements,
                    filterPredicate: (e, term) =>
                        e.parentId.toLowerCase().contains(term) ||
                        e.establishmentId.toLowerCase().contains(term),
                    columns: [
                      StudioTableColumn(
                        header: 'Identifiant Droit',
                        flex: 3,
                        cellBuilder: (e) => Text(e.id, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      ),
                      StudioTableColumn(
                        header: 'Parent UID',
                        flex: 2,
                        cellBuilder: (e) => Text(e.parentId),
                      ),
                      StudioTableColumn(
                        header: 'Offre Associée',
                        flex: 2,
                        cellBuilder: (e) => Text(e.offerId),
                      ),
                      StudioTableColumn(
                        header: 'Début — Fin',
                        flex: 2,
                        cellBuilder: (e) => Text('${e.startsAt} au ${e.endsAt}'),
                      ),
                      StudioTableColumn(
                        header: 'Statut',
                        flex: 1,
                        cellBuilder: (e) => StudioBadge(
                          label: e.status.name.toUpperCase(),
                          variant: e.isActive ? StudioBadgeVariant.success : StudioBadgeVariant.error,
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
}
