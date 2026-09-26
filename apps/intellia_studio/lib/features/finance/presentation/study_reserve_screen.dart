import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/firestore_rest_client.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../control_plane/control_plane_client.dart';
import '../domain/finance_models.dart';

final reservesProvider =
    StateNotifierProvider<
      ReservesNotifier,
      AsyncValue<List<StudioStudyReserve>>
    >((ref) {
      final fs = ref.watch(firestoreRestClientProvider);
      final cp = ref.watch(controlPlaneClientProvider);
      return ReservesNotifier(fs, cp);
    });

class ReservesNotifier
    extends StateNotifier<AsyncValue<List<StudioStudyReserve>>> {
  ReservesNotifier(this._firestore, this._controlPlane)
    : super(const AsyncValue.loading()) {
    loadReserves();
  }

  final FirestoreRestClient _firestore;
  final ControlPlaneClient _controlPlane;

  Future<void> loadReserves() async {
    state = const AsyncValue.loading();
    try {
      // 1. Fetch real students
      final students = await _firestore.runQuery(
        fromCollection: 'users',
        whereFilter: {
          'fieldFilter': {
            'field': {'fieldPath': 'role'},
            'op': 'EQUAL',
            'value': {'stringValue': 'student'},
          },
        },
        limit: 50,
      );

      final list = <StudioStudyReserve>[];
      final now = DateTime.now();
      final monthStart =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final monthEnd = '${now.year}-${now.month.toString().padLeft(2, '0')}-28';

      for (final s in students) {
        final studentName =
            s['displayName'] as String? ??
            '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
        final classLevel =
            s['classLevel'] as String? ?? s['currentClass'] as String? ?? '—';

        try {
          final res = await _controlPlane.getStudyReserve(studentId: s.id);
          list.add(
            StudioStudyReserve(
              studentId: s.id,
              studentName: studentName.isNotEmpty ? studentName : s.id,
              classLevel: classLevel,
              allowanceInternal:
                  (res['allowanceInternal'] as num?)?.toInt() ?? 1000,
              consumedInternal: (res['consumedInternal'] as num?)?.toInt() ?? 0,
              cycleStart: res['cycleStart'] as String? ?? monthStart,
              cycleEnd: res['cycleEnd'] as String? ?? monthEnd,
              latestThresholdEmitted: res['latestThresholdEmitted'] as String?,
            ),
          );
        } catch (_) {
          // If individual reserve document doesn't exist yet, show canonical default allowance
          list.add(
            StudioStudyReserve(
              studentId: s.id,
              studentName: studentName.isNotEmpty ? studentName : s.id,
              classLevel: classLevel,
              allowanceInternal: 1000,
              consumedInternal: 0,
              cycleStart: monthStart,
              cycleEnd: monthEnd,
            ),
          );
        }
      }

      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class StudyReserveScreen extends ConsumerWidget {
  const StudyReserveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reservesProvider);

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
                    Text(
                      'Réserve d\'Étude (Study Reserve)',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Supervision des quotas d\'utilisation IA par élève selon les seuils canoniques [75, 50, 25, 5, 0] %.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualiser',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () =>
                    ref.read(reservesProvider.notifier).loadReserves(),
              ),
              const SizedBox(width: 8),
              const StudioBadge(
                label: 'RENOUVELLEMENT AUTOMATIQUE SERVEUR',
                variant: StudioBadgeVariant.info,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rule compliance banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StudioColors.navyPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: StudioColors.navyPrimary.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_clock_rounded,
                  color: StudioColors.navyPrimary,
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Politique Serveur Stricte : Aucun déclencheur de renouvellement manuel n\'est exposé. '
                    'Les cycles se renouvellent automatiquement via Cloud Functions à l\'expiration du cycle mensuel.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: StudioColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Erreur chargement Réserve d\'Étude:\n$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: StudioColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(reservesProvider.notifier).loadReserves(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (reserves) {
                if (reserves.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun compte élève disponible pour le suivi de la Réserve d\'Étude.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  );
                }

                return StudioDataTable<StudioStudyReserve>(
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
                          Text(
                            r.studentName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${r.classLevel} • ID: ${r.studentId}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: StudioColors.textSecondaryLight,
                            ),
                          ),
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
                              Text(
                                '${r.consumptionPercent}% consommé',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${r.consumedInternal} / ${r.allowanceInternal} un.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: StudioColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: r.consumptionRatio,
                              backgroundColor: StudioColors.borderLight,
                              color: r.isCritical
                                  ? StudioColors.error
                                  : StudioColors.navyPrimary,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StudioTableColumn(
                      header: 'Cycle Actuel',
                      flex: 2,
                      cellBuilder: (r) => Text(
                        '${r.cycleStart} au ${r.cycleEnd}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    StudioTableColumn(
                      header: 'État Canonique',
                      flex: 2,
                      cellBuilder: (r) {
                        final status = r.canonicalStatus;
                        StudioBadgeVariant variant;
                        switch (status) {
                          case 'healthy':
                            variant = StudioBadgeVariant.success;
                            break;
                          case 'warning':
                            variant = StudioBadgeVariant.warning;
                            break;
                          case 'low':
                          case 'critical':
                          case 'depleted':
                            variant = StudioBadgeVariant.error;
                            break;
                          default:
                            variant = StudioBadgeVariant.neutral;
                        }
                        return StudioBadge(
                          label: status.toUpperCase(),
                          variant: variant,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
