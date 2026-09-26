import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/firestore_rest_client.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/user_directory_models.dart';

final parentsProvider =
    StateNotifierProvider<ParentsNotifier, AsyncValue<List<DirectoryUser>>>((
      ref,
    ) {
      final fs = ref.watch(firestoreRestClientProvider);
      final session = ref.watch(authSessionProvider).asData?.value;
      return ParentsNotifier(fs, session);
    });

class ParentsNotifier extends StateNotifier<AsyncValue<List<DirectoryUser>>> {
  ParentsNotifier(this._firestore, this._session)
    : super(const AsyncValue.loading()) {
    loadParents();
  }

  final FirestoreRestClient _firestore;
  final dynamic _session;

  Future<void> loadParents() async {
    state = const AsyncValue.loading();
    try {
      final isSuperAdmin = _session?.isSuperAdmin ?? false;
      final establishmentId = _session?.establishmentId ?? '';

      if (isSuperAdmin || establishmentId.isEmpty) {
        // SuperAdmin has platform-wide visibility
        final docs = await _firestore.runQuery(
          fromCollection: 'users',
          whereFilter: {
            'fieldFilter': {
              'field': {'fieldPath': 'role'},
              'op': 'EQUAL',
              'value': {'stringValue': 'parent'},
            },
          },
          limit: 100,
        );
        final list = docs.map((d) => DirectoryUser.fromFirestore(d)).toList();
        state = AsyncValue.data(list);
      } else {
        // School-scoped Admin:
        // 1. Fetch students belonging to this establishment
        final studentDocs = await _firestore.runQuery(
          fromCollection: 'users',
          whereFilter: {
            'compositeFilter': {
              'op': 'AND',
              'filters': [
                {
                  'fieldFilter': {
                    'field': {'fieldPath': 'role'},
                    'op': 'EQUAL',
                    'value': {'stringValue': 'student'},
                  },
                },
                {
                  'fieldFilter': {
                    'field': {'fieldPath': 'establishmentId'},
                    'op': 'EQUAL',
                    'value': {'stringValue': establishmentId},
                  },
                },
              ],
            },
          },
          limit: 50,
        );

        final studentIds = studentDocs.map((d) => d.id).toSet();
        if (studentIds.isEmpty) {
          state = const AsyncValue.data([]);
          return;
        }

        // 2. Fetch children_links for these students
        final links = await _firestore.listDocuments(
          'children_links',
          pageSize: 100,
        );
        final relevantParentIds = <String>{};
        for (final l in links) {
          final sId = l['studentId'] as String? ?? '';
          final pId = l['parentId'] as String? ?? '';
          if (studentIds.contains(sId) && pId.isNotEmpty) {
            relevantParentIds.add(pId);
          }
        }

        // 3. Fetch each parent document
        final parentsList = <DirectoryUser>[];
        for (final pId in relevantParentIds) {
          final doc = await _firestore.getDocument('users/$pId');
          if (doc != null) {
            parentsList.add(DirectoryUser.fromFirestore(doc));
          }
        }
        state = AsyncValue.data(parentsList);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class ParentsScreen extends ConsumerWidget {
  const ParentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(parentsProvider);

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
                    'Consultation des tuteurs légaux (filtré autoritairement par établissement pour les admins d\'école).',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Actualiser',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () =>
                    ref.read(parentsProvider.notifier).loadParents(),
              ),
            ],
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
                      'Erreur lors du chargement des parents:\n$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: StudioColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(parentsProvider.notifier).loadParents(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (list) {
                return StudioDataTable<DirectoryUser>(
                  items: list,
                  searchHint:
                      'Rechercher un parent par nom, téléphone ou email...',
                  filterPredicate: (u, q) =>
                      u.fullName.toLowerCase().contains(q) ||
                      u.phone.contains(q) ||
                      u.email.toLowerCase().contains(q),
                  columns: [
                    StudioTableColumn(
                      header: 'Parent',
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
                            'ID: ${u.id}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: StudioColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StudioTableColumn(
                      header: 'Téléphone',
                      flex: 2,
                      cellBuilder: (u) =>
                          Text(u.phone.isNotEmpty ? u.phone : '—'),
                    ),
                    StudioTableColumn(
                      header: 'E-mail',
                      flex: 2,
                      cellBuilder: (u) =>
                          Text(u.email.isNotEmpty ? u.email : '—'),
                    ),
                    StudioTableColumn(
                      header: 'Statut Compte',
                      width: 120,
                      cellBuilder: (u) => StudioBadge(
                        label: u.isActive
                            ? 'Actif'
                            : (u.isSuspended ? 'Suspendu' : 'Inactif'),
                        variant: u.isActive
                            ? StudioBadgeVariant.success
                            : StudioBadgeVariant.warning,
                      ),
                    ),
                  ],
                  actionsBuilder: (u) => IconButton(
                    tooltip: 'Consulter la fiche famille',
                    icon: const Icon(
                      Icons.visibility_rounded,
                      size: 18,
                      color: StudioColors.navyPrimary,
                    ),
                    onPressed: () {
                      context.go('/parents/${u.id}');
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
