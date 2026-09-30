import 'dart:developer' as developer;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/telemetry/startup_trace.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_skeleton.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../../../core/widgets/tab_section_header.dart';
import '../../content_engine/application/content_providers.dart';
import '../../content_engine/application/subject_journey.dart';
import '../../content_engine/presentation/subject_identity.dart';
import '../application/learn_providers.dart';
import '../application/subject_hall.dart';
import 'subject_hall_view.dart';
import 'widgets/learn_unavailable_state.dart';

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
    // Recherche réactive et locale : chaque frappe refiltre le Hall.
    _searchCtrl.addListener(() {
      if (_searchCtrl.text == _searchQuery) return;
      setState(() => _searchQuery = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ouvrir Apprendre lance la mise à jour des packs de la classe, en
    // arrière-plan, quel que soit l'état du catalogue : les contenus en
    // place restent affichés, les nouveaux apparaissent d'eux-mêmes.
    ref.listen(contentSyncControllerProvider, (_, _) {});

    // Une seule source : les parcours de la classe et le catalogue, réunis
    // en une matière par carte.
    final hallAsync = ref.watch(subjectHallProvider);
    if (hallAsync.valueOrNull?.isNotEmpty ?? false) {
      StartupTrace.mark(StartupMilestone.learnUsable);
    }

    final content = hallAsync.when(
      loading: _LearnHubLoading.new,
      error: (error, stackTrace) {
        // La cause reste dans les journaux ; l'élève voit un état humain.
        developer.log(
          'Learn hub unavailable.',
          name: 'intellia.learn',
          error: error.runtimeType.toString(),
        );
        return LearnUnavailableState(
          offline: stateKindForError(error) == IntelliaStateKind.offline,
          onRetry: () {
            ref.invalidate(learnHubProvider);
            ref.invalidate(subjectJourneysProvider);
          },
          onContinuePath: () => context.push(AppRoutes.flow),
        );
      },
      // Tirer pour actualiser : le catalogue et les packs de la classe.
      data: (_) => RefreshIndicator(
        key: const ValueKey('learn-refresh'),
        onRefresh: () async {
          await ref.read(contentSyncControllerProvider.notifier).refresh();
          ref.invalidate(learnHubProvider);
        },
        child: _LearnHubBody(
          classLabel:
              ref.watch(learnHubProvider).valueOrNull?.context.label ??
              ref.watch(studentAcademicContextProvider).valueOrNull?.label ??
              '',
          searchQuery: _searchQuery,
          searchCtrl: _searchCtrl,
        ),
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
          context.l10n.learnTitle,
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

/// Le Hall d'Apprendre : en-tête, bandeau de classe, recherche, puis une
/// carte par matière. Aucun chapitre ni séquence ici : ils vivent dans la
/// page de chaque matière.
class _LearnHubBody extends StatelessWidget {
  const _LearnHubBody({
    required this.classLabel,
    required this.searchQuery,
    required this.searchCtrl,
  });

  final String classLabel;
  final String searchQuery;
  final TextEditingController searchCtrl;

  /// Marge sous le Hall : la barre de navigation flottante ne masque
  /// jamais la dernière carte.
  static const bottomClearance = 132.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Un seul arrière-plan partagé pour tous les verres de l'écran : le
    // flou est calculé une fois, pas une fois par carte.
    return BackdropGroup(
      child: Stack(
        children: [
          const Positioned.fill(child: SubjectHallAuras()),
          CustomScrollView(
            slivers: [
              StickyTabSectionHeader(
                key: const ValueKey('learn-sticky-header'),
                eyebrow: l10n.studentSpaceEyebrow,
                title: l10n.learnTitle,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SubjectHallLayout.gutter,
                    IntelliaSpacing.sm,
                    SubjectHallLayout.gutter,
                    0,
                  ),
                  child: _ContextBanner(classLabel: classLabel),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SubjectHallLayout.gutter,
                    IntelliaSpacing.sm,
                    SubjectHallLayout.gutter,
                    0,
                  ),
                  child: _GlassSearchBar(controller: searchCtrl),
                ),
              ),
              const SliverToBoxAdapter(child: NewContentNotice()),
              const SliverToBoxAdapter(
                child: SizedBox(height: IntelliaSpacing.lg - 4),
              ),
              SliverToBoxAdapter(
                child: SubjectHall(
                  query: searchQuery,
                  onClearSearch: searchCtrl.clear,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      bottomClearance + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Context banner
// ─────────────────────────────────────────────────────────────

/// Bandeau de classe, compact : le Hall reste visible sans défiler.
class _ContextBanner extends StatelessWidget {
  const _ContextBanner({required this.classLabel});

  final String classLabel;

  @override
  Widget build(BuildContext context) {
    // Vrai gradient indigo→violet affirmé : texte blanc à contraste garanti.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: IntelliaSpacing.md,
        vertical: IntelliaSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: IntelliaGradients.brand,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        boxShadow: IntelliaShadows.glow(
          IntelliaColors.brandIndigo,
          intensity: 0.18,
        ),
      ),
      child: Wrap(
        spacing: IntelliaSpacing.sm,
        runSpacing: IntelliaSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.personalizedPath,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                context.l10n.levelAdaptedContent,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          if (classLabel.isNotEmpty)
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
                  const Icon(
                    Icons.school_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      classLabel,
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

  static const clearKey = ValueKey('learn-search-clear');

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final dark = learningBrightness(context) == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(IntelliaRadii.medium);
    final accent = dark ? const Color(0xFFB4B2FF) : IntelliaColors.brandIndigo;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: TextField(
          key: const ValueKey('learn-search-field'),
          controller: controller,
          textInputAction: TextInputAction.search,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: TextStyle(color: s.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: context.l10n.searchSubjectHint,
            hintStyle: TextStyle(color: s.textTertiary, fontSize: 15),
            filled: true,
            fillColor: dark ? const Color(0x99232736) : const Color(0xB8FFFFFF),
            prefixIcon: Icon(Icons.search_rounded, color: accent),
            // La croix apparaît avec le texte, sans décaler le champ.
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: value.text.isEmpty
                    ? const SizedBox(width: 48, height: 48)
                    : IconButton(
                        key: clearKey,
                        tooltip: context.l10n.clearSearch,
                        icon: Icon(Icons.close_rounded, color: s.textTertiary),
                        onPressed: controller.clear,
                      ),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: dark ? const Color(0x24FFFFFF) : const Color(0xE6FFFFFF),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: IntelliaSpacing.md,
              vertical: IntelliaSpacing.sm,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Loading & error states
// ─────────────────────────────────────────────────────────────

/// Chargement : le cadre de l'onglet s'affiche tout de suite (en-tête,
/// bandeau, emplacements des matières) ; seules les matières arrivent ensuite.
class _LearnHubLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      children: [
        const Positioned.fill(child: SubjectHallAuras()),
        CustomScrollView(
          key: const ValueKey('learn-hub-loading'),
          slivers: [
            StickyTabSectionHeader(
              key: const ValueKey('learn-sticky-header'),
              eyebrow: l10n.studentSpaceEyebrow,
              title: l10n.learnTitle,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                SubjectHallLayout.gutter,
                IntelliaSpacing.sm,
                SubjectHallLayout.gutter,
                _LearnHubBody.bottomClearance,
              ),
              sliver: SliverList.list(
                children: [
                  // Bandeau de classe et recherche, à leur taille réelle.
                  const IntelliaSkeletonBlock(height: 84, radius: 24),
                  const SizedBox(height: IntelliaSpacing.sm),
                  const IntelliaSkeletonBlock(height: 48, radius: 16),
                  const SizedBox(height: IntelliaSpacing.lg),
                  const IntelliaSkeletonBlock(
                    width: 150,
                    height: 22,
                    radius: 8,
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  // Les cartes du Hall : grille ou rail, comme le vrai Hall.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final layout = SubjectHallLayout.resolve(
                        constraints.maxWidth + 2 * SubjectHallLayout.gutter,
                        MediaQuery.textScalerOf(context).scale(1),
                      );
                      final card = IntelliaSkeletonBlock(
                        width: layout.cardWidth,
                        height: layout.minCardHeight,
                        radius: SubjectHallCard.radius,
                      );
                      final columns = layout.isRail ? 1 : layout.columns;
                      return Wrap(
                        key: const ValueKey('learn-hall-skeleton'),
                        spacing: SubjectHallLayout.gap,
                        runSpacing: SubjectHallLayout.gap,
                        children: [
                          for (
                            var i = 0;
                            i < (layout.isRail ? 1 : columns * 2);
                            i++
                          )
                            card,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
