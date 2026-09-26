import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/firestore_rest_client.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../auth/application/auth_controller.dart';

/// Demande de suppression de compte telle que la tient le serveur
/// (`account_deletion_requests`). Aucune donnée personnelle : uid, rôle,
/// état, échéance et code d'erreur seulement.
class AccountDeletionRequestView {
  const AccountDeletionRequestView({
    required this.uid,
    required this.role,
    required this.status,
    required this.dueAt,
    required this.attempts,
    required this.lastErrorCode,
  });

  factory AccountDeletionRequestView.fromFirestore(FirestoreDocument doc) {
    return AccountDeletionRequestView(
      uid: doc.id,
      role: doc['role'] as String? ?? '—',
      status: doc['status'] as String? ?? 'unknown',
      dueAt: doc['dueAt'] as String?,
      attempts: doc['attempts'] as int? ?? 0,
      lastErrorCode: doc['lastErrorCode'] as String?,
    );
  }

  final String uid;
  final String role;
  final String status;
  final String? dueAt;
  final int attempts;
  final String? lastErrorCode;

  bool get needsAttention => status == 'needs_attention';
}

final accountDeletionRequestsProvider =
    FutureProvider<List<AccountDeletionRequestView>>((ref) async {
      final session = ref.watch(authSessionProvider).asData?.value;
      if (session == null || !session.isSuperAdmin) {
        throw Exception(
          'Accès réservé : les demandes de suppression sont visibles par la super-administration.',
        );
      }
      final fs = ref.watch(firestoreRestClientProvider);
      final docs = await fs.listDocuments(
        'account_deletion_requests',
        pageSize: 100,
      );
      final requests = docs.map(AccountDeletionRequestView.fromFirestore).toList()
        // Ce qui demande un humain d'abord, puis les échéances les plus proches.
        ..sort((a, b) {
          if (a.needsAttention != b.needsAttention) {
            return a.needsAttention ? -1 : 1;
          }
          return (a.dueAt ?? '~').compareTo(b.dueAt ?? '~');
        });
      return requests;
    });

String accountDeletionStatusLabel(String status) => switch (status) {
  'scheduled' => 'PROGRAMMÉE',
  'cancelled' => 'ANNULÉE',
  'processing' => 'EN COURS',
  'failed' => 'ÉCHEC — REPRISE PRÉVUE',
  'needs_attention' => 'INTERVENTION REQUISE',
  'completed' => 'TERMINÉE',
  _ => status.toUpperCase(),
};

StudioBadgeVariant _variant(String status) => switch (status) {
  'needs_attention' => StudioBadgeVariant.error,
  'failed' || 'processing' => StudioBadgeVariant.warning,
  'completed' => StudioBadgeVariant.success,
  'cancelled' => StudioBadgeVariant.neutral,
  _ => StudioBadgeVariant.info,
};

/// Suivi des suppressions de compte (docs/architecture/ACCOUNT_DELETION.md).
class AccountDeletionRequestsPanel extends ConsumerWidget {
  const AccountDeletionRequestsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(accountDeletionRequestsProvider);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: StudioColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Demandes de suppression de compte',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualiser',
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () =>
                      ref.invalidate(accountDeletionRequestsProvider),
                ),
              ],
            ),
            const Text(
              'Délai de grâce de 7 jours, traitement horaire, reprise automatique. '
              '« Intervention requise » après 5 échecs.',
              style: TextStyle(
                fontSize: 12,
                color: StudioColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            requests.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(
                '$error',
                style: const TextStyle(
                  fontSize: 12,
                  color: StudioColors.navyPrimary,
                ),
              ),
              data: (items) => items.isEmpty
                  ? const Text(
                      'Aucune demande enregistrée.',
                      style: TextStyle(
                        fontSize: 12,
                        color: StudioColors.textSecondaryLight,
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final item in items)
                            ListTile(
                              dense: true,
                              title: Text(
                                item.uid,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                              subtitle: Text(
                                '${item.role} · échéance ${item.dueAt?.replaceAll('T', ' ').split('.').first ?? '—'}'
                                ' · tentatives ${item.attempts}'
                                '${item.lastErrorCode == null ? '' : ' · ${item.lastErrorCode}'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: StudioBadge(
                                label: accountDeletionStatusLabel(item.status),
                                variant: _variant(item.status),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
