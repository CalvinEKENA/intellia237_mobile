import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_pressable.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../content_engine/application/content_providers.dart';
import '../../content_engine/presentation/content_style.dart';
import '../../content_engine/presentation/content_subject_screen.dart';
import '../../content_engine/presentation/learning_cards.dart';
import '../../content_engine/presentation/subject_identity.dart';
import '../application/subject_hall.dart';
import 'subject_detail_screen.dart';

/// Nom d'une matière du Hall tel que l'élève le lit (« Anglais » pour un
/// pack « English »).
String subjectHallName(BuildContext context, LearnSubjectOverview subject) =>
    subjectDisplayName(context, subject.key, subject.title);

/// Disposition du Hall pour une largeur et un facteur de texte donnés.
@immutable
class SubjectHallLayout {
  const SubjectHallLayout._({
    required this.columns,
    required this.cardWidth,
    required this.contentWidth,
  });

  /// Marge latérale, identique au reste d'Apprendre.
  static const gutter = IntelliaSpacing.md;
  static const gap = IntelliaSpacing.sm;

  /// Largeur minimale d'une carte à texte nominal : en dessous, deux
  /// colonnes deviendraient illisibles et le Hall passe en rail.
  static const minCardWidth = 150.0;

  /// Au-delà, une carte n'est plus une carte mais une bannière.
  static const maxCardWidth = 260.0;

  /// Ratio largeur / hauteur minimale des cartes (grille et rail).
  static const aspectRatio = 1.08;

  /// Part de la largeur occupée par une carte du rail : la suivante
  /// dépasse, pour inviter à faire défiler.
  static const railFraction = 0.74;

  /// 0 : rail horizontal. Sinon, nombre de colonnes de la grille.
  final int columns;
  final double cardWidth;

  /// Largeur utile, centrée sur tablette.
  final double contentWidth;

  bool get isRail => columns == 0;

  double get minCardHeight => cardWidth / aspectRatio;

  static SubjectHallLayout resolve(double width, double textScale) {
    final available = math.max(0.0, width - 2 * gutter);
    final minWidth = minCardWidth * math.max(1.0, textScale);
    final fit = ((available + gap) / (minWidth + gap)).floor();
    if (fit < 2) {
      return SubjectHallLayout._(
        columns: 0,
        cardWidth: math.min(width * railFraction, maxCardWidth + 40),
        contentWidth: available,
      );
    }
    final columns = math.min(fit, 3);
    final content = math.min(
      available,
      columns * maxCardWidth + (columns - 1) * gap,
    );
    return SubjectHallLayout._(
      columns: columns,
      cardWidth: (content - gap * (columns - 1)) / columns,
      contentWidth: content,
    );
  }
}

/// Le Hall d'Apprendre : une carte vitrée par matière, rien d'autre.
///
/// La recherche filtre cette seule liste (catalogue et parcours réunis) :
/// aucune matière ne peut y échapper ni apparaître deux fois.
class SubjectHall extends ConsumerWidget {
  const SubjectHall({this.query = '', this.onClearSearch, super.key});

  static const hallKey = ValueKey('subject-hall');
  static const gridKey = ValueKey('subject-hall-grid');
  static const railKey = ValueKey('subject-hall-rail');

  final String query;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hall = ref.watch(subjectHallProvider).valueOrNull;
    if (hall == null) return const SizedBox.shrink();
    final palette = _HallPalette.of(context);

    if (hall.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: IntelliaSpacing.md),
        child: IntelliaStateView(
          kind: IntelliaStateKind.comingSoon,
          compact: true,
          title: l10n.subjectsComingTitle,
          message: l10n.subjectsComingBody,
        ),
      );
    }

    final matches = SubjectHallSearch.filter(
      hall,
      query,
      nameOf: (subject) => subjectHallName(context, subject),
    );
    final searching = query.trim().isNotEmpty;

    return Column(
      key: hallKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SubjectHallLayout.gutter,
          ),
          child: Semantics(
            header: true,
            child: Text(
              l10n.learnHallTitle,
              style: ContentText.title(color: palette.text, size: 21),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SubjectHallLayout.gutter,
          ),
          child: Text(
            l10n.learnHallSubtitle,
            style: ContentText.body(color: palette.textSoft, size: 13),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        // Annonce du nombre de résultats aux lecteurs d'écran.
        if (searching)
          Semantics(
            liveRegion: true,
            label: l10n.learnHallResults(matches.length),
            child: const SizedBox.shrink(),
          ),
        if (matches.isEmpty)
          Padding(
            key: const ValueKey('subject-hall-empty'),
            padding: const EdgeInsets.symmetric(
              horizontal: SubjectHallLayout.gutter,
            ),
            child: IntelliaStateView(
              kind: IntelliaStateKind.noResults,
              compact: true,
              title: l10n.noSubjectFound,
              message: l10n.tryAnotherKeyword,
              primaryLabel: l10n.clearSearch,
              onPrimary: onClearSearch,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final layout = SubjectHallLayout.resolve(
                constraints.maxWidth,
                MediaQuery.textScalerOf(context).scale(1),
              );
              return layout.isRail
                  ? _SubjectRail(matches: matches, layout: layout)
                  : _SubjectGrid(matches: matches, layout: layout);
            },
          ),
      ],
    );
  }
}

/// Deux (ou trois) colonnes ; dans une rangée, les cartes prennent la
/// hauteur de la plus haute : aucun texte n'est jamais coupé.
class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid({required this.matches, required this.layout});

  final List<SubjectHallMatch> matches;
  final SubjectHallLayout layout;

  @override
  Widget build(BuildContext context) {
    final columns = layout.columns;
    final rows = <Widget>[];
    for (var start = 0; start < matches.length; start += columns) {
      if (start > 0) rows.add(const SizedBox(height: SubjectHallLayout.gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = start; i < start + columns; i++) ...[
                if (i > start) const SizedBox(width: SubjectHallLayout.gap),
                Expanded(
                  child: i < matches.length
                      ? ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: layout.minCardHeight,
                          ),
                          child: SubjectHallCard(match: matches[i]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Center(
      key: SubjectHall.gridKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SubjectHallLayout.gutter,
        ),
        child: SizedBox(
          width: layout.contentWidth,
          child: Column(children: rows),
        ),
      ),
    );
  }
}

/// Très petit écran ou grand texte : un rail horizontal, carte par carte,
/// jamais une colonne administrative.
class _SubjectRail extends StatelessWidget {
  const _SubjectRail({required this.matches, required this.layout});

  final List<SubjectHallMatch> matches;
  final SubjectHallLayout layout;

  @override
  Widget build(BuildContext context) {
    final width = layout.cardWidth;
    return SingleChildScrollView(
      key: SubjectHall.railKey,
      scrollDirection: Axis.horizontal,
      physics: _SnapToCardPhysics(extent: width + SubjectHallLayout.gap),
      padding: const EdgeInsets.symmetric(horizontal: SubjectHallLayout.gutter),
      // Ombres des cartes : jamais rognées par le rail.
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, match) in matches.indexed) ...[
              if (index > 0) const SizedBox(width: SubjectHallLayout.gap),
              SizedBox(
                width: width,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: layout.minCardHeight),
                  child: SubjectHallCard(match: match),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Le rail s'arrête toujours sur une carte, alignée sur la marge.
class _SnapToCardPhysics extends ScrollPhysics {
  const _SnapToCardPhysics({required this.extent, super.parent});

  final double extent;

  @override
  _SnapToCardPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapToCardPhysics(extent: extent, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    var card = position.pixels / extent;
    if (velocity < -tolerance.velocity) {
      card -= 0.5;
    } else if (velocity > tolerance.velocity) {
      card += 0.5;
    }
    final target = (card.roundToDouble() * extent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// Couleurs du verre, selon la luminosité de l'onglet.
@immutable
class _HallPalette {
  const _HallPalette({
    required this.dark,
    required this.text,
    required this.textSoft,
    required this.glassTop,
    required this.glassBottom,
    required this.border,
    required this.highlight,
    required this.shadow,
  });

  factory _HallPalette.of(BuildContext context) =>
      _HallPalette.forBrightness(learningBrightness(context));

  factory _HallPalette.forBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return dark
        ? const _HallPalette(
            dark: true,
            text: Color(0xFFF5F5F7),
            textSoft: Color(0xFFB9BCC8),
            glassTop: Color(0xB8262A38),
            glassBottom: Color(0x9E1A1D28),
            border: Color(0x24FFFFFF),
            highlight: Color(0x1FFFFFFF),
            shadow: Color(0x52000000),
          )
        : const _HallPalette(
            dark: false,
            text: Color(0xFF111827),
            textSoft: Color(0xFF4B5466),
            glassTop: Color(0xD9FFFFFF),
            glassBottom: Color(0xB8FFFFFF),
            border: Color(0xB3FFFFFF),
            highlight: Color(0x99FFFFFF),
            shadow: Color(0x1A2B2F77),
          );
  }

  final bool dark;
  final Color text;
  final Color textSoft;
  final Color glassTop;
  final Color glassBottom;
  final Color border;
  final Color highlight;
  final Color shadow;
}

/// Une matière du Hall : verre dépoli, accent de la matière, progression.
///
/// Statique au repos (aucune boucle d'animation) ; l'appui réduit la carte
/// (0,98) avec un retour haptique, puis la carte s'ouvre en page matière.
class SubjectHallCard extends StatelessWidget {
  const SubjectHallCard({required this.match, super.key});

  static const radius = 24.0;

  final SubjectHallMatch match;

  LearnSubjectOverview get subject => match.subject;

  Widget _destination() {
    final catalogue = subject.catalogue;
    if (subject.opensContentEngine || catalogue == null) {
      return ContentSubjectScreen(subjectKey: subject.key);
    }
    return SubjectDetailScreen(subjectId: catalogue.id, summary: catalogue);
  }

  // Animations réduites : pas de morph, un fondu de 200 ms, même page.
  void _openFaded(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => _destination(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = subjectHallName(context, subject);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    // La luminosité est lue ici, dans l'onglet : pendant la transformation,
    // la carte est reconstruite hors de l'onglet et doit rester identique.
    final visual = ExcludeSemantics(
      child: _SubjectHallCardVisual(
        match: match,
        name: name,
        brightness: learningBrightness(context),
      ),
    );
    final destinationBackground = learningBackground(
      learningBrightness(context),
    );

    final Widget interactive = reduceMotion
        ? IntelliaPressable(
            onTap: () => _openFaded(context),
            scaleFactor: 0.98,
            child: visual,
          )
        : OpenContainer<void>(
            tappable: false,
            closedElevation: 0,
            openElevation: 0,
            closedColor: Colors.transparent,
            openColor: destinationBackground,
            middleColor: destinationBackground,
            closedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            transitionType: ContainerTransitionType.fade,
            transitionDuration: const Duration(milliseconds: 420),
            closedBuilder: (context, open) => IntelliaPressable(
              onTap: open,
              scaleFactor: 0.98,
              child: visual,
            ),
            openBuilder: (context, _) => _destination(),
          );

    // Un seul nœud annoncé : nom, progression, leçons ; l'appui (de la
    // carte) reste l'action du nœud.
    return Semantics(
      key: ValueKey('subject-card-${subject.key}'),
      container: true,
      button: true,
      label: [
        l10n.subjectTileA11y(
          name,
          subject.percent,
          l10n.lessonCount(subject.lessonCount),
        ),
        if (match.context case final found?) l10n.learnHallFoundIn(found),
      ].join(', '),
      child: interactive,
    );
  }
}

class _SubjectHallCardVisual extends StatelessWidget {
  const _SubjectHallCardVisual({
    required this.match,
    required this.name,
    required this.brightness,
  });

  final SubjectHallMatch match;
  final String name;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subject = match.subject;
    final glass = _HallPalette.forBrightness(brightness);
    final identity = SubjectVisualIdentity.of(subject.key);
    final palette = identity.palette(brightness);
    final radius = BorderRadius.circular(SubjectHallCard.radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: glass.shadow,
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter.grouped(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [glass.glassTop, glass.glassBottom],
              ),
              border: Border.all(color: glass.border),
            ),
            child: Stack(
              children: [
                // Halo de la matière, en haut à droite.
                Positioned(
                  top: -60,
                  right: -50,
                  width: 170,
                  height: 170,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            palette.accent.withValues(
                              alpha: glass.dark ? 0.30 : 0.16,
                            ),
                            palette.accent.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Filigrane de la matière, à peine visible, dans le coin.
                // Fondu radial depuis le coin : aucun bord net.
                Positioned(
                  top: 0,
                  right: 0,
                  width: 120,
                  height: 96,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (rect) => const RadialGradient(
                          center: Alignment.topRight,
                          radius: 1.0,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.15, 1.0],
                        ).createShader(rect),
                        // Peint plus large que la fenêtre : les bords du
                        // dessin restent hors champ.
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topRight,
                            minWidth: 180,
                            maxWidth: 180,
                            minHeight: 130,
                            maxHeight: 130,
                            child: CustomPaint(
                              size: const Size(180, 130),
                              painter: SubjectMotifPainter(
                                motif: identity.motif,
                                color: palette.accent.withValues(
                                  alpha: glass.dark ? 0.16 : 0.10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Reflet du bord supérieur.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 36,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            glass.highlight,
                            glass.highlight.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(IntelliaSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SubjectBadge(
                            identity: identity,
                            palette: palette,
                            size: 38,
                          ),
                          const Spacer(),
                          // Indique que la carte s'ouvre.
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(
                                alpha: glass.dark ? 0.22 : 0.10,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_outward_rounded,
                              size: 16,
                              color: palette.accent,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: IntelliaSpacing.xs),
                      Text(
                        name,
                        style: ContentText.title(color: glass.text, size: 17),
                      ),
                      if (subject.levelLabel.isNotEmpty)
                        Text(
                          subject.levelLabel,
                          style: ContentText.body(
                            color: glass.textSoft,
                            size: 12,
                            weight: FontWeight.w600,
                          ),
                        ),
                      if (match.context case final found?) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.learnHallFoundIn(found),
                          key: ValueKey('subject-hall-context-${subject.key}'),
                          style: ContentText.label(
                            color: palette.accent,
                            size: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: IntelliaSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: JourneyProgressBar(
                              value: subject.progress,
                              palette: palette,
                              height: 5,
                            ),
                          ),
                          const SizedBox(width: IntelliaSpacing.xs),
                          Text(
                            l10n.ljProgressPercent(subject.percent),
                            style: ContentText.math(
                              color: palette.accent,
                              size: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.lessonCount(subject.lessonCount),
                        style: ContentText.body(
                          color: glass.textSoft,
                          size: 12,
                          weight: FontWeight.w600,
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
    );
  }
}

/// Auras très douces (indigo, violet, bleu) derrière le Hall : le verre a
/// quelque chose à dépolir. Peintes une fois, jamais animées.
class SubjectHallAuras extends StatelessWidget {
  const SubjectHallAuras({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = learningBrightness(context) == Brightness.dark;
    Widget aura(Alignment alignment, Color color, double alpha) => Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: 0.9,
        heightFactor: 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: alpha),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              aura(
                const Alignment(-1.1, -0.55),
                IntelliaColors.brandIndigo,
                dark ? 0.30 : 0.16,
              ),
              aura(
                const Alignment(1.2, -0.05),
                const Color(0xFF8B5CF6),
                dark ? 0.24 : 0.13,
              ),
              aura(
                const Alignment(-0.6, 0.75),
                const Color(0xFF3B82F6),
                dark ? 0.22 : 0.11,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Signale, sous la recherche, que des contenus viennent d'arriver.
class NewContentNotice extends ConsumerWidget {
  const NewContentNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(contentSyncControllerProvider).valueOrNull;
    final fresh =
        sync != null && (sync.added.isNotEmpty || sync.updated.isNotEmpty);
    if (!fresh) return const SizedBox.shrink();
    final accent = _HallPalette.of(context).dark
        ? const Color(0xFFB4B2FF)
        : ContentPalette.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SubjectHallLayout.gutter,
        IntelliaSpacing.sm,
        SubjectHallLayout.gutter,
        0,
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          key: const ValueKey('content-new-available'),
          children: [
            Icon(Icons.auto_awesome_rounded, size: 18, color: accent),
            const SizedBox(width: IntelliaSpacing.xs),
            Expanded(
              child: Text(
                context.l10n.ceNewContentAvailable,
                style: ContentText.label(color: accent, size: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
