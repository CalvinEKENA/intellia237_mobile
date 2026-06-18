import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../application/admin_content_providers.dart';
import '../domain/admin_content_models.dart';
import 'content_chapter_screen.dart';
import 'content_quiz_editor_screen.dart';

/// Studio de Contenu — vue principale : sélecteur de classe + liste des matières
class ContentStudioScreen extends ConsumerStatefulWidget {
  const ContentStudioScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<ContentStudioScreen> createState() =>
      _ContentStudioScreenState();
}

class _ContentStudioScreenState extends ConsumerState<ContentStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedClass = ref.watch(selectedAdminClassProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            title: Text(
              'Studio de Contenu',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  // Class selector chips
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: kAllClassLevels.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (context, i) {
                        final cls = kAllClassLevels[i];
                        final active = cls == selectedClass;
                        return FilterChip(
                          label: Text(cls),
                          selected: active,
                          onSelected: (_) =>
                              ref
                                      .read(selectedAdminClassProvider.notifier)
                                      .state =
                                  cls,
                        );
                      },
                    ),
                  ),
                  // Tabs: Matières / Quiz
                  TabBar(
                    controller: _tabs,
                    tabs: const [
                      Tab(text: 'Matières & Cours'),
                      Tab(text: 'Quiz'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _SubjectsTab(classLevel: selectedClass),
            _QuizzesTab(classLevel: selectedClass),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Matières
// ─────────────────────────────────────────────────────────────────────────────

class _SubjectsTab extends ConsumerWidget {
  const _SubjectsTab({required this.classLevel});

  final String classLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(adminSubjectsProvider(classLevel));

    return subjectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(adminSubjectsProvider(classLevel)),
      ),
      data: (subjects) => RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(adminSubjectsProvider(classLevel)),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                120,
              ),
              sliver: subjects.isEmpty
                  ? SliverFillRemaining(
                      child: _EmptyState(
                        icon: Icons.auto_stories_outlined,
                        message:
                            'Aucune matière pour $classLevel.\nAjoutez-en une pour commencer.',
                      ),
                    )
                  : SliverList.separated(
                      itemCount: subjects.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) =>
                          _SubjectCard(subject: subjects[i])
                              .animate(delay: Duration(milliseconds: i * 50))
                              .fadeIn()
                              .slideY(begin: 0.1, end: 0),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends ConsumerWidget {
  const _SubjectCard({required this.subject});

  final AdminSubjectModel subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(subject.colorHex);
    final icon = kSubjectIconOptions[subject.iconKey] ?? Icons.book_rounded;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ContentChapterScreen(subject: subject),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Color badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _StatusChip(status: subject.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${subject.chapterCount} chapitre(s)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Quiz
// ─────────────────────────────────────────────────────────────────────────────

class _QuizzesTab extends ConsumerWidget {
  const _QuizzesTab({required this.classLevel});

  final String classLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(adminQuizzesProvider(classLevel));

    return quizzesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(adminQuizzesProvider(classLevel)),
      ),
      data: (quizzes) => Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminQuizzesProvider(classLevel)),
            child: quizzes.isEmpty
                ? const Center(
                    child: _EmptyState(
                      icon: Icons.quiz_outlined,
                      message: 'Aucun quiz pour ce niveau.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      120,
                    ),
                    itemCount: quizzes.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final quiz = quizzes[i];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.quiz_rounded,
                            color: quiz.isPublished
                                ? AppColors.accent
                                : AppColors.gold,
                          ),
                          title: Text(
                            quiz.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${quiz.questions.length} questions • ${quiz.difficultyLabel}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (quiz.aiGenerated)
                                const Tooltip(
                                  message: 'Généré par l\'IA',
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                    color: AppColors.gold,
                                  ),
                                ),
                              const SizedBox(width: 4),
                              _StatusChip(status: quiz.status),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ContentQuizEditorScreen(
                                classLevel: classLevel,
                                quiz: quiz,
                              ),
                            ),
                          ),
                        ),
                      ).animate(delay: Duration(milliseconds: i * 40)).fadeIn();
                    },
                  ),
          ),
          Positioned(
            bottom: AppSpacing.lg,
            right: AppSpacing.lg,
            child: FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ContentQuizEditorScreen(classLevel: classLevel),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau Quiz'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'published' => ('Publié', AppColors.accent),
      'ai_generated' => ('IA', AppColors.gold),
      _ => ('Brouillon', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
