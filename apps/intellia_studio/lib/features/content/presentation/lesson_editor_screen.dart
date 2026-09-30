import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/academic/academic_context_provider.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../domain/content_models.dart';

class LessonEditorScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonEditorScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends ConsumerState<LessonEditorScreen> {
  late TextEditingController titleCtrl;
  late TextEditingController summaryCtrl;
  late TextEditingController durationCtrl;
  String currentStatus = 'published';

  List<StudioContentBlock> blocks = [
    const StudioContentBlock(
      id: 'blk_01',
      type: ContentBlockType.text,
      title: 'Introduction et objectifs',
      body:
          'Dans cette leçon, nous aborderons la notion fondamentale de continuité sur un intervalle.',
    ),
    const StudioContentBlock(
      id: 'blk_02',
      type: ContentBlockType.callout,
      title: 'Théorème clé (TVI)',
      body:
          'Si f est continue sur [a, b] et k compris entre f(a) et f(b), alors il existe c in [a, b] tel que f(c) = k.',
    ),
    const StudioContentBlock(
      id: 'blk_03',
      type: ContentBlockType.text,
      title: 'Exemple d’application guidée',
      body:
          'Montrons que l’équation x^3 + x - 1 = 0 admet au moins une solution réelle dans ]0, 1[.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(
      text: 'Théorème des Valeurs Intermédiaires (TVI)',
    );
    summaryCtrl = TextEditingController(
      text: 'Énoncé, interprétation graphique et méthode de dichotomie.',
    );
    durationCtrl = TextEditingController(text: '30');
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    summaryCtrl.dispose();
    durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/content'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Retour au Content Studio',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Éditeur de Leçon',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(width: 12),
                          StudioBadge(
                            label: currentStatus.toUpperCase(),
                            variant: currentStatus == 'published'
                                ? StudioBadgeVariant.success
                                : StudioBadgeVariant.warning,
                          ),
                          const SizedBox(width: 8),
                          const StudioBadge(
                            label: 'ORIGINE: MANUEL (V2 DUAL-WRITE)',
                            variant: StudioBadgeVariant.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.lessonId} • ${ref.watch(academicContextProvider).fullTargetDescription}',
                        style: const TextStyle(
                          color: StudioColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Brouillon enregistré en local.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer Brouillon'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _publishLesson(context),
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text('Publier la Leçon'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 380,
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
                              'Métadonnées de la leçon',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Divider(height: 24),
                            TextField(
                              controller: titleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Titre officiel',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: summaryCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Résumé pédagogique',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: durationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Durée estimée (minutes)',
                                suffixText: 'min',
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Périmètre d’accès',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Accès : Tous les élèves inscrits au niveau Terminale.',
                              style: TextStyle(
                                fontSize: 12,
                                color: StudioColors.textSecondaryLight,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: StudioColors.navyPrimary.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.security_rounded,
                                    size: 20,
                                    color: StudioColors.navyPrimary,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Dual-write actif : projection automatique vers V1 pour compatibilité mobile.',
                                      style: TextStyle(fontSize: 11),
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
                                Text(
                                  'Blocs de contenu (${blocks.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _addBlock(ContentBlockType.text),
                                      icon: const Icon(
                                        Icons.text_fields_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Texte'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _addBlock(ContentBlockType.callout),
                                      icon: const Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Encadré'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _addBlock(ContentBlockType.video),
                                      icon: const Icon(
                                        Icons.video_library_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Média'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Expanded(
                              child: ListView.separated(
                                itemCount: blocks.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  final blk = blocks[idx];
                                  return Card(
                                    elevation: 0,
                                    color: blk.type == ContentBlockType.callout
                                        ? StudioColors.goldAccent.withValues(
                                            alpha: 0.08,
                                          )
                                        : StudioColors.backgroundLight,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(
                                        color: StudioColors.borderLight,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    blk.type ==
                                                            ContentBlockType
                                                                .callout
                                                        ? Icons
                                                              .lightbulb_rounded
                                                        : Icons
                                                              .article_outlined,
                                                    size: 18,
                                                    color: StudioColors
                                                        .navyPrimary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    blk.title,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setState(
                                                    () => blocks.removeAt(idx),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                ),
                                                color: StudioColors.error,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(blk.body),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
      ),
    );
  }

  void _addBlock(ContentBlockType type) {
    setState(() {
      blocks.add(
        StudioContentBlock(
          id: 'blk_${DateTime.now().millisecondsSinceEpoch}',
          type: type,
          title: type == ContentBlockType.callout
              ? 'Formule importante'
              : 'Nouveau paragraphe',
          body: 'Contenu rédigé par l’enseignant ou l’administrateur.',
        ),
      );
    });
  }

  void _publishLesson(BuildContext context) {
    final academicCtx = ref.read(academicContextProvider);
    if (!academicCtx.isPublicationReady) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cible Académique Incomplète'),
          content: Text(
            'Publication impossible : une leçon officielle ne peut pas être publiée sans classe et matière valides.\n\n'
            'Cible actuelle : ${academicCtx.fullTargetDescription}.\n\n'
            'Veuillez définir une classe et une matière dans la barre de contexte Studio.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => currentStatus = 'published');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Leçon publiée pour ${academicCtx.fullTargetDescription}.',
        ),
        backgroundColor: StudioColors.success,
      ),
    );
  }
}
