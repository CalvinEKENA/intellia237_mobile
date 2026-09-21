import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

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
                    Text('Annonces & Communications Établissements', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Publication des communiqués officiels, calendrier des épreuves et alertes générales.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle Annonce'),
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
                    leading: Icon(Icons.announcement_rounded, color: StudioColors.navyPrimary),
                    title: Text('Ouverture des inscriptions aux sessions de révision intensives Bacc 2026'),
                    subtitle: Text('Portée : Nationale • Publié le 10/03/2026 par Direction Pédagogique'),
                    trailing: StudioBadge(label: 'PUBLIÉ', variant: StudioBadgeVariant.success),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.announcement_rounded, color: StudioColors.warning),
                    title: Text('Maintenance planifiée de la plateforme (18 Mars, 02h00 - 04h00)'),
                    subtitle: Text('Portée : Tous utilisateurs • Prévu le 18/03/2026'),
                    trailing: StudioBadge(label: 'PROGRAMMÉ', variant: StudioBadgeVariant.warning),
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
