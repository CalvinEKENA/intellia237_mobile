import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytique Opérationnelle & Pédagogique', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text(
            'Indicateurs d\'apprentissage, assiduité, complétion des leçons et efficacité des tuteurs.',
            style: TextStyle(color: StudioColors.textSecondaryLight),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMetric('Utilisateurs Actifs Quotidiens (DAU)', '18 420', '+12% ce mois'),
              const SizedBox(width: 16),
              _buildMetric('Leçons Complétées', '94 210', '98% satisfaction'),
              const SizedBox(width: 16),
              _buildMetric('Questions Tuteur IA Résolues', '142 800', 'Temps moyen 820ms'),
              const SizedBox(width: 16),
              _buildMetric('Score Moyen aux Quiz', '15.4 / 20', 'Progression constante'),
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
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_rounded, size: 48, color: StudioColors.navyPrimary),
                    SizedBox(height: 12),
                    Text('Tableaux de bord analytiques en temps réel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Données agrégées depuis BigQuery et Firebase Analytics.', style: TextStyle(color: StudioColors.textSecondaryLight)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String title, String value, String subtitle) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: StudioColors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: StudioColors.textSecondaryLight)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: StudioColors.navyPrimary)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: StudioColors.success)),
            ],
          ),
        ),
      ),
    );
  }
}
