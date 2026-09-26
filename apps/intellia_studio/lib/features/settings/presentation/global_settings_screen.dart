import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class GlobalSettingsScreen extends ConsumerWidget {
  const GlobalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres Généraux du Système',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Constantes académiques et quotas nominaux d\'infrastructure (Mode Lecture Seule / Consultation).',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
              const StudioBadge(
                label: 'LECTURE SEULE / PARTIEL',
                variant: StudioBadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StudioColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: StudioColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: StudioColors.warning,
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Précision d\'Architecture : La collection Firestore settings/{uid} est réservée aux préférences par utilisateur. Aucun modèle de configuration globale modifiable n\'est provisionné sur le backend. Ces valeurs reflètent les constantes du système MINESEC et ne peuvent être modifiées sans un endpoint Cloud dédié.',
                    style: TextStyle(
                      fontSize: 12,
                      color: StudioColors.navyPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                Card(
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
                        const Text(
                          'Année Scolaire & Calendrier Académique',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Divider(height: 24),
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Année académique en vigueur'),
                          subtitle: Text(
                            '2025 - 2026 (Calendrier officiel MINESEC Cameroun)',
                          ),
                          trailing: StudioBadge(
                            label: 'ACTIF',
                            variant: StudioBadgeVariant.success,
                          ),
                        ),
                        const Divider(),
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Période académique courante'),
                          subtitle: Text(
                            '3ème Trimestre (Préparation aux épreuves nationales Bacc & BEPC)',
                          ),
                          trailing: StudioBadge(
                            label: 'TRIMESTRE 3',
                            variant: StudioBadgeVariant.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: StudioColors.borderLight),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quotas Nominales & Paramètres IA Serveur',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Divider(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Limite journalière Kira & Léo (TUTOR_DAILY_QUESTION_LIMIT)',
                          ),
                          subtitle: Text(
                            '20 questions par jour et par élève (défini dans backend Functions)',
                          ),
                          trailing: Text(
                            '20 req/j',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Seuils canoniques Réserve d\'Étude'),
                          subtitle: Text(
                            '[75%, 50%, 25%, 5%, 0%] avec émission d\'alerte FCM',
                          ),
                          trailing: Text(
                            'Canonicaux',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Région de calcul Cloud Functions'),
                          subtitle: Text(
                            'europe-west1 (Projet Firebase edunova-aabd1)',
                          ),
                          trailing: Text(
                            'europe-west1',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
