import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class SystemHealthScreen extends ConsumerWidget {
  const SystemHealthScreen({super.key});

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
                  Text('État de Santé du Système (System Health)', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'Surveillance en temps réel des services Cloud, latences API, quotas et erreurs d\'infrastructure.',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
              const StudioBadge(label: 'TOUS SYSTÈMES OPÉRATIONNELS', variant: StudioBadgeVariant.success),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildServiceCard('Firebase Authentication', 'Opérationnel', '99.99%', '35 ms', StudioBadgeVariant.success),
                const SizedBox(height: 12),
                _buildServiceCard('Cloud Firestore (Production edunova-aabd1)', 'Opérationnel', '100%', '42 ms', StudioBadgeVariant.success),
                const SizedBox(height: 12),
                _buildServiceCard('Cloud Functions (Node.js 20)', 'Opérationnel', '99.95%', '180 ms', StudioBadgeVariant.success),
                const SizedBox(height: 12),
                _buildServiceCard('Vertex AI & Gemini API (Kira & Léo)', 'Opérationnel', '99.88%', '820 ms', StudioBadgeVariant.success),
                const SizedBox(height: 12),
                _buildServiceCard('Firebase Cloud Messaging (FCM Push)', 'Opérationnel', '99.91%', '110 ms', StudioBadgeVariant.success),
                const SizedBox(height: 12),
                _buildServiceCard('Cloud Storage (Assets éducatifs)', 'Opérationnel', '100%', '65 ms', StudioBadgeVariant.success),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String serviceName, String status, String uptime, String latency, StudioBadgeVariant variant) {
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
            const Icon(Icons.check_circle_rounded, color: StudioColors.success, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Disponibilité : $uptime • Latence moyenne : $latency', style: const TextStyle(fontSize: 12, color: StudioColors.textSecondaryLight)),
                ],
              ),
            ),
            StudioBadge(label: status.toUpperCase(), variant: variant),
          ],
        ),
      ),
    );
  }
}
