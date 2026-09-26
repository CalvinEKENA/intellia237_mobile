import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

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
                onPressed: () => context.go('/students'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calvin Ekena',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Élève ID: $studentId • Terminale C • Lycée Leclerc, Yaoundé',
                      style: const TextStyle(
                        color: StudioColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const StudioBadge(
                label: 'PREMIUM ACTIF',
                variant: StudioBadgeVariant.success,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: StudioColors.goldAccent),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Réserve d\'Étude Individuelle',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      StudioBadge(
                        label: 'CYCLE EN COURS',
                        variant: StudioBadgeVariant.info,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '480 000 / 600 000 unités (80% consommé)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: 0.8,
                              backgroundColor: StudioColors.borderLight,
                              color: StudioColors.goldAccent,
                              minHeight: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Renouvellement automatique par les Cloud Functions au 31/03/2026.',
                    style: TextStyle(
                      fontSize: 11,
                      color: StudioColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                          Text(
                            'Parents rattachés',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          const ListTile(
                            leading: CircleAvatar(child: Text('SE')),
                            title: Text('Suzanne Ekena (Mère)'),
                            subtitle: Text(
                              '+237 699 01 23 45 • Tuteur financier',
                            ),
                            trailing: StudioBadge(
                              label: 'VÉRIFIÉ',
                              variant: StudioBadgeVariant.success,
                            ),
                          ),
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
                          Text(
                            'Activité pédagogique récente',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          const ListTile(
                            leading: Icon(
                              Icons.auto_stories,
                              color: StudioColors.navyPrimary,
                            ),
                            title: Text(
                              'Leçon complétée : Théorème des Valeurs Intermédiaires',
                            ),
                            subtitle: Text('Mathématiques • Hier à 17:42'),
                          ),
                          const ListTile(
                            leading: Icon(
                              Icons.quiz_rounded,
                              color: StudioColors.goldAccent,
                            ),
                            title: Text(
                              'Quiz : Cinématique & Dynamique (Score: 18/20)',
                            ),
                            subtitle: Text('Physique • 13/03/2026 à 20:15'),
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
      ),
    );
  }
}
