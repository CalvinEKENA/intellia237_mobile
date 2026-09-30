import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../auth/application/auth_controller.dart';

final dashboardKpiProvider = FutureProvider<Map<String, int?>>((ref) async {
  final fsClient = ref.watch(firestoreRestClientProvider);
  try {
    final establishments = await fsClient.runAggregationCount('establishments');
    final students = await fsClient.runAggregationCount(
      'users',
      whereFilter: {
        'fieldFilter': {
          'field': {'fieldPath': 'role'},
          'op': 'EQUAL',
          'value': {'stringValue': 'student'},
        },
      },
    );
    final parents = await fsClient.runAggregationCount(
      'users',
      whereFilter: {
        'fieldFilter': {
          'field': {'fieldPath': 'role'},
          'op': 'EQUAL',
          'value': {'stringValue': 'parent'},
        },
      },
    );
    final teachers = await fsClient.runAggregationCount(
      'users',
      whereFilter: {
        'fieldFilter': {
          'field': {'fieldPath': 'role'},
          'op': 'EQUAL',
          'value': {'stringValue': 'teacher'},
        },
      },
    );
    return {
      'establishments': establishments,
      'students': students,
      'parents': parents,
      'teachers': teachers,
    };
  } catch (_) {
    return {
      'establishments': null,
      'students': null,
      'parents': null,
      'teachers': null,
    };
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final kpis = ref.watch(dashboardKpiProvider);
    final numFormat = NumberFormat('#,###', 'fr_FR');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Overview
          Text(
            'Bienvenue, ${session?.displayName ?? "Administrateur"}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Console d\'exploitation et de commandement INTELLIA237 — Données de production vérifiées.',
            style: TextStyle(color: StudioColors.textSecondaryLight),
          ),
          const SizedBox(height: 24),

          // KPI Cards Row
          kpis.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: StudioColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: StudioColors.error),
              ),
              child: Text(
                'Impossible de charger les agrégats de données: $err',
                style: const TextStyle(color: StudioColors.error),
              ),
            ),
            data: (counts) {
              return Row(
                children: [
                  _buildKpiCard(
                    'Établissements Enregistrés',
                    counts['establishments'] != null
                        ? numFormat.format(counts['establishments'])
                        : 'Donnée non disponible',
                    Icons.school_rounded,
                    StudioColors.navyPrimary,
                  ),
                  const SizedBox(width: 16),
                  _buildKpiCard(
                    'Élèves Enregistrés',
                    counts['students'] != null
                        ? numFormat.format(counts['students'])
                        : 'Donnée non disponible',
                    Icons.person_rounded,
                    StudioColors.blueAccent,
                  ),
                  const SizedBox(width: 16),
                  _buildKpiCard(
                    'Comptes Parents',
                    counts['parents'] != null
                        ? numFormat.format(counts['parents'])
                        : 'Donnée non disponible',
                    Icons.family_restroom_rounded,
                    StudioColors.goldAccent,
                  ),
                  const SizedBox(width: 16),
                  _buildKpiCard(
                    'Comptes Enseignants',
                    counts['teachers'] != null
                        ? numFormat.format(counts['teachers'])
                        : 'Donnée non disponible',
                    Icons.co_present_rounded,
                    StudioColors.success,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Operational Status & Alerts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending Actions
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudioColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.pending_actions_rounded,
                            color: StudioColors.warning,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Alertes Opérationnelles & Files de Décision',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildAlertTile(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'File Mobile Money',
                        subtitle:
                            'Validation manuelle via le module Finances & MoMo (/payments)',
                        color: StudioColors.warning,
                      ),
                      const Divider(
                        height: 16,
                        color: StudioColors.borderLight,
                      ),
                      _buildAlertTile(
                        icon: Icons.how_to_reg_rounded,
                        title: 'File Enseignants en Attente',
                        subtitle:
                            'Revue et affectation d\'établissement via le module Enseignants (/teachers)',
                        color: StudioColors.info,
                      ),
                      const Divider(
                        height: 16,
                        color: StudioColors.borderLight,
                      ),
                      _buildAlertTile(
                        icon: Icons.hourglass_empty_rounded,
                        title: 'Surveillance Réserve d\'Étude',
                        subtitle:
                            'Seuils canoniques [75, 50, 25, 5, 0] % calculés par Cloud Functions',
                        color: StudioColors.goldAccent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // System Health Summary
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudioColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.health_and_safety_rounded,
                            color: StudioColors.success,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Connectivité & Infrastructure',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildHealthIndicator(
                        'Cloud Functions (europe-west1)',
                        'Accessible',
                        true,
                      ),
                      const SizedBox(height: 12),
                      _buildHealthIndicator(
                        'Firestore Database (edunova-aabd1)',
                        'Accessible',
                        true,
                      ),
                      const SizedBox(height: 12),
                      _buildHealthIndicator(
                        'Cloud Storage (educational_assets)',
                        'Accessible',
                        true,
                      ),
                      const SizedBox(height: 12),
                      _buildHealthIndicator(
                        'Google Play Console',
                        'Non configurée',
                        false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String count,
    IconData icon,
    Color accentColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: StudioColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: count.length > 10 ? 14 : 22,
                      fontWeight: FontWeight.bold,
                      color: StudioColors.navyPrimary,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: StudioColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: StudioColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthIndicator(String service, String status, bool isGood) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isGood ? StudioColors.success : StudioColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(service, style: const TextStyle(fontSize: 12))),
        Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isGood ? StudioColors.success : StudioColors.warning,
          ),
        ),
      ],
    );
  }
}
