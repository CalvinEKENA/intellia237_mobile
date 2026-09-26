import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/academic/academic_context_bar.dart';
import '../../../core/academic/academic_context_provider.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../domain/content_models.dart';

final selectedClassLevelProvider = StateProvider<String>((ref) => 'Terminale');

final subjectsProvider =
    StateNotifierProvider<SubjectsNotifier, List<StudioSubject>>((ref) {
      return SubjectsNotifier();
    });

class SubjectsNotifier extends StateNotifier<List<StudioSubject>> {
  SubjectsNotifier()
    : super([
        const StudioSubject(
          id: 'sub_math_t',
          classLevel: 'Terminale',
          title: 'Mathématiques',
          description: 'Analyse, Algèbre linéaire, Probabilités',
          colorHex: 0xFF1451E1,
          iconKey: 'calculate',
          order: 1,
          status: 'published',
          chapterCount: 8,
          allowedSeries: ['C', 'D', 'TI'],
        ),
        const StudioSubject(
          id: 'sub_phy_t',
          classLevel: 'Terminale',
          title: 'Physique-Chimie',
          description: 'Mécanique de Newton, Électromagnétisme, Cinétique',
          colorHex: 0xFF7C3AED,
          iconKey: 'science',
          order: 2,
          status: 'published',
          chapterCount: 6,
          allowedSeries: ['C', 'D', 'TI'],
        ),
        const StudioSubject(
          id: 'sub_philo_t',
          classLevel: 'Terminale',
          title: 'Philosophie',
          description: 'La conscience, L’art, L’État et la liberté',
          colorHex: 0xFFB45309,
          iconKey: 'lightbulb',
          order: 3,
          status: 'published',
          chapterCount: 5,
          allowedSeries: ['A', 'C', 'D', 'TI'],
        ),
        const StudioSubject(
          id: 'sub_info_t',
          classLevel: 'Terminale',
          title: 'Informatique',
          description: 'Algorithmique, Structures de données, Réseaux',
          colorHex: 0xFF059669,
          iconKey: 'computer',
          order: 4,
          status: 'draft',
          chapterCount: 4,
          allowedSeries: ['TI'],
        ),
      ]);

  void addSubject(StudioSubject subject) {
    state = [...state, subject];
  }
}

final chaptersProvider =
    StateNotifierProvider<ChaptersNotifier, List<StudioChapter>>((ref) {
      return ChaptersNotifier();
    });

class ChaptersNotifier extends StateNotifier<List<StudioChapter>> {
  ChaptersNotifier()
    : super([
        const StudioChapter(
          id: 'ch_01',
          subjectId: 'sub_math_t',
          classLevel: 'Terminale',
          title: 'Limites et Continuité',
          description: 'Théorème des valeurs intermédiaires, asymptotes',
          order: 1,
          lessonsCount: 4,
        ),
        const StudioChapter(
          id: 'ch_02',
          subjectId: 'sub_math_t',
          classLevel: 'Terminale',
          title: 'Dérivation et Convexité',
          description: 'Points d’inflexion, optimisation et extrema',
          order: 2,
          lessonsCount: 5,
        ),
        const StudioChapter(
          id: 'ch_03',
          subjectId: 'sub_math_t',
          classLevel: 'Terminale',
          title: 'Fonction Logarithme Népérien',
          description: 'Propriétés algébriques, dérivée, limites usuelles',
          order: 3,
          lessonsCount: 3,
        ),
        const StudioChapter(
          id: 'ch_04',
          subjectId: 'sub_math_t',
          classLevel: 'Terminale',
          title: 'Fonctions Exponentielles',
          description: 'Équations différentielles simples, croissance comparée',
          order: 4,
          lessonsCount: 4,
        ),
      ]);
}

class ContentStudioScreen extends ConsumerStatefulWidget {
  const ContentStudioScreen({super.key});

  @override
  ConsumerState<ContentStudioScreen> createState() =>
      _ContentStudioScreenState();
}

class _ContentStudioScreenState extends ConsumerState<ContentStudioScreen> {
  String? selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final academicContext = ref.watch(academicContextProvider);
    final allSubjects = ref.watch(subjectsProvider);
    final subjects = academicContext.showAllClasses
        ? allSubjects
        : (academicContext.selectedClass == null
              ? <StudioSubject>[]
              : allSubjects
                    .where(
                      (s) =>
                          s.classLevel.toLowerCase() ==
                              academicContext.selectedClass!.catalogKey
                                  .toLowerCase() ||
                          s.classLevel.toLowerCase() ==
                              academicContext.selectedClass!.id.toLowerCase(),
                    )
                    .toList());
    final allChapters = ref.watch(chaptersProvider);
    final chapters = selectedSubjectId == null
        ? <StudioChapter>[]
        : allChapters.where((c) => c.subjectId == selectedSubjectId).toList();

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
                      'Content Studio',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Programmes académiques officiels, matières, chapitres et hiérarchie pédagogique.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openAddSubjectDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nouvelle Matière'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AcademicContextBar(
            allowGlobalView: true,
            onContextChanged: () {
              setState(() => selectedSubjectId = null);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: StudioColors.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Matières (${academicContext.selectedClass?.label ?? "Toutes"})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              StudioBadge(
                                label: '${subjects.length} matières',
                                variant: StudioBadgeVariant.info,
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Expanded(
                            child: subjects.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Aucune matière pour ce niveau.',
                                      style: TextStyle(
                                        color: StudioColors.textSecondaryLight,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: subjects.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, idx) {
                                      final sub = subjects[idx];
                                      final isSelected =
                                          sub.id == selectedSubjectId;
                                      return ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? StudioColors.goldAccent
                                                : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        tileColor: isSelected
                                            ? StudioColors.goldAccent
                                                  .withValues(alpha: 0.08)
                                            : null,
                                        leading: CircleAvatar(
                                          backgroundColor: Color(
                                            sub.colorHex,
                                          ).withValues(alpha: 0.15),
                                          child: Icon(
                                            Icons.menu_book_rounded,
                                            color: Color(sub.colorHex),
                                          ),
                                        ),
                                        title: Text(
                                          sub.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${sub.chapterCount} chapitres • Séries: ${sub.allowedSeries.join(", ")}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: StudioBadge(
                                          label: sub.isPublished
                                              ? 'Publié'
                                              : 'Brouillon',
                                          variant: sub.isPublished
                                              ? StudioBadgeVariant.success
                                              : StudioBadgeVariant.warning,
                                        ),
                                        onTap: () {
                                          setState(
                                            () => selectedSubjectId = sub.id,
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: StudioColors.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedSubjectId == null
                                    ? 'Chapitres'
                                    : 'Chapitres — ${subjects.firstWhere((s) => s.id == selectedSubjectId, orElse: () => subjects.first).title}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (selectedSubjectId != null)
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Nouveau Chapitre'),
                                ),
                            ],
                          ),
                          const Divider(height: 24),
                          Expanded(
                            child: selectedSubjectId == null
                                ? const Center(
                                    child: Text(
                                      'Sélectionnez une matière à gauche pour explorer ses chapitres.',
                                      style: TextStyle(
                                        color: StudioColors.textSecondaryLight,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: chapters.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, idx) {
                                      final ch = chapters[idx];
                                      return ExpansionTile(
                                        leading: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: StudioColors
                                              .navyPrimary
                                              .withValues(alpha: 0.1),
                                          child: Text(
                                            '${ch.order}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: StudioColors.navyPrimary,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          ch.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${ch.lessonsCount} leçons • ${ch.description}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            child: Column(
                                              children: [
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.article_rounded,
                                                    size: 20,
                                                  ),
                                                  title: const Text(
                                                    'Leçon 1 : Définition formelle et théorèmes',
                                                  ),
                                                  subtitle: const Text(
                                                    'Durée estimée : 25 min • Publiée',
                                                  ),
                                                  trailing: FilledButton.tonal(
                                                    onPressed: () => context.go(
                                                      '/content/lesson/lsn_01',
                                                    ),
                                                    child: const Text('Éditer'),
                                                  ),
                                                ),
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.article_rounded,
                                                    size: 20,
                                                  ),
                                                  title: const Text(
                                                    'Leçon 2 : Exercices d’application et automatismes',
                                                  ),
                                                  subtitle: const Text(
                                                    'Durée estimée : 35 min • Publiée',
                                                  ),
                                                  trailing: FilledButton.tonal(
                                                    onPressed: () => context.go(
                                                      '/content/lesson/lsn_02',
                                                    ),
                                                    child: const Text('Éditer'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
    );
  }

  void _openAddSubjectDialog(BuildContext context) {
    final academicContext = ref.read(academicContextProvider);
    if (academicContext.selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez d\'abord sélectionner une classe dans la barre académique avant de créer une matière.',
          ),
          backgroundColor: StudioColors.warning,
        ),
      );
      return;
    }

    final targetClass = academicContext.selectedClass!;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nouvelle Matière (${targetClass.label})'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Système: ${academicContext.system.shortLabel} • Classe cible: ${targetClass.label}',
                style: const TextStyle(
                  fontSize: 12,
                  color: StudioColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titre de la matière (ex: Sciences de la Vie)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description synthétique',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                ref
                    .read(subjectsProvider.notifier)
                    .addSubject(
                      StudioSubject(
                        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                        classLevel: targetClass.catalogKey,
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        colorHex: 0xFF1451E1,
                        iconKey: 'book',
                        order: 5,
                        status: 'draft',
                        chapterCount: 0,
                        allowedSeries: targetClass.allowedSeries,
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
