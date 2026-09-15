import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class NotebookLmScreen extends ConsumerStatefulWidget {
  const NotebookLmScreen({super.key});

  @override
  ConsumerState<NotebookLmScreen> createState() => _NotebookLmScreenState();
}

class _NotebookLmScreenState extends ConsumerState<NotebookLmScreen> {
  final notebookIdCtrl = TextEditingController(text: 'ntb_cameroun_bacc_2026');
  final docNameCtrl = TextEditingController(text: 'Epreuve_Math_Zero_2026.pdf');
  bool isAnalyzing = false;
  bool isExtracted = false;

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
                    Text('NotebookLM Import Center', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Ingestion de documents de cours, manuels officiels et génération de brouillons supervisés.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              const StudioBadge(
                label: 'PROVENANCE TRACKING ACTIF',
                variant: StudioBadgeVariant.info,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 420,
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
                            'Paramètres de la source',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Divider(height: 24),
                          TextField(
                            controller: notebookIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Identifiant NotebookLM / Projet',
                              prefixIcon: Icon(Icons.auto_awesome),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: docNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nom du document source',
                              prefixIcon: Icon(Icons.picture_as_pdf),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: StudioColors.goldAccent.withValues(alpha: 0.5),
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: StudioColors.goldAccent.withValues(alpha: 0.04),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 36, color: StudioColors.navyPrimary),
                                  SizedBox(height: 8),
                                  Text(
                                    'Déposez votre PDF ou scan de cours ici',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'PDF jusqu’à 14 MB (conforme quota serveur)',
                                    style: TextStyle(fontSize: 11, color: StudioColors.textSecondaryLight),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: isAnalyzing ? null : _simulateExtraction,
                              icon: isAnalyzing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.bolt_rounded),
                              label: Text(isAnalyzing ? 'Extraction Gemini en cours...' : 'Analyser avec Gemini'),
                            ),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Brouillons générés (Revue requise)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (isExtracted)
                                FilledButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Leçon et Quiz créés en statut Brouillon avec étiquette NotebookLM.'),
                                        backgroundColor: StudioColors.success,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.done_all_rounded),
                                  label: const Text('Transférer dans le Curriculum'),
                                ),
                            ],
                          ),
                          const Divider(height: 24),
                          Expanded(
                            child: !isExtracted
                                ? const Center(
                                    child: Text(
                                      'Lancez l’analyse pour prévisualiser la leçon et le QCM proposés.',
                                      style: TextStyle(color: StudioColors.textSecondaryLight),
                                    ),
                                  )
                                : ListView(
                                    children: [
                                      const ListTile(
                                        tileColor: StudioColors.backgroundLight,
                                        leading: Icon(Icons.menu_book, color: StudioColors.navyPrimary),
                                        title: Text('Brouillon de Leçon : Nombres Complexes et Géométrie'),
                                        subtitle: Text('3 blocs textuels • 1 formule clé • Est. 25 min'),
                                        trailing: StudioBadge(
                                          label: 'ORIGINE: NOTEBOOKLM',
                                          variant: StudioBadgeVariant.info,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const ListTile(
                                        tileColor: StudioColors.backgroundLight,
                                        leading: Icon(Icons.quiz, color: StudioColors.navyPrimary),
                                        title: Text('Banque QCM : 5 questions à choix multiple'),
                                        subtitle: Text('Solutions argumentées et indices d’apprentissage inclus'),
                                        trailing: StudioBadge(
                                          label: 'DIFFICULTÉ : MOYENNE',
                                          variant: StudioBadgeVariant.neutral,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const ListTile(
                                        tileColor: StudioColors.backgroundLight,
                                        leading: Icon(Icons.view_carousel, color: StudioColors.navyPrimary),
                                        title: Text('Carte FLOW candidate : Notion clé sur le module complexe'),
                                        subtitle: Text('Accroche brève pour révision mobile rapide'),
                                        trailing: StudioBadge(
                                          label: 'FLOW CANDIDAT',
                                          variant: StudioBadgeVariant.warning,
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

  void _simulateExtraction() {
    setState(() => isAnalyzing = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
          isExtracted = true;
        });
      }
    });
  }
}
