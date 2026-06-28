import 'dart:math' as math;
import 'dart:ui';

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
              backgroundColor: const Color(0xFF060E22),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Matière')),
        body: Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(subjectDetailProvider(subjectId)),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Recharger'),
          ),
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
      backgroundColor: const Color(0xFF060E22),
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
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Text(
                'Chapitres',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // ── Chapters list ────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final chapter = subject.chapters[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                  AppSpacing.xl,
                  AppSpacing.xxxl,
                  AppSpacing.xl,
                  AppSpacing.lg,
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
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
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
      backgroundColor: const Color(0xFF060E22),
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
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Text(
                'Chapitres',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
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
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
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
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x18FFFFFF), Color(0x0CFFFFFF)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    _ChapterArc(
                      progress: chapter.completion,
                      gradient: subjectGradient,
                      size: 44,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter.title,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            chapter.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${chapter.lessons.length} leçon${chapter.lessons.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.40),
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
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: 0.35),
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
              color: Colors.white,
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
        ..color = Colors.white.withValues(alpha: 0.15)
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
