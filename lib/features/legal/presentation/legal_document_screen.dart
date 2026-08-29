import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';

enum LegalDocumentType { terms, privacy, educationalData }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({required this.type, super.key});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final document = _LegalDocument.forType(type);
    return Scaffold(
      backgroundColor: IntelliaColors.backgroundPrimary,
      appBar: AppBar(title: Text(document.title)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          children: [
            Text(
              document.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              'Version du 16 juillet 2026',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: IntelliaSpacing.lg),
            for (final section in document.sections) ...[
              Text(
                section.$1,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: IntelliaSpacing.xs),
              Text(
                section.$2,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
              const SizedBox(height: IntelliaSpacing.lg),
            ],
            Container(
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              decoration: BoxDecoration(
                color: IntelliaColors.brandIndigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(IntelliaRadii.large),
              ),
              child: const Text(
                'Pour toute question ou demande liée aux données, contacte ton établissement ou l’équipe Intellia237. Une validation juridique locale reste requise avant la mise en production commerciale.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDocument {
  const _LegalDocument({required this.title, required this.sections});

  final String title;
  final List<(String, String)> sections;

  static _LegalDocument forType(LegalDocumentType type) => switch (type) {
    LegalDocumentType.terms => const _LegalDocument(
      title: 'Conditions d’utilisation',
      sections: [
        (
          'Objet du service',
          'Intellia237 fournit des ressources pédagogiques, des quiz et un compagnon d’apprentissage. Le service complète l’enseignement et ne remplace ni l’établissement ni l’enseignant.',
        ),
        (
          'Compte et sécurité',
          'Les informations fournies doivent être exactes. Les identifiants restent personnels. Les comptes enseignants et administrateurs peuvent nécessiter une validation.',
        ),
        (
          'Usage responsable',
          'Il est interdit de contourner les règles des évaluations, d’extraire des données d’autres utilisateurs ou d’utiliser le compagnon pour produire un contenu nuisible.',
        ),
        (
          'Disponibilité',
          'Certaines fonctions exigent une connexion. Les maintenances et indisponibilités temporaires sont signalées aussi clairement que possible.',
        ),
      ],
    ),
    LegalDocumentType.privacy => const _LegalDocument(
      title: 'Politique de confidentialité',
      sections: [
        (
          'Données collectées',
          'Le compte, le rôle, la classe, la progression et les tentatives nécessaires au service peuvent être enregistrés. Les données demandées doivent rester limitées à la finalité pédagogique.',
        ),
        (
          'Mineurs et confidentialité',
          'Les conversations, réponses libres, noms et e-mails ne doivent jamais être envoyés aux outils de mesure d’audience. Les diagnostics anonymes sont désactivés par défaut.',
        ),
        (
          'Conservation et accès',
          'Les données sont accessibles uniquement aux personnes autorisées selon leur rôle. Les durées de conservation et procédures d’accès doivent être validées avant mise en production.',
        ),
        (
          'Vos droits',
          'L’utilisateur ou son représentant peut demander l’accès, la correction ou la suppression de ses données auprès de l’établissement ou de l’équipe Intellia237.',
        ),
      ],
    ),
    LegalDocumentType.educationalData => const _LegalDocument(
      title: 'Traitement pédagogique des données',
      sections: [
        (
          'Finalité',
          'Les réponses, résultats et progressions servent à proposer une prochaine étape, présenter une correction et aider l’enseignant ou le parent autorisé à accompagner l’élève.',
        ),
        (
          'Décisions',
          'Une recommandation automatisée ne constitue pas une décision scolaire officielle. L’enseignant et l’établissement restent responsables de l’évaluation académique.',
        ),
        (
          'Compagnon pédagogique',
          'Les messages sont transmis au service nécessaire pour générer une réponse. L’élève ne doit pas y communiquer d’information personnelle sensible.',
        ),
      ],
    ),
  };
}
