import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Journal des Notifications & Diffusion', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Historique des envois FCM, notifications in-app et alertes seuils de quota.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.send_rounded),
                label: const Text('Diffuser une Notification'),
                onPressed: () {},
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
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: const [
                  ListTile(
                    leading: Icon(Icons.notifications_active, color: StudioColors.goldAccent),
                    title: Text('Alerte Réserve d\'Étude 80% — Calvin Ekena'),
                    subtitle: Text('Mode : Inbox only • Déclenché par Cloud Functions • 15/03/2026 à 09:12'),
                    trailing: StudioBadge(label: 'DÉLIVRÉ', variant: StudioBadgeVariant.success),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.campaign_rounded, color: StudioColors.navyPrimary),
                    title: Text('Rappel Préparation Bacc Blanc Régional'),
                    subtitle: Text('Cible : Terminale (Toutes séries) • Push + Inbox • 14/03/2026 à 18:00'),
                    trailing: StudioBadge(label: 'DÉLIVRÉ (98.2%)', variant: StudioBadgeVariant.success),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.payment, color: StudioColors.success),
                    title: Text('Confirmation Activation Abonnement Atelier'),
                    subtitle: Text('Cible : Suzanne Ekena • Push + SMS • 15/03/2026 à 08:35'),
                    trailing: StudioBadge(label: 'DÉLIVRÉ', variant: StudioBadgeVariant.success),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
