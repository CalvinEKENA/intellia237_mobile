import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../domain/audience_models.dart';

final audienceRulesProvider = StateNotifierProvider<AudienceRulesNotifier, List<StudioAudienceRule>>((ref) {
  return AudienceRulesNotifier();
});

class AudienceRulesNotifier extends StateNotifier<List<StudioAudienceRule>> {
  AudienceRulesNotifier() : super([
    const StudioAudienceRule(
      id: 'aud_01',
      name: 'Tous les élèves Terminale Scientifique (C, D, TI)',
      classLevels: ['Terminale'],
      series: ['C', 'D', 'TI'],
      scopeType: 'global',
      accessTier: AccessTier.all,
      estimatedStudentReach: 1420,
    ),
    const StudioAudienceRule(
      id: 'aud_02',
      name: 'Abonnés Premium — Prépa Concours Polytechnique',
      classLevels: ['Terminale'],
      series: ['C', 'TI'],
      scopeType: 'global',
      accessTier: AccessTier.premiumOnly,
      estimatedStudentReach: 385,
    ),
    const StudioAudienceRule(
      id: 'aud_03',
      name: 'Établissement Pilote — Collège Vogt (Toutes classes)',
      classLevels: ['6eme', '5eme', '4eme', '3eme', 'Seconde', 'Premiere', 'Terminale'],
      scopeType: 'establishment',
      establishmentId: 'est_vogt_01',
      accessTier: AccessTier.all,
      estimatedStudentReach: 860,
    ),
  ]);
}

class AudiencesScreen extends ConsumerStatefulWidget {
  const AudiencesScreen({super.key});

  @override
  ConsumerState<AudiencesScreen> createState() => _AudiencesScreenState();
}

class _AudiencesScreenState extends ConsumerState<AudiencesScreen> {
  String testClassLevel = 'Terminale';
  String testSeries = 'C';
  bool testIsPremium = true;

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(audienceRulesProvider);

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
                    Text('Audiences & Règles de Diffusion', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Segmentation par niveau, série, établissement et statut d’abonnement.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nouvelle Règle d’Audience'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rules list
                Expanded(
                  flex: 3,
                  child: StudioDataTable<StudioAudienceRule>(
                    items: rules,
                    filterPredicate: (r, term) => r.name.toLowerCase().contains(term),
                    columns: [
                      StudioTableColumn(
                        header: 'Nom de la règle',
                        flex: 3,
                        cellBuilder: (r) => Text(
                          r.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      StudioTableColumn(
                        header: 'Périmètre',
                        flex: 1,
                        cellBuilder: (r) => StudioBadge(
                          label: r.scopeType.toUpperCase(),
                          variant: r.scopeType == 'global'
                              ? StudioBadgeVariant.info
                              : StudioBadgeVariant.warning,
                        ),
                      ),
                      StudioTableColumn(
                        header: 'Niveau d’accès',
                        flex: 1,
                        cellBuilder: (r) => Text(r.accessTier.name),
                      ),
                      StudioTableColumn(
                        header: 'Portée Estimée',
                        flex: 1,
                        cellBuilder: (r) => Text(
                          '${r.estimatedStudentReach} élèves',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Simulator
                Expanded(
                  flex: 2,
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
                          const Text(
                            'Simulateur d’Éligibilité Élève',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Divider(height: 24),
                          DropdownButtonFormField<String>(
                            initialValue: testClassLevel,
                            decoration: const InputDecoration(labelText: 'Classe test'),
                            items: const [
                              DropdownMenuItem(value: '3eme', child: Text('3ème')),
                              DropdownMenuItem(value: 'Premiere', child: Text('Première')),
                              DropdownMenuItem(value: 'Terminale', child: Text('Terminale')),
                            ],
                            onChanged: (val) => setState(() => testClassLevel = val ?? testClassLevel),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: testSeries,
                            decoration: const InputDecoration(labelText: 'Série test'),
                            items: const [
                              DropdownMenuItem(value: 'A', child: Text('Série A')),
                              DropdownMenuItem(value: 'C', child: Text('Série C')),
                              DropdownMenuItem(value: 'D', child: Text('Série D')),
                              DropdownMenuItem(value: 'TI', child: Text('Série TI')),
                            ],
                            onChanged: (val) => setState(() => testSeries = val ?? testSeries),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Statut Abonné Premium'),
                            value: testIsPremium,
                            onChanged: (val) => setState(() => testIsPremium = val),
                          ),
                          const Divider(height: 24),
                          const Text(
                            'Règles applicables pour ce profil :',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              children: [
                                for (final r in rules)
                                  if (r.matches(
                                    studentClassLevel: testClassLevel,
                                    studentSeries: testSeries,
                                    isPremium: testIsPremium,
                                  ))
                                    Card(
                                      elevation: 0,
                                      color: StudioColors.success.withValues(alpha: 0.08),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: StudioColors.success),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: StudioColors.success, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                r.name,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
