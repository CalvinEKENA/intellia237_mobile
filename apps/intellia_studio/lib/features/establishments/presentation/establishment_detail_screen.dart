import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class EstablishmentDetailScreen extends ConsumerWidget {
  const EstablishmentDetailScreen({super.key, required this.establishmentId});

  final String establishmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/establishments'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lycée Général Leclerc',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Établissement ID: $establishmentId • Yaoundé, Centre • Type: Public',
                      style: const TextStyle(
                        color: StudioColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const StudioBadge(
                label: 'ACTIF',
                variant: StudioBadgeVariant.success,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildKpiCard('Élèves inscrits', '842', Icons.school_rounded),
              const SizedBox(width: 16),
              _buildKpiCard(
                'Classes actives',
                '24',
                Icons.meeting_room_rounded,
              ),
              const SizedBox(width: 16),
              _buildKpiCard('Enseignants', '48', Icons.psychology_rounded),
              const SizedBox(width: 16),
              _buildKpiCard(
                'Taux d\'activation',
                '94.2%',
                Icons.check_circle_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                    Text(
                      'Classes associées à cet établissement',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: const [
                          ListTile(
                            leading: Icon(
                              Icons.class_rounded,
                              color: StudioColors.navyPrimary,
                            ),
                            title: Text('Terminale C1 (38 élèves)'),
                            subtitle: Text(
                              'Série C • Enseignant principal : M. Talla',
                            ),
                            trailing: StudioBadge(
                              label: 'ACTIF',
                              variant: StudioBadgeVariant.success,
                            ),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(
                              Icons.class_rounded,
                              color: StudioColors.navyPrimary,
                            ),
                            title: Text('Terminale D2 (42 élèves)'),
                            subtitle: Text(
                              'Série D • Enseignante principale : Mme Ngo',
                            ),
                            trailing: StudioBadge(
                              label: 'ACTIF',
                              variant: StudioBadgeVariant.success,
                            ),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(
                              Icons.class_rounded,
                              color: StudioColors.navyPrimary,
                            ),
                            title: Text('Première A4 (45 élèves)'),
                            subtitle: Text(
                              'Série Littéraire • Enseignant principal : M. Bipoun',
                            ),
                            trailing: StudioBadge(
                              label: 'ACTIF',
                              variant: StudioBadgeVariant.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: StudioColors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: StudioColors.navyPrimary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: StudioColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
