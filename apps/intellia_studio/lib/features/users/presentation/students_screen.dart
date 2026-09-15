import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../domain/user_directory_models.dart';

final studentsProvider =
    StateNotifierProvider<StudentsNotifier, List<DirectoryUser>>((ref) {
      return StudentsNotifier();
    });

class StudentsNotifier extends StateNotifier<List<DirectoryUser>> {
  StudentsNotifier()
    : super([
        DirectoryUser(
          id: 'std_01',
          fullName: 'Marc Nkoa',
          role: 'student',
          email: 'marc.nkoa@gmail.com',
          phone: '+237691234567',
          establishmentId: 'est_douala_01',
          establishmentName: 'Collège Libermann',
          classLevel: 'Terminale C',
          accountStatus: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          linkCount: 1,
          linkCode: 'LNK83921',
        ),
        DirectoryUser(
          id: 'std_02',
          fullName: 'Esther Biya',
          role: 'student',
          email: 'esther.b@outlook.cm',
          phone: '+237675432109',
          establishmentId: 'est_douala_01',
          establishmentName: 'Collège Libermann',
          classLevel: 'Première D',
          accountStatus: 'suspended',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          linkCount: 2,
          linkCode: 'LNK10492',
        ),
      ]);

  void updateStatus(String id, String newStatus, [String? previous]) {
    state = [
      for (final u in state)
        if (u.id == id)
          u.copyWith(accountStatus: newStatus, statusBeforeDeletion: previous)
        else
          u,
    ];
  }

  void rotateCode(String id) {
    state = [
      for (final u in state)
        if (u.id == id)
          u.copyWith(
            linkCode: 'ROT${DateTime.now().millisecondsSinceEpoch % 100000}',
          )
        else
          u,
    ];
  }
}

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(studentsProvider);

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
                    'Répertoire des Élèves',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text(
                    'Gestion des comptes apprenants, liaison parentale et statut de compte.',
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
              searchHint: 'Rechercher un élève (nom, téléphone, e-mail)...',
              filterPredicate: (u, q) =>
                  u.fullName.toLowerCase().contains(q) ||
                  u.phone.contains(q) ||
                  u.email.toLowerCase().contains(q),
              columns: [
                StudioTableColumn(
                  header: 'Élève',
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
                        '${u.classLevel} · ${u.establishmentName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: StudioColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                StudioTableColumn(
                  header: 'Téléphone',
                  flex: 2,
                  cellBuilder: (u) => Text(u.phone),
                ),
                StudioTableColumn(
                  header: 'Code Liaison',
                  width: 130,
                  cellBuilder: (u) => Row(
                    children: [
                      Text(
                        u.linkCode ?? 'Aucun',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Générer un nouveau code',
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: StudioColors.navyPrimary,
                        ),
                        onPressed: () => ref
                            .read(studentsProvider.notifier)
                            .rotateCode(u.id),
                      ),
                    ],
                  ),
                ),
                StudioTableColumn(
                  header: 'Parents Liés',
                  width: 100,
                  cellBuilder: (u) => Text('${u.linkCount} rattaché(s)'),
                ),
                StudioTableColumn(
                  header: 'Statut',
                  width: 110,
                  cellBuilder: (u) => StudioBadge(
                    label: u.isActive
                        ? 'Actif'
                        : (u.isSuspended ? 'Suspendu' : 'Supprimé'),
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
                  IconButton(
                    tooltip: u.isActive ? 'Suspendre' : 'Réactiver',
                    icon: Icon(
                      u.isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: u.isActive
                          ? StudioColors.warning
                          : StudioColors.success,
                    ),
                    onPressed: () async {
                      final reason = await ConfirmationDialog.show(
                        context,
                        title: u.isActive
                            ? 'Suspendre l\'élève'
                            : 'Réactiver l\'élève',
                        message:
                            'Action autoritaire server-side pour ${u.fullName}.',
                        requireReason: true,
                        isDestructive: u.isActive,
                      );
                      if (reason != null) {
                        ref
                            .read(studentsProvider.notifier)
                            .updateStatus(
                              u.id,
                              u.isActive ? 'suspended' : 'active',
                            );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
