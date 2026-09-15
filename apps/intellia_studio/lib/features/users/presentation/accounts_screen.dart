import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../domain/user_directory_models.dart';

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<DirectoryUser>>((ref) {
      return AccountsNotifier();
    });

class AccountsNotifier extends StateNotifier<List<DirectoryUser>> {
  AccountsNotifier()
    : super([
        DirectoryUser(
          id: 'adm_01',
          fullName: 'Directeur Général',
          role: 'superAdmin',
          email: 'admin@intellia.cm',
          phone: '+237690000000',
          establishmentId: '',
          establishmentName: 'Administration Générale',
          classLevel: 'SuperAdmin',
          accountStatus: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
        ),
        DirectoryUser(
          id: 'adm_sch_02',
          fullName: 'Pr. Ndongo',
          role: 'admin',
          email: 'direction@leclerc.cm',
          phone: '+237691112233',
          establishmentId: 'est_yaounde_02',
          establishmentName: 'Lycée Général Leclerc',
          classLevel: 'Chef d\'établissement',
          accountStatus: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 150)),
        ),
        DirectoryUser(
          id: 'acc_del_03',
          fullName: 'Ancien Compte Suspect',
          role: 'student',
          email: 'suspect@test.cm',
          phone: '+237699999999',
          establishmentId: 'est_douala_01',
          establishmentName: 'Collège Libermann',
          classLevel: '6ème',
          accountStatus: 'deleted',
          statusBeforeDeletion: 'suspended',
          createdAt: DateTime.now().subtract(const Duration(days: 400)),
        ),
      ]);

  void performAction(String id, String action, String reason) {
    state = [
      for (final u in state)
        if (u.id == id) _applyAction(u, action) else u,
    ];
  }

  DirectoryUser _applyAction(DirectoryUser u, String action) {
    if (action == 'suspend') {
      return u.copyWith(accountStatus: 'suspended');
    }
    if (action == 'reactivate') {
      return u.copyWith(accountStatus: 'active');
    }
    if (action == 'delete') {
      return u.copyWith(
        accountStatus: 'deleted',
        statusBeforeDeletion: u.accountStatus,
      );
    }
    if (action == 'restore') {
      return u.copyWith(accountStatus: u.statusBeforeDeletion ?? 'suspended');
    }
    return u;
  }
}

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(accountsProvider);

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
                    'Comptes & Gestion des Rôles (manageAccount)',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text(
                    'Cycle de vie officiel des comptes : suspendre, réactiver, archiver, restaurer.',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StudioDataTable<DirectoryUser>(
              items: list,
              searchHint: 'Rechercher un compte...',
              filterPredicate: (u, q) =>
                  u.fullName.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q) ||
                  u.role.contains(q),
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
                        '${u.email} · ID: ${u.id}',
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
    String title, {
    bool isDestructive = false,
  }) async {
    final reason = await ConfirmationDialog.show(
      context,
      title: title,
      message:
          'Opération serveur manageAccount ($action) sur le compte ${u.fullName} (${u.id}).',
      requireReason: true,
      reasonLabel: 'Motif obligatoire pour le journal d\'audit',
      confirmLabel: 'Exécuter',
      isDestructive: isDestructive,
    );
    if (reason != null) {
      ref.read(accountsProvider.notifier).performAction(u.id, action, reason);
    }
  }
}
