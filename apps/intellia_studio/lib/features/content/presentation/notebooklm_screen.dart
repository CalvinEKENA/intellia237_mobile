import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/academic/academic_context_bar.dart';
import '../../../core/academic/academic_context_provider.dart';
import '../../../core/academic/academic_hierarchy.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

class NotebookLmScreen extends ConsumerStatefulWidget {
  const NotebookLmScreen({super.key});

  @override
  ConsumerState<NotebookLmScreen> createState() => _NotebookLmScreenState();
}

class _NotebookLmScreenState extends ConsumerState<NotebookLmScreen> {
  final storagePathCtrl = TextEditingController(
    text: 'educational_assets/global/terminale/mathematiques/cours_chapitre_1.png',
  );
  final subjectCtrl = TextEditingController(text: 'Mathématiques');
  String selectedClassLevel = 'terminale';

  bool isAnalyzing = false;
  String? errorMessage;
  Map<String, dynamic>? extractionResult;

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
                    Text(
                      'Import de Cours & Documents Structurés (importCoursePages)',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ingestion multimodale via Cloud Function (Gemini) : compatible exports NotebookLM et numérisations officielles.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              const StudioBadge(
                label: 'MULTIMODAL GEMINI PIPELINE',
                variant: StudioBadgeVariant.info,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AcademicContextBar(allowGlobalView: false),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 440,
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
                            'Paramètres d\'Ingestion Server-Side',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Divider(height: 24),
                          Builder(
                            builder: (context) {
                              final academicCtx = ref.watch(academicContextProvider);
                              final classes = AcademicHierarchy.classesForSystem(academicCtx.system);
                              return DropdownButtonFormField<String>(
                                value: academicCtx.selectedClass?.catalogKey,
                                decoration: const InputDecoration(
                                  labelText: 'Classe Cible (Canonique)',
                                  prefixIcon: Icon(Icons.school_rounded),
                                ),
                                hint: const Text('Choisir une classe'),
                                items: classes.map((cl) {
                                  return DropdownMenuItem(
                                    value: cl.catalogKey,
                                    child: Text('${cl.order}. ${cl.label}'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    ref.read(academicContextProvider.notifier).setClassByCatalogKey(val);
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              final academicCtx = ref.watch(academicContextProvider);
                              final allowedSeries = academicCtx.selectedClass?.allowedSeries ?? [];
                              if (allowedSeries.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: DropdownButtonFormField<String>(
                                  value: academicCtx.series,
                                  decoration: const InputDecoration(
                                    labelText: 'Série / Filière',
                                    prefixIcon: Icon(Icons.category_rounded),
                                  ),
                                  hint: const Text('Toutes séries ou choisir'),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('Tronc Commun / Toutes')),
                                    ...allowedSeries.map((s) => DropdownMenuItem(value: s, child: Text('Série $s'))),
                                  ],
                                  onChanged: (val) {
                                    ref.read(academicContextProvider.notifier).setSeries(val);
                                  },
                                ),
                              );
                            },
                          ),
                          TextField(
                            controller: subjectCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Discipline / Matière',
                              prefixIcon: Icon(Icons.book_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: storagePathCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Chemin Cloud Storage (educational_assets/...)',
                              prefixIcon: Icon(Icons.cloud_done_rounded),
                              hintText: 'educational_assets/{scope}/{class}/{subject}/...',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: StudioColors.goldAccent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: StudioColors.goldAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        size: 16, color: StudioColors.navyPrimary),
                                    SizedBox(width: 6),
                                    Text(
                                      'Contrat Multimodal Autoritaire',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: StudioColors.navyPrimary),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Les fichiers doivent résider dans le bucket sécurisé sous educational_assets/. Le callable analyse les pages en une passe avec Gemini 2.5 et synthétise leçon, quiz et cartes FLOW.',
                                  style: TextStyle(fontSize: 11, color: StudioColors.navyPrimary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: isAnalyzing ? null : _triggerRealImport,
                              icon: isAnalyzing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.bolt_rounded),
                              label: Text(isAnalyzing
                                  ? 'Appel Cloud Function en cours...'
                                  : 'Ingérer via importCoursePages'),
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
                                'Résultat de la Synthèse Multimodale',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (extractionResult != null)
                                const StudioBadge(
                                  label: 'SYNTHÈSE DISPONIBLE',
                                  variant: StudioBadgeVariant.success,
                                ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: StudioColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: StudioColors.error),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: StudioColors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: const TextStyle(
                                          color: StudioColors.error, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: extractionResult == null
                                ? const Center(
                                    child: Text(
                                      'Spécifiez le chemin d\'un actif dans Storage et lancez l\'ingestion pour obtenir la synthèse Gemini.',
                                      style: TextStyle(color: StudioColors.textSecondaryLight),
                                    ),
                                  )
                                : ListView(
                                    children: [
                                      ListTile(
                                        tileColor: StudioColors.backgroundLight,
                                        leading: const Icon(Icons.menu_book,
                                            color: StudioColors.navyPrimary),
                                        title: Text(
                                          extractionResult?['lessonTitle'] as String? ??
                                              'Brouillon de Leçon Généré',
                                        ),
                                        subtitle: Text(
                                          'Niveau: $selectedClassLevel • Matière: ${subjectCtrl.text}',
                                        ),
                                        trailing: const StudioBadge(
                                          label: 'LEÇON',
                                          variant: StudioBadgeVariant.info,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ListTile(
                                        tileColor: StudioColors.backgroundLight,
                                        leading: const Icon(Icons.quiz,
                                            color: StudioColors.navyPrimary),
                                        title: Text(
                                          'Questions QCM : ${(extractionResult?['quizzes'] as List?)?.length ?? 0} générée(s)',
                                        ),
                                        subtitle: const Text(
                                          'Solutions argumentées avec distracteurs canoniques',
                                        ),
                                        trailing: const StudioBadge(
                                          label: 'QUIZ',
                                          variant: StudioBadgeVariant.success,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ListTile(
                                        tileColor: StudioColors.backgroundLight,
                                        leading: const Icon(Icons.view_carousel,
                                            color: StudioColors.navyPrimary),
                                        title: Text(
                                          'Cartes FLOW : ${(extractionResult?['flowCards'] as List?)?.length ?? 0} candidate(s)',
                                        ),
                                        subtitle: const Text(
                                          'Micro-notions synthétisées pour l\'app mobile',
                                        ),
                                        trailing: const StudioBadge(
                                          label: 'FLOW',
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

  Future<void> _triggerRealImport() async {
    final academicCtx = ref.read(academicContextProvider);
    if (academicCtx.selectedClass == null) {
      setState(() {
        errorMessage = 'Veuillez d\'abord sélectionner une classe canonique cible avant de lancer l\'ingestion.';
      });
      return;
    }

    setState(() {
      isAnalyzing = true;
      errorMessage = null;
    });

    final controlPlane = ref.read(controlPlaneClientProvider);
    final path = storagePathCtrl.text.trim();

    try {
      final res = await controlPlane.importCoursePages(
        pages: [
          {'storagePath': path, 'pageNumber': 1}
        ],
        classLevel: academicCtx.selectedClass!.catalogKey,
        subjectId: subjectCtrl.text.trim(),
      );

      if (mounted) {
        setState(() {
          isAnalyzing = false;
          extractionResult = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
          errorMessage = 'Erreur lors de l\'ingestion Cloud Function : $e';
        });
      }
    }
  }
}
