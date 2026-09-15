import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/user_directory_models.dart';

final parentDetailFamilyProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, parentId) async {
  final fs = ref.watch(firestoreRestClientProvider);
  final session = ref.watch(authSessionProvider).asData?.value;
  final isSuperAdmin = session?.isSuperAdmin ?? false;
  final adminEstablishmentId = session?.establishmentId ?? '';

  // 1. Load Parent Doc
  final parentDoc = await fs.getDocument('users/$parentId');
  if (parentDoc == null) {
    throw Exception('Parent introuvable.');
  }
  final parentUser = DirectoryUser.fromFirestore(parentDoc);

  // 2. Query children_links for this parent
  final linksDocs = await fs.runQuery(
    fromCollection: 'children_links',
    whereFilter: {
      'fieldFilter': {
        'field': {'fieldPath': 'parentId'},
        'op': 'EQUAL',
        'value': {'stringValue': parentId},
      }
    },
    limit: 50,
  );

  // 3. For each link, load student doc
  final allChildren = <Map<String, dynamic>>[];
  int hiddenCount = 0;

  for (final l in linksDocs) {
    final studentId = l['studentId'] as String? ?? '';
    final linkStatus = l['status'] as String? ?? 'pending';
    if (studentId.isEmpty) continue;

    final studentDoc = await fs.getDocument('users/$studentId');
    if (studentDoc != null) {
      final studentEstId = studentDoc['establishmentId'] as String? ?? '';
      final studentEstName = studentDoc['establishmentName'] as String? ?? studentEstId;
      final studentClass = studentDoc['classLevel'] as String? ?? studentDoc['currentClass'] as String? ?? '—';
      final studentName = studentDoc['displayName'] as String? ??
          '${studentDoc['firstName'] ?? ''} ${studentDoc['lastName'] ?? ''}'.trim();

      // Enforce multi-school family scoping:
      if (isSuperAdmin || studentEstId == adminEstablishmentId) {
        allChildren.add({
          'id': studentId,
          'name': studentName.isNotEmpty ? studentName : studentId,
          'establishmentId': studentEstId,
          'establishmentName': studentEstName,
          'classLevel': studentClass,
          'linkStatus': linkStatus,
        });
      } else {
        // Child belongs to another school! Hidden from this school admin!
        hiddenCount++;
      }
    }
  }

  return {
    'parent': parentUser,
    'children': allChildren,
    'hiddenCount': hiddenCount,
  };
});

class ParentDetailScreen extends ConsumerWidget {
  const ParentDetailScreen({super.key, required this.parentId});

  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(parentDetailFamilyProvider(parentId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: familyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: StudioColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Erreur: $err', style: const TextStyle(color: StudioColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/parents'),
                child: const Text('Retour au répertoire'),
              ),
            ],
          ),
        ),
        data: (data) {
          final parent = data['parent'] as DirectoryUser;
          final children = data['children'] as List<Map<String, dynamic>>;
          final hiddenCount = data['hiddenCount'] as int;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/parents'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(parent.fullName, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Parent ID: ${parent.id} • ${parent.phone.isNotEmpty ? parent.phone : "Sans tél."} • ${parent.email.isNotEmpty ? parent.email : "Sans email"}',
                          style: const TextStyle(color: StudioColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  StudioBadge(
                    label: parent.isActive ? 'COMPTE ACTIF' : 'COMPTE SUSPENDU',
                    variant: parent.isActive ? StudioBadgeVariant.success : StudioBadgeVariant.warning,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: StudioColors.borderLight),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Enfants rattachés au compte',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 12),
                              if (children.isEmpty && hiddenCount == 0)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    'Aucun enfant lié dans la collection children_links.',
                                    style: TextStyle(color: StudioColors.textSecondaryLight),
                                  ),
                                ),
                              for (final ch in children) ...[
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: StudioColors.navyPrimary.withValues(alpha: 0.1),
                                    child: Text(
                                      (ch['name'] as String).isNotEmpty
                                          ? (ch['name'] as String)[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(color: StudioColors.navyPrimary),
                                    ),
                                  ),
                                  title: Text(ch['name'] as String),
                                  subtitle: Text(
                                      '${ch['classLevel']} • ${ch['establishmentName']} (ID: ${ch['id']})'),
                                  trailing: StudioBadge(
                                    label: ch['linkStatus'] == 'approved' ? 'APPROUVÉ' : 'EN ATTENTE',
                                    variant: ch['linkStatus'] == 'approved'
                                        ? StudioBadgeVariant.success
                                        : StudioBadgeVariant.warning,
                                  ),
                                ),
                                const Divider(),
                              ],
                              if (hiddenCount > 0) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: StudioColors.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: StudioColors.warning.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.shield_outlined,
                                          color: StudioColors.warning, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$hiddenCount autre(s) enfant(s) de cette famille sont scolarisés dans un autre établissement. Leurs données sont cloisonnées conformément aux règles d\'isolation inter-établissements.',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: StudioColors.navyPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: StudioColors.borderLight),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Droits & Opérations Famille',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.info_outline, color: StudioColors.navyPrimary),
                                title: const Text('Cloisonnement Multi-Établissement'),
                                subtitle: const Text(
                                  'Le tuteur est unique au niveau national, mais chaque chef d\'établissement n\'administre que la relation concernant ses propres élèves.',
                                ),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.calendar_today, color: StudioColors.navyPrimary),
                                title: const Text('Date d\'inscription'),
                                subtitle: Text(
                                  parent.createdAt.toIso8601String().split('T').first,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
