import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../domain/user_directory_models.dart';

final parentsProvider =
    StateNotifierProvider<ParentsNotifier, List<DirectoryUser>>((ref) {
      return ParentsNotifier();
    });

class ParentsNotifier extends StateNotifier<List<DirectoryUser>> {
  ParentsNotifier()
    : super([
        DirectoryUser(
          id: 'prt_01',
          fullName: 'Jean-Marc Mballa',
          role: 'parent',
          email: 'jm.mballa@camnet.cm',
          phone: '+237699887766',
          establishmentId: 'est_douala_01',
          establishmentName: 'Collège Libermann',
          classLevel: 'Parent d\'élèves',
          accountStatus: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 120)),
          linkCount: 2,
        ),
        DirectoryUser(
          id: 'prt_02',
          fullName: 'Béatrice Manga',
          role: 'parent',
          email: 'manga.b@gmail.com',
          phone: '+237677112233',
          establishmentId: 'est_douala_01',
          establishmentName: 'Collège Libermann',
          classLevel: 'Parent d\'élèves',
          accountStatus: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          linkCount: 1,
        ),
      ]);
}

class ParentsScreen extends ConsumerWidget {
  const ParentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(parentsProvider);

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
                    'Répertoire des Parents',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text(
                    'Consultation des tuteurs légaux, enfants associés et vérification d\'établissement.',
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
              searchHint: 'Rechercher un parent...',
              filterPredicate: (u, q) =>
                  u.fullName.toLowerCase().contains(q) ||
                  u.phone.contains(q) ||
                  u.email.toLowerCase().contains(q),
              columns: [
                StudioTableColumn(
                  header: 'Parent',
                  flex: 3,
                  cellBuilder: (u) => Text(
                    u.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                StudioTableColumn(
                  header: 'Téléphone',
                  flex: 2,
                  cellBuilder: (u) => Text(u.phone),
                ),
                StudioTableColumn(
                  header: 'E-mail',
                  flex: 2,
                  cellBuilder: (u) => Text(u.email),
                ),
                StudioTableColumn(
                  header: 'Enfants Rattachés',
                  width: 130,
                  cellBuilder: (u) => Text('${u.linkCount} enfant(s)'),
                ),
                StudioTableColumn(
                  header: 'Statut',
                  width: 100,
                  cellBuilder: (u) => StudioBadge(
                    label: u.isActive ? 'Actif' : 'Inactif',
                    variant: u.isActive
                        ? StudioBadgeVariant.success
                        : StudioBadgeVariant.neutral,
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
