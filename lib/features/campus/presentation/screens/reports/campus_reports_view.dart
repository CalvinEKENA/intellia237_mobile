import 'package:flutter/material.dart';

import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_kpi_card.dart';

class CampusReportsView extends StatelessWidget {
  const CampusReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = CampusLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.navReports,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: CampusTokens.campusGraphite,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.isEnglish
                ? 'Internal establishment pedagogical reports and synthesis.'
                : 'Rapports pédagogiques internes et synthèses périodiques de l’établissement.',
            style: const TextStyle(
              fontSize: 13,
              color: CampusTokens.campusGraphiteSecondary,
            ),
          ),
          const SizedBox(height: 24),
          // 4 Allowed Initial Reports
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 800;
              return GridView.count(
                crossAxisCount: isWide ? 2 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 2.0 : 2.2,
                children: [
                  CampusKpiCard(
                    category: 'Rapport officiel',
                    metric: 'Avancement 82 %',
                    label: 'Progression du programme officiel',
                    subtitle:
                        'Synthèse hebdomadaire de la couverture des séquences officielles.',
                    icon: Icons.auto_stories_outlined,
                    onTap: () {},
                  ),
                  CampusKpiCard(
                    category: 'Synthèse collective',
                    metric: '36 classes',
                    label: 'Panorama des acquis et consolidations',
                    subtitle:
                        'Cartographie des notions nécessitant un renforcement par classe.',
                    icon: Icons.groups_outlined,
                    onTap: () {},
                  ),
                  CampusKpiCard(
                    category: 'Ressources',
                    metric: '18 fiches',
                    label: 'Diffusion et utilisation des ressources',
                    subtitle:
                        'Taux d’appropriation des fiches méthodologiques et exercices.',
                    icon: Icons.menu_book_outlined,
                    onTap: () {},
                  ),
                  CampusKpiCard(
                    category: 'Évaluations',
                    metric: '92 % assiduité',
                    label: 'Participation aux quiz diagnostiques',
                    subtitle:
                        'Taux de complétion des entraînements et quiz de fin de chapitre.',
                    icon: Icons.quiz_outlined,
                    onTap: () {},
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
