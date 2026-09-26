import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/flow_subject.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../application/flow_controller.dart';

/// Châssis plein écran commun à toutes les cartes du Flow.
///
/// Fond teinté par la matière, en-tête (chip matière + kicker), zone de
/// contenu et pied optionnel. Garantit une cohérence visuelle élégante.
class FlowCardScaffold extends ConsumerWidget {
  const FlowCardScaffold({
    required this.subject,
    required this.kicker,
    required this.child,
    this.footer,
    super.key,
  });

  final FlowSubject subject;
  final String kicker;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = subject.accent;
    // La provenance se lit ici plutôt que de traverser les dix vues de
    // cartes : le bandeau suit le catalogue, pas chaque appelant.
    final isDemo = ref.watch(flowCatalogProvider).valueOrNull?.isDemo ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond doux teinté par la matière.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                IntelliaColors.backgroundPremium,
                accent.withValues(alpha: 0.07),
                IntelliaColors.backgroundPrimary,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Deux halos à la couleur de la matière se posent à l'arrivée de la
        // carte (une fois) : le fond vit sans distraire la lecture.
        Positioned(
          top: -80,
          right: -60,
          child: _AmbientHalo(accent: accent, size: 240, alpha: 0.14),
        ),
        Positioned(
          bottom: -110,
          left: -90,
          child: _AmbientHalo(
            accent: accent,
            size: 280,
            alpha: 0.08,
            delay: const Duration(milliseconds: 160),
          ),
        ),
        SafeArea(
          child: Padding(
            // Marge haute : laisse respirer le HUD superposé par l'écran.
            padding: const EdgeInsets.fromLTRB(
              IntelliaSpacing.lg,
              72,
              IntelliaSpacing.lg,
              IntelliaSpacing.lg,
            ),
            child: SingleChildScrollView(
              key: const ValueKey('flow-content-scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _subjectChip(accent),
                      if (isDemo) _DemoContentBadge(accent: accent),
                      _kickerChip(accent),
                    ],
                  ).animate().fadeIn(duration: 360.ms),
                  const SizedBox(height: 24),
                  child,
                  if (footer != null) ...[const SizedBox(height: 16), footer!],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _subjectChip(Color accent) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(IntelliaRadii.full),
      border: Border.all(color: accent.withValues(alpha: 0.30)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(subject.icon, size: 15, color: accent),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            subject.label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _kickerChip(Color accent) => Text(
    kicker.toUpperCase(),
    style: GoogleFonts.montserrat(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: IntelliaColors.textTertiary,
    ),
  );
}

class _AmbientHalo extends StatelessWidget {
  const _AmbientHalo({
    required this.accent,
    required this.size,
    required this.alpha,
    this.delay = Duration.zero,
  });

  final Color accent;
  final double size;
  final double alpha;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final halo = IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              accent.withValues(alpha: alpha),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return halo;
    return halo
        .animate(delay: delay)
        .fadeIn(duration: 700.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: 900.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Dit à l'élève que ces cartes ne sont pas encore un contenu validé.
class _DemoContentBadge extends StatelessWidget {
  const _DemoContentBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.demoDataLabel;
    return Semantics(
      label: label,
      child: Container(
        key: const ValueKey('flow-demo-badge'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_rounded, size: 12, color: accent),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
