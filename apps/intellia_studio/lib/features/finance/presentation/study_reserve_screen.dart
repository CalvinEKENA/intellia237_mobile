import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../domain/finance_models.dart';

final reservesProvider = StateNotifierProvider<ReservesNotifier, List<StudioStudyReserve>>((ref) {
  return ReservesNotifier();
});

class ReservesNotifier extends StateNotifier<List<StudioStudyReserve>> {
  ReservesNotifier() : super([
    const StudioStudyReserve(
      studentId: 'usr_std_01',
      studentName: 'Calvin Ekena',
      classLevel: 'Terminale',
      allowanceInternal: 600000,
      consumedInternal: 480000,
      cycleStart: '2026-03-01',
      cycleEnd: '2026-03-31',
      latestThresholdEmitted: '80%',
    ),
    const StudioStudyReserve(
      studentId: 'usr_std_02',
      studentName: 'Brenda Kamga',
      classLevel: 'Terminale',
      allowanceInternal: 600000,
      consumedInternal: 120000,
      cycleStart: '2026-03-01',
      cycleEnd: '2026-03-31',
    ),
    const StudioStudyReserve(
      studentId: 'usr_std_03',
      studentName: 'Yannick Noah',
      classLevel: 'Premiere',
      allowanceInternal: 600000,
      consumedInternal: 590000,
      cycleStart: '2026-03-01',
      cycleEnd: '2026-03-31',
      latestThresholdEmitted: '100%',
    ),
    const StudioStudyReserve(
      studentId: 'usr_std_04',
      studentName: 'Marie Fotso',
      classLevel: '3eme',
      allowanceInternal: 600000,
      consumedInternal: 85000,
      cycleStart: '2026-03-01',
      cycleEnd: '2026-03-31',
    ),
  ]);
}

class StudyReserveScreen extends ConsumerWidget {
  const StudyReserveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reserves = ref.watch(reservesProvider);

    return Padding(
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
                    Text('Réserve d\'Étude (Study Reserve)', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Supervision des quotas d\'utilisation IA par élève, cycles mensuels et seuils d\'alerte.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              const StudioBadge(
                label: 'RENOUVELLEMENT AUTOMATIQUE SERVEUR',
                variant: StudioBadgeVariant.info,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rule compliance banner (Amendment 5)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StudioColors.navyPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: StudioColors.navyPrimary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: StudioColors.navyPrimary, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Politique Serveur Stricte : Aucun déclencheur de renouvellement manuel n\'est exposé. '
                    'Les cycles se renouvellent automatiquement via les Cloud Functions à expiration mensuelle.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StudioDataTable<StudioStudyReserve>(
              items: reserves,
              filterPredicate: (r, term) =>
                  r.studentName.toLowerCase().contains(term) ||
                  r.classLevel.toLowerCase().contains(term),
              columns: [
                StudioTableColumn(
                  header: 'Élève',
                  flex: 3,
                  cellBuilder: (r) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${r.classLevel} • ID: ${r.studentId}', style: const TextStyle(fontSize: 11, color: StudioColors.textSecondaryLight)),
                    ],
                  ),
                ),
                StudioTableColumn(
                  header: 'Consommation Réserve',
                  flex: 3,
                  cellBuilder: (r) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${r.consumptionPercent}% consommé', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('${r.consumedInternal} / ${r.allowanceInternal} un.', style: const TextStyle(fontSize: 11, color: StudioColors.textSecondaryLight)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: r.consumptionRatio,
                          backgroundColor: StudioColors.borderLight,
                          color: r.isCritical ? StudioColors.error : StudioColors.navyPrimary,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                StudioTableColumn(
                  header: 'Cycle Actuel',
                  flex: 2,
                  cellBuilder: (r) => Text('${r.cycleStart} au ${r.cycleEnd}', style: const TextStyle(fontSize: 12)),
                ),
                StudioTableColumn(
                  header: 'Dernier Seuil Émis',
                  flex: 2,
                  cellBuilder: (r) => r.latestThresholdEmitted == null
                      ? const Text('Aucun', style: TextStyle(color: StudioColors.textSecondaryLight))
                      : StudioBadge(
                          label: 'SEUIL ${r.latestThresholdEmitted}',
                          variant: r.latestThresholdEmitted == '100%'
                              ? StudioBadgeVariant.error
                              : StudioBadgeVariant.warning,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
