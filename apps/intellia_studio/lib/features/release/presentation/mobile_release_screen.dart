import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class MobileReleaseScreen extends ConsumerWidget {
  const MobileReleaseScreen({super.key});

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
                    Text('Publication & Versions Mobile', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Visibilité des versions mobiles, politique de mise à jour forcée et statut des magasins.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              const StudioBadge(label: 'VERSION MOBILE 3.2.1+28', variant: StudioBadgeVariant.info),
            ],
          ),
          const SizedBox(height: 20),
          // Strict compliance with Amendment 6: The Studio must NOT guess Google Play release status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.amber, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statut Google Play Console : Intégration non configurée',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Conformément aux directives d\'architecture, le Studio ne devine aucun statut de publication '
                        'sur le Play Store. Pour afficher le statut en temps réel (Production, Alpha, Examen en cours), '
                        'veuillez configurer une clé de service Google Play Developer API.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Version Mobile Actuelle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 16),
                          ListTile(
                            leading: Icon(Icons.android, color: StudioColors.success),
                            title: Text('Version Publiée : 3.2.1 (Build 28)'),
                            subtitle: Text('Cible Android 15 (API 35) • Compilation Flutter 3.29'),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.security_update_warning, color: StudioColors.warning),
                            title: Text('Version Minimale Requise : 3.0.0 (Build 22)'),
                            subtitle: Text('Les versions antérieures affichent l\'écran de mise à jour obligatoire.'),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.update, color: StudioColors.navyPrimary),
                            title: Text('Mise à jour forcée (Force Update) : DÉSACTIVÉE'),
                            subtitle: Text('Activée uniquement en cas d\'incompatibilité majeure d\'API.'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
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
                          Text('Notes de Version (Changelog v3.2.1)', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          const Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                '- Intégration de la Réserve d\'Étude (Study Reserve) avec gestion autonome du quota IA\n'
                                '- Ajout du défilement continu et des quiz interactifs dans FLOW\n'
                                '- Optimisation des leçons hors-ligne et réduction de l\'empreinte cache\n'
                                '- Correction du calcul des frais Mobile Money Orange / MTN\n'
                                '- Amélioration des transitions d\'écran et respect de la palette institutionnelle',
                                style: TextStyle(fontSize: 13, height: 1.6),
                              ),
                            ),
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
