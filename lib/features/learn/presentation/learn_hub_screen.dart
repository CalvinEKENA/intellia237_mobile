import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../application/learn_providers.dart';
import '../domain/learn_subject.dart';

class LearnHubScreen extends ConsumerStatefulWidget {
  const LearnHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<LearnHubScreen> createState() => _LearnHubScreenState();
}

class _LearnHubScreenState extends ConsumerState<LearnHubScreen> {
  int _selectedFilter = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hubAsync = ref.watch(learnHubProvider);

    final content = hubAsync.when(
      loading: _LearnHubLoading.new,
      error: (error, stackTrace) =>
          _LearnHubError(onRetry: () => ref.invalidate(learnHubProvider)),
      data: (snapshot) => _LearnHubBody(
        classLabel: snapshot.context.label,
        subjects: snapshot.subjects,
        selectedFilter: _selectedFilter,
        searchQuery: _searchQuery,
        onFilterChanged: (i) => setState(() => _selectedFilter = i),
        searchCtrl: _searchCtrl,
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Apprendre',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: content,
    );
  }
}

class _LearnHubBody extends StatelessWidget {
  const _LearnHubBody({
    required this.classLabel,
    required this.subjects,
    required this.selectedFilter,
    required this.searchQuery,
    required this.onFilterChanged,
    required this.searchCtrl,
  });

  final String classLabel;
  final List<LearnSubject> subjects;
  final int selectedFilter;
  final String searchQuery;
  final ValueChanged<int> onFilterChanged;
  final TextEditingController searchCtrl;

  List<LearnSubject> get _filtered {
    var result = subjects;
    if (searchQuery.isNotEmpty) {
      result = result
          .where((s) => s.title.toLowerCase().contains(searchQuery))
          .toList();
    }
    return result;
  }

  List<String> get _currentFilters {
    final Map<String, String> examMapping = {
      'Terminale': 'Baccalauréat',
      'Première': 'Probatoire',
      'Troisième': 'BEPC',
    };
    final exam = examMapping[classLabel.split(' ').first] ?? classLabel;
    return ['Tout', exam];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final filters = _currentFilters;

    return CustomScrollView(
      slivers: [
        // ── Context banner ─────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: _ContextBanner(classLabel: classLabel),
          ),
        ),

        // ── Glass search bar ───────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: _GlassSearchBar(controller: searchCtrl),
          ),
        ),

        // ── Filter chips ───────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < filters.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: _FilterChip(
                        label: filters[i],
                        selected: i == selectedFilter,
                        onTap: () => onFilterChanged(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // ── Subject grid ───────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            132,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              mainAxisExtent: 160,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final subject = filtered[index];
                return _SubjectCard(subject: subject, index: index);
              },
              childCount: filtered.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Context banner
// ─────────────────────────────────────────────────────────────

class _ContextBanner extends StatelessWidget {
  const _ContextBanner({required this.classLabel});

  final String classLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x221451E1), Color(0x110B1F4A)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.brand.withValues(alpha: 0.30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parcours personnalisé',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Contenus adaptés à ton niveau actuel.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.40),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      classLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Glass search bar
// ─────────────────────────────────────────────────────────────

class _GlassSearchBar extends StatelessWidget {
  const _GlassSearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Rechercher une matière…',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 15,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.50),
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    onPressed: controller.clear,
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter chip
// ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.heroGold : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.18),
          ),
          boxShadow: selected
              ? AppShadows.glow(AppColors.gold, intensity: 0.20)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Subject card
// ─────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.index});

  final LearnSubject subject;
  final int index;

  @override
  Widget build(BuildContext context) {
    final gradient = AppGradients.forSubject(subject.iconKey);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.subjectDetail(subject.id)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          children: [
            // Gradient background
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),

            // Decorative circle
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          AppIcons.forSubject(subject.iconKey),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(subject.completion * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    subject.title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${subject.lessonsCount} leçon${subject.lessonsCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: subject.completion,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────
// Loading & error states
// ─────────────────────────────────────────────────────────────

class _LearnHubLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SkeletonBox(height: 140),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < 4; i++) ...[
          _SkeletonBox(height: 160),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.25, end: 0.55),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      },
    );
  }
}

class _LearnHubError extends StatelessWidget {
  const _LearnHubError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.40),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Impossible de charger les matières.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 14,
              ),
            ),
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
