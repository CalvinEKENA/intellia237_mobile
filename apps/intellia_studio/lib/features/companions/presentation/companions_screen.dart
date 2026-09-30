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
                                label: 'SPÉCIFICATION SERVEUR',
                                variant: StudioBadgeVariant.info,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Texte réellement envoyé au modèle par askTutor : rôle, règles pédagogiques et garde-fous. Lu depuis le serveur, jamais recopié ici.',
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
                                  configAsync.maybeWhen(
                                    data: (config) =>
                                        formatCompanionSpecification(
                                          config,
                                          _selectedCompanion,
                                        ),
                                    loading: () =>
                                        'Chargement de la spécification serveur…',
                                    orElse: () =>
                                        kCompanionSpecificationUnavailable,
                                  ),
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

const kCompanionSpecificationUnavailable =
    'Spécification serveur indisponible. Aucun texte n\'est affiché de mémoire : '
    'ce qui est montré ici doit être ce que le modèle reçoit.';

/// Met en forme la spécification publiée par `getCompanionRuntimeConfig`.
///
/// Studio n'a aucune copie locale des règles : si le serveur ne publie pas la
/// spécification (ancienne version déployée), l'écran le dit.
String formatCompanionSpecification(
  Map<String, dynamic> config,
  String companionId,
) {
  final companions = config['companions'];
  if (companions is! List) return kCompanionSpecificationUnavailable;
  final entry = companions.whereType<Map>().where(
    (companion) => companion['id'] == companionId,
  );
  if (entry.isEmpty) return kCompanionSpecificationUnavailable;
  final spec = entry.first;
  String fr(Object? value) => value is Map ? '${value['fr'] ?? ''}' : '';
  List<String> frList(Object? value) => value is Map && value['fr'] is List
      ? [for (final line in value['fr'] as List) '$line']
      : const [];
  final name = '${spec['displayName'] ?? companionId}'.toUpperCase();
  final buffer = StringBuffer()
    ..writeln('SPÉCIFICATION DU COMPAGNON — $name')
    ..writeln()
    ..writeln('Rôle : ${fr(spec['role'])}')
    ..writeln('Tempérament : ${fr(spec['temperament'])}')
    ..writeln('Devise : « ${fr(spec['motto'])} »')
    ..writeln();
  void section(String title, List<String> lines) {
    if (lines.isEmpty) return;
    buffer.writeln(title);
    for (final line in lines) {
      buffer.writeln('  - $line');
    }
    buffer.writeln();
  }

  section('STYLE :', frList(spec['style']));
  section('RÈGLES PÉDAGOGIQUES :', frList(spec['pedagogy']));
  section('GARDE-FOUS (MINEURS) :', frList(spec['safety']));
  section('FORME :', frList(spec['format']));
  buffer.writeln(
    'Le même texte existe en anglais pour les élèves anglophones ; '
    'la langue est choisie par le serveur depuis le profil.',
  );
  return buffer.toString().trimRight();
}
