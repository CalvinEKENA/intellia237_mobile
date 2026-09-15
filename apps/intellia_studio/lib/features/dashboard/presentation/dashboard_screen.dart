import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/studio_theme.dart';
import '../../auth/application/auth_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;

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
            'Console de commandement et d\'exploitation globale INTELLIA237.',
            style: TextStyle(color: StudioColors.textSecondaryLight),
          ),
          const SizedBox(height: 24),

          // KPI Cards Row
          Row(
            children: [
              _buildKpiCard(
                'Établissements Actifs',
                '12',
                Icons.school_rounded,
                StudioColors.navyPrimary,
              ),
              const SizedBox(width: 16),
              _buildKpiCard(
                'Élèves Inscrits',
                '2,480',
                Icons.person_rounded,
                StudioColors.blueAccent,
              ),
              const SizedBox(width: 16),
              _buildKpiCard(
                'Parents Rattachés',
                '1,840',
                Icons.family_restroom_rounded,
                StudioColors.goldAccent,
              ),
              const SizedBox(width: 16),
              _buildKpiCard(
                'Enseignants Validés',
                '142',
                Icons.co_present_rounded,
                StudioColors.success,
              ),
            ],
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
                            'Alertes & Décisions en Attente',
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
                        title: '1 demande de paiement Mobile Money en attente',
                        subtitle:
                            'Paiement de 15 000 XAF par Jean Mballa (Orange Money)',
                        color: StudioColors.warning,
                      ),
                      const Divider(
                        height: 16,
                        color: StudioColors.borderLight,
                      ),
                      _buildAlertTile(
                        icon: Icons.how_to_reg_rounded,
                        title: '2 demandes de personnel enseignant à valider',
                        subtitle: 'Collège Libermann & Lycée Général Leclerc',
                        color: StudioColors.info,
                      ),
                      const Divider(
                        height: 16,
                        color: StudioColors.borderLight,
                      ),
                      _buildAlertTile(
                        icon: Icons.hourglass_empty_rounded,
                        title: 'Plan Réserve d\'Étude non provisionné',
                        subtitle:
                            '1 établissement sans document study_reserve_plans',
                        color: StudioColors.error,
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
                            'Santé des Services Cloud',
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
                        'Opérationnel',
                        true,
                      ),
                      const SizedBox(height: 12),
                      _buildHealthIndicator(
                        'Firestore Database (edunova-aabd1)',
                        'Opérationnel',
                        true,
                      ),
                      const SizedBox(height: 12),
                      _buildHealthIndicator(
                        'Cloud Storage (educational_assets)',
                        'Opérationnel',
                        true,
                      ),
                      const SizedBox(height: 12),
                      _buildHealthIndicator(
                        'Intégration Google Play Developer',
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
                    style: const TextStyle(
                      fontSize: 22,
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
