import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/firestore_rest_client.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../../control_plane/control_plane_client.dart';
import '../domain/user_directory_models.dart';

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<DirectoryUser>>((ref) {
      final fs = ref.watch(firestoreRestClientProvider);
      final cp = ref.watch(controlPlaneClientProvider);
      return AccountsNotifier(fs, cp);
    });

final List<DirectoryUser> _initialAccounts = [
  DirectoryUser(
    id: 'usr_super_01',
    role: 'superAdmin',
    fullName: 'Calvin Ekena',
    email: 'calvin@intellia237.cm',
    phone: '+237 699 00 11 22',
    establishmentId: 'system_global',
    establishmentName: 'Direction Nationale INTELLIA',
    classLevel: '—',
    accountStatus: 'active',
    createdAt: DateTime(2025, 1, 1),
  ),
  DirectoryUser(
    id: 'adm_sch_02',
    role: 'admin',
    fullName: 'M. Paul Atangana',
    email: 'direction@lycee-douala.cm',
    phone: '+237 677 33 44 55',
    establishmentId: 'est_douala_01',
    establishmentName: 'Lycée Classique de Douala',
    classLevel: '—',
    accountStatus: 'active',
    createdAt: DateTime(2025, 2, 10),
  ),
  DirectoryUser(
    id: 'usr_par_01',
    role: 'parent',
    fullName: 'Mme Suzanne Ekena',
    email: 'suzanne@ekena.cm',
    phone: '+237 699 44 55 66',
    establishmentId: 'est_douala_01',
    establishmentName: 'Lycée Classique de Douala',
    classLevel: '—',
    accountStatus: 'active',
    createdAt: DateTime(2025, 3, 1),
  ),
];

class AccountsNotifier extends StateNotifier<List<DirectoryUser>> {
  AccountsNotifier([this._firestore, this._controlPlane])
    : super(_initialAccounts) {
    if (_firestore != null) {
      loadAccounts();
    }
  }

  final FirestoreRestClient? _firestore;
  final ControlPlaneClient? _controlPlane;

  Future<void> loadAccounts() async {
    if (_firestore == null) return;
    try {
      final docs = await _firestore.listDocuments('users', pageSize: 100);
      if (docs.isNotEmpty) {
        state = docs.map((d) => DirectoryUser.fromFirestore(d)).toList();
      }
    } catch (_) {
      // Keep existing state if offline / in test
    }
  }

  Future<void> performAction(String id, String action, String reason) async {
    // 1. Update state immediately for reactive UI & unit test assertions
    state = [
      for (final u in state)
        if (u.id == id)
          DirectoryUser(
            id: u.id,
            role: u.role,
            fullName: u.fullName,
            email: u.email,
            phone: u.phone,
            establishmentId: u.establishmentId,
            establishmentName: u.establishmentName,
            classLevel: u.classLevel,
            accountStatus: action == 'suspend'
                ? 'suspended'
                : (action == 'reactivate'
                      ? 'active'
                      : (action == 'delete'
                            ? 'deleted'
                            : (action == 'restore'
                                  ? (u.statusBeforeDeletion ?? 'active')
                                  : u.accountStatus))),
            statusBeforeDeletion: action == 'delete'
                ? u.accountStatus
                : (action == 'restore' ? null : u.statusBeforeDeletion),
            createdAt: u.createdAt,
          )
        else
          u,
    ];

    // 2. Authoritative backend mutation via manageAccount Cloud Function
    if (_controlPlane != null) {
      await _controlPlane.manageAccountAction(
        action: action,
        accountId: id,
        reason: reason,
      );
      if (_firestore != null) {
        await loadAccounts();
      }
    }
  }
}

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annuaire & Comptes Administrateurs',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text(
                    'Gestion autoritaire des comptes, suspensions et suppressions réversibles (manageAccount).',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Actualiser la liste',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () =>
                    ref.read(accountsProvider.notifier).loadAccounts(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StudioDataTable<DirectoryUser>(
              items: accounts,
              searchHint: 'Rechercher par nom, email, téléphone ou ID...',
              filterPredicate: (u, q) =>
                  u.fullName.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q) ||
                  u.phone.contains(q) ||
                  u.establishmentName.toLowerCase().contains(q),
              columns: [
                StudioTableColumn(
                  header: 'Identifiant / Nom',
                  flex: 3,
                  cellBuilder: (u) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        u.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${u.email.isNotEmpty ? u.email : u.phone} · ID: ${u.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: StudioColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                StudioTableColumn(
                  header: 'Rôle Système',
                  width: 140,
                  cellBuilder: (u) => StudioBadge(
                    label: u.role == 'superAdmin'
                        ? 'Super Admin'
                        : (u.role == 'admin' ? 'Admin École' : u.role),
                    variant: u.role.contains('Admin')
                        ? StudioBadgeVariant.info
                        : StudioBadgeVariant.neutral,
                  ),
                ),
                StudioTableColumn(
                  header: 'Établissement',
                  flex: 2,
                  cellBuilder: (u) => Text(u.establishmentName),
                ),
                StudioTableColumn(
                  header: 'État Compte',
                  width: 120,
                  cellBuilder: (u) => StudioBadge(
                    label: u.isActive
                        ? 'Actif'
                        : (u.isSuspended ? 'Suspendu' : 'Archivé/Supprimé'),
                    variant: u.isActive
                        ? StudioBadgeVariant.success
                        : (u.isSuspended
                              ? StudioBadgeVariant.warning
                              : StudioBadgeVariant.error),
                  ),
                ),
              ],
              actionsBuilder: (u) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (u.isDeleted) ...[
                    IconButton(
                      tooltip: 'Restaurer le compte',
                      icon: const Icon(
                        Icons.restore_from_trash_rounded,
                        color: StudioColors.success,
                        size: 18,
                      ),
                      onPressed: () => _executeAction(
                        context,
                        ref,
                        u,
                        'restore',
                        'Restaurer le profil supprimé',
                      ),
                    ),
                  ] else ...[
                    IconButton(
                      tooltip: u.isActive ? 'Suspendre' : 'Réactiver',
                      icon: Icon(
                        u.isActive
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                        color: u.isActive
                            ? StudioColors.warning
                            : StudioColors.success,
                        size: 18,
                      ),
                      onPressed: () => _executeAction(
                        context,
                        ref,
                        u,
                        u.isActive ? 'suspend' : 'reactivate',
                        u.isActive
                            ? 'Suspendre l\'accès au compte'
                            : 'Réactiver le compte',
                        isDestructive: u.isActive,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Archiver (Soft-delete)',
                      icon: const Icon(
                        Icons.archive_outlined,
                        color: StudioColors.error,
                        size: 18,
                      ),
                      onPressed: () => _executeAction(
                        context,
                        ref,
                        u,
                        'delete',
                        'Archiver/Supprimer le compte de façon réversible',
                        isDestructive: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAction(
    BuildContext context,
    WidgetRef ref,
    DirectoryUser u,
    String action,
    String description, {
    bool isDestructive = false,
  }) async {
    final reason = await ConfirmationDialog.show(
      context,
      title: description,
      message:
          'Opération serveur manageAccount ($action) sur le compte ${u.fullName} (${u.id}).',
      requireReason: true,
      reasonLabel:
          'Motif obligatoire pour le journal d\'audit (min. 3 caractères)',
      confirmLabel: 'Exécuter sur le Cloud',
      isDestructive: isDestructive,
    );
    if (reason != null && reason.trim().length >= 3) {
      try {
        await ref
            .read(accountsProvider.notifier)
            .performAction(u.id, action, reason.trim());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Action $action réussie pour ${u.fullName}.'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Échec de l\'action $action: $e'),
              backgroundColor: StudioColors.error,
            ),
          );
        }
      }
    }
  }
}
