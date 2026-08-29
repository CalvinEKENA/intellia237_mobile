import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_pressable.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../../../core/widgets/tab_section_header.dart';
import '../application/learn_providers.dart';
import '../domain/learn_subject.dart';
import 'subject_detail_screen.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';

class LearnHubScreen extends ConsumerStatefulWidget {
  const LearnHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<LearnHubScreen> createState() => _LearnHubScreenState();
}

class _LearnHubScreenState extends ConsumerState<LearnHubScreen> {
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
      error: (error, stackTrace) => IntelliaStateView(
        kind: stateKindForError(error),
        title: 'Impossible de charger les matières',
        message: stateMessageForKind(stateKindForError(error)),
        primaryLabel: 'Réessayer',
        onPrimary: () => ref.invalidate(learnHubProvider),
      ),
      data: (snapshot) => _LearnHubBody(
        classLabel: snapshot.context.label,
        subjects: snapshot.subjects,
        searchQuery: _searchQuery,
        searchCtrl: _searchCtrl,
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: const Color(0xFF060E22),
      // Univers sombre explicite : le contrat de surface suit l'écran.
      // (embedded : la palette claire vient du shell de l'accueil.)
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
      body: TabSurface(
        palette: const TabPalette(TabPresentationMode.standaloneDark),
        child: content,
      ),
    );
  }
}

class _LearnHubBody extends StatelessWidget {
  const _LearnHubBody({
    required this.classLabel,
    required this.subjects,
    required this.searchQuery,
    required this.searchCtrl,
  });

  final String classLabel;
  final List<LearnSubject> subjects;
  final String searchQuery;
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    // Hauteur de tuile adaptative : évite tout débordement à grand facteur
    // de texte (1.3 / 1.5).
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final tileExtent = 160 + (textScale - 1).clamp(0.0, 0.6) * 96;

    return CustomScrollView(
      slivers: [
        // ── En-tête commun clair ───────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              IntelliaSpacing.lg,
              IntelliaSpacing.lg,
              IntelliaSpacing.lg,
              IntelliaSpacing.md,
            ),
            child: TabSectionHeader(
              eyebrow: 'Espace élève',
              title: 'Apprendre',
              subtitle: 'Tes matières, adaptées à ton niveau.',
            ),
          ),
        ),
        // ── Context banner ─────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.lg,
              0,
              IntelliaSpacing.lg,
              0,
            ),
            child: _ContextBanner(classLabel: classLabel),
          ),
        ),

        // ── Glass search bar ───────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.lg,
              IntelliaSpacing.md,
              IntelliaSpacing.lg,
              0,
            ),
            child: _GlassSearchBar(controller: searchCtrl),
          ),
        ),

        // (Chips de filtre sans effet retirées : fausse affordance. Le
        // contexte de classe est déjà affiché dans le banner.)
        const SliverToBoxAdapter(child: SizedBox(height: IntelliaSpacing.md)),

        // ── Subject grid ───────────────────────────────────
        if (subjects.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                IntelliaSpacing.lg,
                IntelliaSpacing.md,
                IntelliaSpacing.lg,
                132,
              ),
              child: IntelliaStateView(
                kind: IntelliaStateKind.comingSoon,
                compact: true,
                title: 'Tes matières arrivent',
                message:
                    'Les cours de ta classe sont en cours de préparation. '
                    'Tu seras parmi les premiers à en profiter.',
              ),
            ),
          )
        else if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                IntelliaSpacing.lg,
                IntelliaSpacing.md,
                IntelliaSpacing.lg,
                132,
              ),
              child: IntelliaStateView(
                kind: IntelliaStateKind.noResults,
                compact: true,
                title: 'Aucune matière trouvée',
                message: 'Essaie un autre mot-clé.',
                primaryLabel: 'Effacer la recherche',
                onPrimary: searchCtrl.clear,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.lg,
              0,
              IntelliaSpacing.lg,
              132,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisSpacing: IntelliaSpacing.md,
                crossAxisSpacing: IntelliaSpacing.md,
                mainAxisExtent: tileExtent,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final subject = filtered[index];
                return _SubjectCard(subject: subject, index: index);
              }, childCount: filtered.length),
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
    // Vrai gradient indigo→violet affirmé : texte blanc à contraste garanti,
    // sans BackdropFilter (perf + lisibilité sur fond clair).
    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.lg),
      decoration: BoxDecoration(
        gradient: IntelliaGradients.brand,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        boxShadow: IntelliaShadows.glow(
          IntelliaColors.brandIndigo,
          intensity: 0.22,
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
          const SizedBox(height: IntelliaSpacing.xxs),
          Text(
            'Contenus adaptés à ton niveau actuel.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: IntelliaSpacing.sm,
              vertical: IntelliaSpacing.xxs + 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    classLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

// ─────────────────────────────────────────────────────────────
// Glass search bar
// ─────────────────────────────────────────────────────────────

class _GlassSearchBar extends StatelessWidget {
  const _GlassSearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return TextField(
      controller: controller,
      style: TextStyle(color: s.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Rechercher une matière…',
        hintStyle: TextStyle(color: s.textTertiary, fontSize: 15),
        filled: true,
        fillColor: s.fieldFill,
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: IntelliaColors.brandIndigo,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close_rounded, color: s.textTertiary),
                onPressed: controller.clear,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          borderSide: BorderSide(color: s.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          borderSide: const BorderSide(
            color: IntelliaColors.brandIndigo,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: IntelliaSpacing.md,
          vertical: IntelliaSpacing.sm,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter chip
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// Subject card
// ─────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.index});

  final LearnSubject subject;
  final int index;

  // Détail ouvert en route fondue (200 ms) lorsque les animations sont réduites.
  void _openFaded(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) =>
            SubjectDetailScreen(subjectId: subject.id, summary: subject),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = AppGradients.forSubject(subject.iconKey);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final tile = _SubjectTileVisual(subject: subject, gradient: gradient);

    // Container Transform : la tuile se transforme en écran Détail Matière.
    // Reduced motion : pas de morph, simple cross-fade 200 ms (même destination).
    final Widget interactive = reduceMotion
        ? IntelliaPressable(onTap: () => _openFaded(context), child: tile)
        : OpenContainer<void>(
            tappable: false,
            closedElevation: 0,
            closedColor: Colors.transparent,
            openColor: IntelliaColors.backgroundPrimary,
            middleColor: IntelliaColors.backgroundPrimary,
            closedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            ),
            // `fade` (et non fadeThrough) garde la source visible plus longtemps
            // → l'expansion spatiale du conteneur est nettement plus perceptible.
            transitionType: ContainerTransitionType.fade,
            transitionDuration: const Duration(milliseconds: 450),
            closedBuilder: (context, openContainer) =>
                IntelliaPressable(onTap: openContainer, child: tile),
            openBuilder: (context, _) =>
                SubjectDetailScreen(subjectId: subject.id, summary: subject),
          );

    final lessons =
        '${subject.lessonsCount} leçon${subject.lessonsCount > 1 ? 's' : ''}';
    return Semantics(
          button: true,
          label:
              '${subject.title}, '
              '${(subject.completion * 100).round()} % complété, $lessons',
          child: interactive,
        )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

/// Visuel de la tuile matière (sans logique de navigation) — sert de
/// `closedBuilder` au Container Transform et de fallback reduced-motion.
class _SubjectTileVisual extends StatelessWidget {
  const _SubjectTileVisual({required this.subject, required this.gradient});

  final LearnSubject subject;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
          ),
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
          Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
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
                const SizedBox(height: IntelliaSpacing.xxs),
                Text(
                  '${subject.lessonsCount} leçon${subject.lessonsCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.xs),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Loading & error states
// ─────────────────────────────────────────────────────────────

class _LearnHubLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(IntelliaSpacing.lg),
      children: [
        _SkeletonBox(height: 140),
        const SizedBox(height: IntelliaSpacing.md),
        for (int i = 0; i < 4; i++) ...[
          _SkeletonBox(height: 160),
          const SizedBox(height: IntelliaSpacing.md),
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
    final s = TabSurface.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.55, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: s.surfaceMuted,
              borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            ),
          ),
        );
      },
    );
  }
}
