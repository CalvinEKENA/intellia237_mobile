import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class ParentDetailScreen extends ConsumerWidget {
  const ParentDetailScreen({super.key, required this.parentId});

  final String parentId;

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
                onPressed: () => context.go('/parents'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mme Suzanne Ekena', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Parent ID: $parentId • +237 699 01 23 45 • suzanne.ekena@gmail.com',
                      style: const TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              const StudioBadge(label: 'ABONNEMENT ACTIF', variant: StudioBadgeVariant.success),
            ],
          ),
          const SizedBox(height: 24),
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
                          Text('Enfants associés au compte', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          const ListTile(
                            leading: CircleAvatar(child: Text('CE')),
                            title: Text('Calvin Ekena'),
                            subtitle: Text('Terminale C • Lycée Leclerc'),
                            trailing: StudioBadge(label: 'RÉSERVE 80%', variant: StudioBadgeVariant.warning),
                          ),
                          const Divider(),
                          const ListTile(
                            leading: CircleAvatar(child: Text('JE')),
                            title: Text('Junior Ekena'),
                            subtitle: Text('3ème • Collège François-Xavier Vogt'),
                            trailing: StudioBadge(label: 'RÉSERVE 25%', variant: StudioBadgeVariant.success),
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
                          Text('Historique des paiements & Droits', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          const ListTile(
                            leading: Icon(Icons.payment, color: StudioColors.success),
                            title: Text('5 000 FCFA — Formule Atelier (Mensuel)'),
                            subtitle: Text('Orange Money Réf: OM-2026-98124 • 15/03/2026'),
                            trailing: StudioBadge(label: 'APPROUVÉ', variant: StudioBadgeVariant.success),
                          ),
                          const Divider(),
                          const ListTile(
                            leading: Icon(Icons.payment, color: StudioColors.success),
                            title: Text('5 000 FCFA — Formule Atelier (Mensuel)'),
                            subtitle: Text('Orange Money Réf: OM-2026-87110 • 15/02/2026'),
                            trailing: StudioBadge(label: 'EXPIRÉ', variant: StudioBadgeVariant.neutral),
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
