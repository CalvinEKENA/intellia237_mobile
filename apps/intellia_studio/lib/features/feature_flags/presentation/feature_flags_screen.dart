import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class FeatureFlagsScreen extends ConsumerWidget {
  const FeatureFlagsScreen({super.key});

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
                  Text('Indicateurs de Fonctionnalités (Feature Flags)', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'Gestion du déploiement progressif (Remote Config) pour les applications mobiles et web.',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nouveau Flag'),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildFlagCard('enable_flow_v2', 'Nouveau moteur de défilement immersif FLOW', 100, true),
                const SizedBox(height: 12),
                _buildFlagCard('enable_notebooklm_importer', 'Importateur automatique de cours par NotebookLM', 100, true),
                const SizedBox(height: 12),
                _buildFlagCard('enable_audio_kira', 'Synthèse vocale locale pour Kira en français camerounais', 50, true),
                const SizedBox(height: 12),
                _buildFlagCard('enable_study_reserve_v1', 'Nouveau modèle d\'allocation de réserve d\'étude', 100, true),
                const SizedBox(height: 12),
                _buildFlagCard('enable_offline_lessons', 'Téléchargement hors-ligne des leçons (Beta)', 25, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagCard(String key, String description, int rolloutPercent, bool isEnabled) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: StudioColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Switch(value: isEnabled, onChanged: (_) {}),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(fontSize: 12, color: StudioColors.textSecondaryLight)),
                ],
              ),
            ),
            StudioBadge(label: 'DÉPLOIEMENT $rolloutPercent%', variant: isEnabled ? StudioBadgeVariant.info : StudioBadgeVariant.neutral),
          ],
        ),
      ),
    );
  }
}
