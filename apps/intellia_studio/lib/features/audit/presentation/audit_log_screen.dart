import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';

class StudioAuditEvent {
  final String id;
  final String timestamp;
  final String actorUid;
  final String actorRole;
  final String action;
  final String targetResourceId;
  final String reason;
  final String ipAddress;

  const StudioAuditEvent({
    required this.id,
    required this.timestamp,
    required this.actorUid,
    required this.actorRole,
    required this.action,
    required this.targetResourceId,
    required this.reason,
    required this.ipAddress,
  });
}

final auditEventsProvider = Provider<List<StudioAuditEvent>>((ref) {
  return const [
    StudioAuditEvent(
      id: 'aud_evt_101',
      timestamp: '2026-03-15 08:35:12',
      actorUid: 'usr_admin_01',
      actorRole: 'superAdmin',
      action: 'APPROVE_PAYMENT',
      targetResourceId: 'pay_req_01',
      reason: 'Validation virement Orange Money vérifié sur relevé bancaire',
      ipAddress: '102.244.155.10',
    ),
    StudioAuditEvent(
      id: 'aud_evt_100',
      timestamp: '2026-03-14 16:40:05',
      actorUid: 'usr_admin_01',
      actorRole: 'superAdmin',
      action: 'SUSPEND_ACCOUNT',
      targetResourceId: 'usr_target_03',
      reason: 'Non-respect charte comportement élève',
      ipAddress: '102.244.155.10',
    ),
    StudioAuditEvent(
      id: 'aud_evt_099',
      timestamp: '2026-03-14 14:12:30',
      actorUid: 'usr_admin_02',
      actorRole: 'admin',
      action: 'SOFT_DELETE_ACCOUNT',
      targetResourceId: 'usr_target_99',
      reason: 'Archivage demandé par inspection académique',
      ipAddress: '197.159.200.4',
    ),
    StudioAuditEvent(
      id: 'aud_evt_098',
      timestamp: '2026-03-13 11:05:44',
      actorUid: 'usr_admin_01',
      actorRole: 'superAdmin',
      action: 'PUBLISH_CATALOG_BATCH',
      targetResourceId: 'catalog_rev_42',
      reason: 'Déploiement programme officiel 3ème trimestre 2026',
      ipAddress: '102.244.155.10',
    ),
  ];
});

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(auditEventsProvider);

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
                    Text('Registre d\'Audit Immuable (Audit Log)', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Piste d\'audit officielle serveur (account_management_audit). Traçabilité complète des actions privilégiées.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('Exporter CSV'),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StudioDataTable<StudioAuditEvent>(
              items: events,
              filterPredicate: (e, term) =>
                  e.action.toLowerCase().contains(term) ||
                  e.actorUid.toLowerCase().contains(term) ||
                  e.targetResourceId.toLowerCase().contains(term) ||
                  e.reason.toLowerCase().contains(term),
              columns: [
                StudioTableColumn(
                  header: 'Horodatage',
                  flex: 2,
                  cellBuilder: (e) => Text(e.timestamp, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                ),
                StudioTableColumn(
                  header: 'Opérateur',
                  flex: 2,
                  cellBuilder: (e) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(e.actorUid, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(e.actorRole, style: const TextStyle(fontSize: 11, color: StudioColors.textSecondaryLight)),
                    ],
                  ),
                ),
                StudioTableColumn(
                  header: 'Action Exécutée',
                  flex: 2,
                  cellBuilder: (e) => StudioBadge(
                    label: e.action,
                    variant: e.action.contains('DELETE')
                        ? StudioBadgeVariant.error
                        : e.action.contains('SUSPEND')
                        ? StudioBadgeVariant.warning
                        : StudioBadgeVariant.info,
                  ),
                ),
                StudioTableColumn(
                  header: 'Cible Ressource',
                  flex: 2,
                  cellBuilder: (e) => Text(e.targetResourceId, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
                StudioTableColumn(
                  header: 'Motif Obligatoire Enregistré',
                  flex: 4,
                  cellBuilder: (e) => Text(e.reason, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
