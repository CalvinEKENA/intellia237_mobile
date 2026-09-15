import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/firestore_rest_client.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../auth/application/auth_controller.dart';

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

  factory StudioAuditEvent.fromFirestore(FirestoreDocument doc) {
    return StudioAuditEvent(
      id: doc.id,
      timestamp: doc['timestamp'] as String? ??
          doc['createdAt'] as String? ??
          DateTime.now().toIso8601String(),
      actorUid: doc['actorUid'] as String? ?? doc['performedBy'] as String? ?? 'Système',
      actorRole: doc['actorRole'] as String? ?? 'superAdmin',
      action: (doc['action'] as String? ?? 'MANAGE_ACCOUNT').toUpperCase(),
      targetResourceId: doc['accountId'] as String? ?? doc['targetId'] as String? ?? doc.id,
      reason: doc['reason'] as String? ?? 'Aucun motif renseigné',
      ipAddress: doc['ipAddress'] as String? ?? '127.0.0.1',
    );
  }
}

final auditEventsProvider = FutureProvider<List<StudioAuditEvent>>((ref) async {
  final session = ref.watch(authSessionProvider).asData?.value;
  if (session == null || !session.isSuperAdmin) {
    throw Exception(
      'Accès réservé : Le registre account_management_audit requiert les privilèges SuperAdmin selon les règles de sécurité Firestore.',
    );
  }

  final fs = ref.watch(firestoreRestClientProvider);
  final docs = await fs.listDocuments('account_management_audit', pageSize: 100);
  return docs.map((d) => StudioAuditEvent.fromFirestore(d)).toList();
});

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(auditEventsProvider);

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
                    Text('Registre d\'Audit Immuable (Audit Log)',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Piste d\'audit officielle serveur (account_management_audit). Traçabilité complète des actions privilégiées.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualiser',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.refresh(auditEventsProvider),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, color: StudioColors.warning, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      '$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: StudioColors.navyPrimary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun événement d\'audit enregistré dans account_management_audit.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  );
                }

                return StudioDataTable<StudioAuditEvent>(
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
                      cellBuilder: (e) => Text(
                        e.timestamp.length > 19 ? e.timestamp.substring(0, 19).replaceAll('T', ' ') : e.timestamp,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                    StudioTableColumn(
                      header: 'Opérateur',
                      flex: 2,
                      cellBuilder: (e) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(e.actorUid,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(e.actorRole,
                              style: const TextStyle(
                                  fontSize: 11, color: StudioColors.textSecondaryLight)),
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
                      cellBuilder: (e) => Text(e.targetResourceId,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ),
                    StudioTableColumn(
                      header: 'Motif Obligatoire Enregistré',
                      flex: 4,
                      cellBuilder: (e) => Text(e.reason, style: const TextStyle(fontSize: 12)),
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
