import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/network/network_status.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_pressable.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../application/learn_providers.dart';
import '../application/offline_learning_controller.dart';
import '../domain/learn_chapter.dart';
import '../domain/learn_lesson.dart';
import '../domain/learn_route_requests.dart';

/// Détail d'un chapitre — même famille claire que le hub Apprendre et le
/// détail matière : en-tête immersif teinté, liste de leçons tangibles,
/// prochaine action toujours identifiable (« À suivre »).
///
/// Registre de décisions : plus aucun écran Material générique au milieu du
/// parcours d'apprentissage.
class ChapterDetailScreen extends ConsumerWidget {
  const ChapterDetailScreen({
    required this.subjectId,
    required this.chapterId,
    super.key,
  });

  final String subjectId;
  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ChapterRequest(subjectId: subjectId, chapterId: chapterId);
    final chapterAsync = ref.watch(chapterDetailProvider(request));

    return TabSurface(
      palette: const TabPalette(TabPresentationMode.embeddedLight),
      child: Scaffold(
        backgroundColor: IntelliaColors.backgroundPrimary,
        body: chapterAsync.when(
          loading: () => const _ChapterLoading(),
          error: (error, stackTrace) => SafeArea(
            child: Column(
              children: [
                const _ChapterBackBar(title: 'Chapitre'),
                Expanded(
                  child: IntelliaStateView(
                    kind: stateKindForError(error),
                    title: 'Chapitre indisponible',
                    message: stateMessageForKind(stateKindForError(error)),
                    primaryLabel: 'Réessayer',
                    onPrimary: () =>
                        ref.invalidate(chapterDetailProvider(request)),
                  ),
                ),
              ],
            ),
          ),
          data: (chapter) => _ChapterBody(chapter: chapter),
        ),
      ),
    );
  }
}

class _ChapterBody extends StatelessWidget {
  const _ChapterBody({required this.chapter});

  final LearnChapter chapter;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final lessons = chapter.lessons;
    // Prochaine action : première leçon non terminée.
    final nextIndex = lessons.indexWhere((l) => l.progress < 1.0);

    return CustomScrollView(
      slivers: [
        // ── En-tête immersif clair, teinté par la marque ────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: IntelliaColors.brandIndigo,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: IntelliaGradients.brand),
                ),
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      IntelliaSpacing.xl,
                      IntelliaSpacing.xxl,
                      IntelliaSpacing.xl,
                      IntelliaSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CHAPITRE',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chapter.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        if (chapter.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            chapter.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.90),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Compteur de progression du chapitre ─────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.lg,
              IntelliaSpacing.lg,
              IntelliaSpacing.lg,
              IntelliaSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  'Leçons',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: s.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${lessons.where((l) => l.progress >= 1.0).length}'
                  '/${lessons.length} terminées',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: s.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.lg,
              0,
              IntelliaSpacing.lg,
              IntelliaSpacing.md,
            ),
            child: _OfflineChapterAction(chapter: chapter),
          ),
        ),

        // ── Leçons ──────────────────────────────────────────────────
        if (lessons.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(IntelliaSpacing.lg),
              child: IntelliaStateView(
                kind: IntelliaStateKind.comingSoon,
                compact: true,
                title: 'Leçons en préparation',
                message:
                    'Les leçons de ce chapitre sont en cours de rédaction. '
                    'Reviens bientôt !',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.lg,
              0,
              IntelliaSpacing.lg,
              IntelliaSpacing.xxxl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final lesson = lessons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
                  child: _LessonTile(
                    subjectId: chapter.subjectId,
                    chapterId: chapter.id,
                    lesson: lesson,
                    index: index,
                    isNext: index == nextIndex,
                  ),
                );
              }, childCount: lessons.length),
            ),
          ),
      ],
    );
  }
}

class _OfflineChapterAction extends ConsumerStatefulWidget {
  const _OfflineChapterAction({required this.chapter});

  final LearnChapter chapter;

  @override
  ConsumerState<_OfflineChapterAction> createState() =>
      _OfflineChapterActionState();
}

class _OfflineChapterActionState extends ConsumerState<_OfflineChapterAction> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final key = (
      subjectId: widget.chapter.subjectId,
      chapterId: widget.chapter.id,
    );
    final pack = ref.watch(offlineChapterPackProvider(key)).valueOrNull;
    final saved = pack != null;
    final offline = ref.watch(isOfflineProvider);
    final canSave = widget.chapter.lessons.isNotEmpty && !_busy;

    return Semantics(
      container: true,
      label: saved
          ? 'Chapitre enregistré pour la lecture hors connexion'
          : 'Enregistrer ce chapitre pour la lecture hors connexion',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        decoration: BoxDecoration(
          color: saved ? s.success.withValues(alpha: 0.10) : s.surface,
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          border: Border.all(
            color: saved ? s.success.withValues(alpha: 0.35) : s.border,
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _busy
                  ? SizedBox(
                      key: const ValueKey('busy'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: s.accent,
                      ),
                    )
                  : Icon(
                      saved
                          ? Icons.offline_pin_rounded
                          : Icons.download_for_offline_outlined,
                      key: ValueKey(saved),
                      color: saved ? s.success : s.accent,
                    ),
            ),
            const SizedBox(width: IntelliaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    saved ? 'Disponible hors connexion' : 'Étudier sans réseau',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: s.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    saved
                        ? '${pack.lessonIds.length} leçon(s) préparée(s) sur cet appareil.'
                        : offline
                        ? 'Reconnecte-toi pour préparer toutes les leçons.'
                        : 'Prépare les ${widget.chapter.lessons.length} leçon(s) de ce chapitre.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: s.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: IntelliaSpacing.xs),
            if (saved)
              IconButton(
                tooltip: 'Retirer de cet appareil',
                onPressed: _busy ? null : _remove,
                icon: const Icon(Icons.delete_outline_rounded),
              )
            else
              FilledButton.tonal(
                onPressed: canSave && !offline ? _save : null,
                child: const Text('Préparer'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(offlineLearningActionsProvider)
          .saveChapter(widget.chapter);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chapitre prêt pour une lecture hors connexion.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le téléchargement n’a pas abouti. Vérifie la connexion et réessaie.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(offlineLearningActionsProvider)
          .removeChapter(
            subjectId: widget.chapter.subjectId,
            chapterId: widget.chapter.id,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Barre de retour minimale pour les états sans en-tête immersif.
class _ChapterBackBar extends StatelessWidget {
  const _ChapterBackBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: IntelliaSpacing.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_rounded, color: s.iconPrimary),
          ),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: s.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterLoading extends StatelessWidget {
  const _ChapterLoading();

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChapterBackBar(title: 'Chapitre'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(IntelliaSpacing.lg),
              children: [
                for (var i = 0; i < 4; i++) ...[
                  Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: s.skeleton,
                      borderRadius: BorderRadius.circular(IntelliaRadii.large),
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends ConsumerWidget {
  const _LessonTile({
    required this.subjectId,
    required this.chapterId,
    required this.lesson,
    required this.index,
    required this.isNext,
  });

  final String subjectId;
  final String chapterId;
  final LearnLessonPreview lesson;
  final int index;
  final bool isNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = TabSurface.of(context);
    final completed = lesson.progress >= 1.0;
    final percent = (lesson.progress * 100).round();

    return Semantics(
      button: true,
      label:
          'Leçon ${index + 1} : ${lesson.title}, '
          '${completed ? 'terminée' : '$percent % complétée'}'
          '${isNext ? ', à suivre' : ''}',
      child:
          IntelliaPressable(
                onTap: () => context.push(
                  AppRoutes.lessonViewer(subjectId, chapterId, lesson.id),
                ),
                child: Container(
                  padding: const EdgeInsets.all(IntelliaSpacing.md),
                  decoration: BoxDecoration(
                    color: s.surface,
                    borderRadius: BorderRadius.circular(IntelliaRadii.large),
                    border: Border.all(
                      color: isNext
                          ? s.accent.withValues(alpha: 0.45)
                          : s.border,
                      width: isNext ? 1.4 : 1.0,
                    ),
                    boxShadow: IntelliaShadows.card(Colors.black),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Numéro / état de la leçon.
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: completed
                              ? s.success.withValues(alpha: 0.14)
                              : s.accentSoft,
                          borderRadius: BorderRadius.circular(
                            IntelliaRadii.small,
                          ),
                        ),
                        child: Center(
                          child: completed
                              ? Icon(
                                  Icons.check_rounded,
                                  color: s.success,
                                  size: 22,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: s.accent,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: IntelliaSpacing.md),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lesson.title,
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: s.textPrimary,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                if (isNext)
                                  Container(
                                    margin: const EdgeInsets.only(
                                      left: IntelliaSpacing.xs,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: IntelliaSpacing.xs,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: s.accentSoft,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      'À suivre',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: s.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (lesson.summary.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                lesson.summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: s.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: IntelliaSpacing.xs),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 14,
                                  color: s.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${lesson.estimatedMinutes} min',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: s.textTertiary,
                                  ),
                                ),
                                const SizedBox(width: IntelliaSpacing.sm),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: lesson.progress,
                                      minHeight: 5,
                                      backgroundColor: s.surfaceMuted,
                                      color: completed ? s.success : s.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Favori — cible tactile 48dp.
                      Semantics(
                        button: true,
                        label: lesson.isFavorite
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                        child: IconButton(
                          onPressed: () => ref
                              .read(learnActionsProvider)
                              .toggleFavorite(
                                subjectId: subjectId,
                                chapterId: chapterId,
                                lessonId: lesson.id,
                              ),
                          icon: Icon(
                            lesson.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: lesson.isFavorite
                                ? const Color(0xFFE0426B)
                                : s.iconSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(delay: Duration(milliseconds: 40 + index * 50))
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.04, end: 0),
    );
  }
}
