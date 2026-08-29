import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../application/learn_providers.dart';
import '../domain/learn_chapter.dart';
import '../domain/learn_subject.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';

class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({required this.subjectId, this.summary, super.key});

  final String subjectId;

  /// Résumé déjà connu (passé par la tuile du hub) : permet d'afficher l'en-tête
  /// immersif (gradient + icône + titre) **immédiatement** pendant le Container
  /// Transform, sans spinner, le temps que les chapitres se chargent. Null pour
  /// l'accès direct par route (deep link) → spinner historique conservé.
  final LearnSubject? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectAsync = ref.watch(subjectDetailProvider(subjectId));
    final knownSummary = summary;

    return subjectAsync.when(
      loading: () => knownSummary != null
          ? _SubjectLoadingWithHeader(summary: knownSummary)
          : Scaffold(
              backgroundColor: IntelliaColors.backgroundPrimary,
              appBar: AppBar(backgroundColor: Colors.transparent),
              body: const IntelliaStateView(kind: IntelliaStateKind.loading),
            ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: IntelliaColors.backgroundPrimary,
        appBar: AppBar(title: const Text('Matière')),
        body: IntelliaStateView(
          kind: stateKindForError(error),
          title: 'Matière indisponible',
          message: stateMessageForKind(stateKindForError(error)),
          primaryLabel: 'Réessayer',
          onPrimary: () => ref.invalidate(subjectDetailProvider(subjectId)),
        ),
      ),
      data: (subject) => _SubjectDetailBody(subject: subject),
    );
  }
}

class _SubjectDetailBody extends StatelessWidget {
  const _SubjectDetailBody({required this.subject});

  final LearnSubjectDetail subject;

  @override
  Widget build(BuildContext context) {
    final gradient = AppGradients.forSubject(subject.iconKey);

    return Scaffold(
      backgroundColor: IntelliaColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // En-tête immersif (identique à celui montré pendant le morph).
          _SubjectImmersiveSliverAppBar(
            title: subject.title,
            iconKey: subject.iconKey,
            description: subject.description,
          ),

          // ── Chapters header ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                IntelliaSpacing.xl,
                IntelliaSpacing.lg,
                IntelliaSpacing.xl,
                IntelliaSpacing.sm,
              ),
              child: Text(
                'Chapitres',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: IntelliaColors.textPrimary,
                ),
              ),
            ),
          ),

          if (subject.chapters.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  IntelliaSpacing.xl,
                  0,
                  IntelliaSpacing.xl,
                  IntelliaSpacing.xxxl,
                ),
                child: IntelliaStateView(
                  kind: IntelliaStateKind.comingSoon,
                  compact: true,
                  title: 'Chapitres en préparation',
                  message:
                      'Le contenu de cette matière est en cours de '
                      'rédaction pour ta classe. Reviens bientôt !',
                ),
              ),
            ),
          // ── Chapters list ────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.xl,
              0,
              IntelliaSpacing.xl,
              IntelliaSpacing.xxxl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final chapter = subject.chapters[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
                  child: _ChapterCard(
                    subjectId: subject.id,
                    chapter: chapter,
                    subjectGradient: gradient,
                    index: index,
                  ),
                );
              }, childCount: subject.chapters.length),
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête immersif de la matière, réutilisé par l'écran chargé **et** par
/// l'état de chargement (depuis le résumé) → continuité visuelle du morph.
class _SubjectImmersiveSliverAppBar extends StatelessWidget {
  const _SubjectImmersiveSliverAppBar({
    required this.title,
    required this.iconKey,
    required this.description,
  });

  final String title;
  final String iconKey;
  final String description;

  @override
  Widget build(BuildContext context) {
    final gradient = AppGradients.forSubject(iconKey);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: gradient.colors.first,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
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
                  IntelliaSpacing.xxxl,
                  IntelliaSpacing.xl,
                  IntelliaSpacing.lg,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Icon(
                        AppIcons.forSubject(iconKey),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.sm),
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: IntelliaSpacing.xxs),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// État de chargement du détail montré pendant/après le morph : l'en-tête est
/// déjà visible (depuis le résumé), seuls les chapitres se chargent (squelette).
class _SubjectLoadingWithHeader extends StatelessWidget {
  const _SubjectLoadingWithHeader({required this.summary});

  final LearnSubject summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IntelliaColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          _SubjectImmersiveSliverAppBar(
            title: summary.title,
            iconKey: summary.iconKey,
            description: summary.description,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                IntelliaSpacing.xl,
                IntelliaSpacing.lg,
                IntelliaSpacing.xl,
                IntelliaSpacing.sm,
              ),
              child: Text(
                'Chapitres',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: IntelliaColors.textPrimary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.xl,
              0,
              IntelliaSpacing.xl,
              IntelliaSpacing.xxxl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: IntelliaSpacing.sm),
                  child: _ChapterSkeleton(),
                ),
                childCount: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterSkeleton extends StatelessWidget {
  const _ChapterSkeleton();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.25, end: 0.5),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: IntelliaColors.textPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          ),
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.subjectId,
    required this.chapter,
    required this.subjectGradient,
    required this.index,
  });

  final String subjectId;
  final LearnChapter chapter;
  final LinearGradient subjectGradient;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: () =>
              context.push(AppRoutes.chapterDetail(subjectId, chapter.id)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            child: DecoratedBox(
              decoration: const BoxDecoration(),
              child: Container(
                padding: const EdgeInsets.all(IntelliaSpacing.md),
                decoration: BoxDecoration(
                  color: IntelliaColors.surfaceSolid,
                  borderRadius: BorderRadius.circular(IntelliaRadii.medium),
                  border: Border.all(
                    color: IntelliaColors.brandIndigo.withValues(alpha: 0.10),
                  ),
                  boxShadow: IntelliaShadows.card(Colors.black),
                ),
                child: Row(
                  children: [
                    _ChapterArc(
                      progress: chapter.completion,
                      gradient: subjectGradient,
                      size: 44,
                    ),
                    const SizedBox(width: IntelliaSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter.title,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: IntelliaColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: IntelliaSpacing.xxs),
                          Text(
                            chapter.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: IntelliaColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: IntelliaSpacing.xs),
                          Text(
                            '${chapter.lessons.length} leçon${chapter.lessons.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: IntelliaColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(chapter.completion * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8A5300),
                          ),
                        ),
                        const SizedBox(height: IntelliaSpacing.xxs),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: IntelliaColors.textTertiary,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0);
  }
}

/// Circular arc progress indicator for chapter cards.
class _ChapterArc extends StatefulWidget {
  const _ChapterArc({
    required this.progress,
    required this.gradient,
    required this.size,
  });

  final double progress;
  final LinearGradient gradient;
  final double size;

  @override
  State<_ChapterArc> createState() => _ChapterArcState();
}

class _ChapterArcState extends State<_ChapterArc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _ChapterArcPainter(
          progress: widget.progress * _anim.value,
          gradient: widget.gradient,
        ),
        child: Center(
          child: Text(
            chapterCompletionLabel(widget.progress),
            style: const TextStyle(
              fontSize: 9,
              color: IntelliaColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

String chapterCompletionLabel(double p) {
  if (p >= 1.0) return '✓';
  if (p <= 0.0) return '—';
  return '${(p * 100).round()}%';
}

class _ChapterArcPainter extends CustomPainter {
  const _ChapterArcPainter({required this.progress, required this.gradient});

  final double progress;
  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 3.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = IntelliaColors.textPrimary.withValues(alpha: 0.10)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..shader = gradient.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height),
          )
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ChapterArcPainter old) => old.progress != progress;
}
