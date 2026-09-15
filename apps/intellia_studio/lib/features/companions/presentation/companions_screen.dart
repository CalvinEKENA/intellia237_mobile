import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class CompanionsScreen extends ConsumerStatefulWidget {
  const CompanionsScreen({super.key});

  @override
  ConsumerState<CompanionsScreen> createState() => _CompanionsScreenState();
}

class _CompanionsScreenState extends ConsumerState<CompanionsScreen> {
  String _selectedCompanion = 'kira';

  @override
  Widget build(BuildContext context) {
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
                    Text('Opérations Compagnons IA (Kira & Léo)', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Configuration des prompts système, garde-fous pédagogiques et télémétrie des tuteurs.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'kira', label: Text('Kira (Tuteur Académique)')),
                  ButtonSegment(value: 'leo', label: Text('Léo (Orientation)')),
                ],
                selected: {_selectedCompanion},
                onSelectionChanged: (val) => setState(() => _selectedCompanion = val.first),
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
                                    ? 'Prompt Système — Kira v3.2 (Production)'
                                    : 'Prompt Système — Léo v2.1 (Production)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const StudioBadge(label: 'ACTIF SUR MOBILE', variant: StudioBadgeVariant.success),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: StudioColors.surfaceDark.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: StudioColors.borderLight),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  _selectedCompanion == 'kira'
                                      ? 'Tu es Kira, la compagne d\'étude bienveillante et rigoureuse d\'INTELLIA 237.\n'
                                        'Ton rôle est d\'aider les élèves camerounais (de la 6ème à la Terminale) à comprendre leurs cours.\n\n'
                                        'RÈGLES INVIOLABLES :\n'
                                        '1. Ne donne JAMAIS directement la réponse brute d\'un devoir. Guide pas-à-pas avec méthode socratique.\n'
                                        '2. Utilise le programme officiel du MINESEC Cameroun.\n'
                                        '3. Reste encourageante, respectueuse et concise.'
                                      : 'Tu es Léo, le guide d\'orientation professionnelle et universitaire d\'INTELLIA 237.\n'
                                        'Ton rôle est d\'orienter les élèves camerounais vers les filières adaptées à leurs compétences (Polytechnique, ENSP, FMSB, ENS, filières techniques et littéraires).\n\n'
                                        'RÈGLES :\n'
                                        '1. Présente les débouchés réels au Cameroun et en Afrique centrale.\n'
                                        '2. Détaille les concours nationaux et les conditions d\'admission.',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
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
                          side: const BorderSide(color: StudioColors.borderLight),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Paramètres Modèle Gemini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Modèle sous-jacent :'),
                                  Text('gemini-1.5-flash', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Température :'),
                                  Text('0.2 (Faible hallucination)', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Filtres de sécurité :'),
                                  StudioBadge(label: 'STRICT', variant: StudioBadgeVariant.info),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
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
                              Text('Télémétrie & Quotas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              SizedBox(height: 12),
                              Text('Questions traitées aujourd\'hui : 14 280'),
                              SizedBox(height: 6),
                              Text('Temps moyen de réponse : 820 ms'),
                              SizedBox(height: 6),
                              Text('Taux de satisfaction tuteur : 98.4%'),
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
}
