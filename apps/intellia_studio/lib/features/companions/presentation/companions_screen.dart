import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

final companionRuntimeConfigProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final client = ref.watch(controlPlaneClientProvider);
      return client.getCompanionRuntimeConfig();
    });

class CompanionsScreen extends ConsumerStatefulWidget {
  const CompanionsScreen({super.key});

  @override
  ConsumerState<CompanionsScreen> createState() => _CompanionsScreenState();
}

class _CompanionsScreenState extends ConsumerState<CompanionsScreen> {
  String _selectedCompanion = 'kira';

  static const String _kiraSpecification =
      'SPÉCIFICATION DU COMPAGNON — KIRA\n\n'
      '1. POSITIONNEMENT &\n   RÔLE ÉDUCATIF :\n'
      '   - Compagne d\'étude bienveillante, rigoureuse et patiente.\n'
      '   - Accompagne les élèves camerounais (de la 6ème à la Terminale, sous-systèmes francophone et anglophone).\n'
      '   - Axée sur la compréhension en profondeur, la méthodologie et le déblocage pas-à-pas.\n\n'
      '2. SIGNATURE ÉDITORIALE :\n'
      '   - Nom : Kira\n'
      '   - Spécialité : Méthodologie & Accompagnement\n'
      '   - Tempérament : Patiente & Explicative\n'
      '   - Devise : "Apprenons avec calme et sérénité."\n\n'
      '3. DIRECTIVES PÉDAGOGIQUES :\n'
      '   - Méthode socratique : ne jamais donner directement la solution brute d\'un exercice.\n'
      '   - S\'appuyer exclusivement sur le contexte académique officiel du MINESEC Cameroun fourni par le backend.\n'
      '   - Clarté mathématique et scientifique sans dispersion.\n\n'
      'NOTE ARCHITECTURALE :\n'
      'Le prompt système d\'inférence actif est assemblé dynamiquement par le backend (askTutor) avec le contexte académique vérifié de l\'élève. Il n\'est pas dupliqué statiquement dans Studio.';

  static const String _leoSpecification =
      'SPÉCIFICATION DU COMPAGNON — LÉO\n\n'
      '1. POSITIONNEMENT &\n   RÔLE ÉDUCATIF :\n'
      '   - Guide d\'entraînement, de défi et de performance académique.\n'
      '   - Stimule les élèves par des challenges progressifs et l\'auto-dépassement.\n'
      '   - Prépare activement aux examens officiels et grands concours (Polytechnique, ENSP, FMSB, ENS).\n\n'
      '2. SIGNATURE ÉDITORIALE :\n'
      '   - Nom : Léo\n'
      '   - Spécialité : Défis & Performance\n'
      '   - Tempérament : Dynamique & Challengeur\n'
      '   - Devise : "Dépasse tes limites et bats tes records !"\n\n'
      '3. DIRECTIVES PÉDAGOGIQUES :\n'
      '   - Exigeant, énergique et constructif.\n'
      '   - Valorise l\'effort, l\'esprit critique et la rigueur de raisonnement.\n'
      '   - Reste toujours arrimé aux programmes officiels du MINESEC Cameroun.\n\n'
      'NOTE ARCHITECTURALE :\n'
      'Le prompt système d\'inférence actif est assemblé dynamiquement par le backend (askTutor) avec le contexte académique vérifié de l\'élève. Il n\'est pas dupliqué statiquement dans Studio.';

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(companionRuntimeConfigProvider);

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
                    Text(
                      'Opérations Compagnons IA (Kira & Léo)',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Spécifications des compagnons, garde-fous pédagogiques et métadonnées de runtime.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualiser la configuration serveur',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(companionRuntimeConfigProvider),
              ),
              const SizedBox(width: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'kira',
                    label: Text('Kira (Méthodologie & Accompagnement)'),
                  ),
                  ButtonSegment(
                    value: 'leo',
                    label: Text('Léo (Défis & Performance)'),
                  ),
                ],
                selected: {_selectedCompanion},
                onSelectionChanged: (val) =>
                    setState(() => _selectedCompanion = val.first),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedCompanion == 'kira'
                                    ? 'Spécification du compagnon — Kira'
                                    : 'Spécification du compagnon — Léo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const StudioBadge(
                                label: 'SPÉCIFICATION ÉDITORIALE',
                                variant: StudioBadgeVariant.info,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Spécification éditoriale et rôle pédagogique. Le prompt d\'inférence actif est assemblé dynamiquement par le backend askTutor.',
                            style: TextStyle(
                              fontSize: 12,
                              color: StudioColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: StudioColors.surfaceDark.withValues(
                                  alpha: 0.03,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: StudioColors.borderLight,
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  _selectedCompanion == 'kira'
                                      ? _kiraSpecification
                                      : _leoSpecification,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: StudioColors.borderLight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: configAsync.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (err, _) => const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Configuration Runtime IA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    StudioBadge(
                                      label: 'INDISPONIBLE',
                                      variant: StudioBadgeVariant.warning,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Configuration serveur indisponible',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: StudioColors.warning,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'L\'endpoint getCompanionRuntimeConfig n\'est pas encore joignable ou nécessite des droits SuperAdmin. Aucun modèle statique de secours n\'est affiché afin de garantir l\'exactitude des informations de production.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: StudioColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            data: (data) {
                              final model = data['model']?.toString();
                              if (model == null || model.isEmpty) {
                                return const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Configuration Runtime IA',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        StudioBadge(
                                          label: 'INDISPONIBLE',
                                          variant: StudioBadgeVariant.warning,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Configuration serveur indisponible',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: StudioColors.warning,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Aucune configuration de modèle valide n\'a été renvoyée par le serveur.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: StudioColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              final provider =
                                  data['provider']?.toString() ??
                                  'Donnée non disponible';
                              final tutorThinking =
                                  data['tutorThinkingLevel']?.toString() ??
                                  'Donnée non disponible';
                              final structuredThinking =
                                  data['structuredThinkingLevel']?.toString() ??
                                  'Donnée non disponible';
                              final location =
                                  data['location']?.toString() ??
                                  'Donnée non disponible';
                              final isConfigured = data['configured'] == true;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Configuration Runtime IA',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      StudioBadge(
                                        label: isConfigured
                                            ? 'OPÉRATIONNEL'
                                            : 'NON CONFIGURÉ',
                                        variant: isConfigured
                                            ? StudioBadgeVariant.success
                                            : StudioBadgeVariant.warning,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildConfigRow(
                                    'Fournisseur d\'inférence :',
                                    provider,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildConfigRow(
                                    'Modèle sous-jacent :',
                                    model,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildConfigRow(
                                    'Réflexion tuteur (Kira & Léo) :',
                                    tutorThinking,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildConfigRow(
                                    'Réflexion structurée :',
                                    structuredThinking,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildConfigRow(
                                    'Région Vertex AI :',
                                    location,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildConfigRow(
                                    'Température :',
                                    'valeur par défaut du modèle',
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: StudioColors.borderLight,
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Télémétrie & Quotas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Questions traitées aujourd\'hui : Donnée non disponible',
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Temps moyen de réponse : Donnée non disponible',
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Taux de satisfaction tuteur : Donnée non disponible',
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Note : La télémétrie agrégée globale n\'est pas synthétisée. Chaque élève dispose d\'une Réserve d\'étude et d\'un quota journalier mesurés côté serveur.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: StudioColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: StudioColors.navyPrimary,
          ),
        ),
      ],
    );
  }
}
