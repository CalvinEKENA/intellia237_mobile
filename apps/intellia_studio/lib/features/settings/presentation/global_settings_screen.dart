import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';

class GlobalSettingsScreen extends ConsumerWidget {
  const GlobalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paramètres Généraux du Système', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text(
            'Configuration de l\'année académique, des quotas globaux et des modes opératoires.',
            style: TextStyle(color: StudioColors.textSecondaryLight),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                Card(
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
                        const Text('Année Scolaire & Calendrier Académique', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'Année scolaire courante',
                            helperText: 'Programme MINESEC Cameroun en vigueur',
                          ),
                          controller: null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Trimestre actif :'),
                            const SizedBox(width: 16),
                            DropdownButton<String>(
                              value: 'T3',
                              items: const [
                                DropdownMenuItem(value: 'T1', child: Text('1er Trimestre')),
                                DropdownMenuItem(value: 'T2', child: Text('2ème Trimestre')),
                                DropdownMenuItem(value: 'T3', child: Text('3ème Trimestre (Examens Bacc & BEPC)')),
                              ],
                              onChanged: (_) {},
                            ),
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
                        Text('Quotas Nominales Tuteur IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 12),
                        Text('TUTOR_DAILY_QUESTION_LIMIT par défaut : 20 questions / jour / élève'),
                        SizedBox(height: 6),
                        Text('Study Reserve Unit Standard : 600 000 unités par cycle de 30 jours'),
                      ],
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
