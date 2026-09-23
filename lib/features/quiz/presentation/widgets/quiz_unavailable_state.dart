import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/tab_section_header.dart';

/// Quiz sans quiz : l'écran reste un espace d'entraînement.
///
/// Même maison qu'Apprendre (en-tête, rayons, typographie), autre intention :
/// une « arène » aux couleurs de l'entraînement, une cible, et les deux modes
/// réels du Quiz, qui reviendront avec les quiz. Aucun détail technique n'est
/// montré à l'élève ; la cause est journalisée par l'appelant.
class QuizUnavailableState extends StatelessWidget {
  const QuizUnavailableState({
    required this.onRetry,
    required this.onContinuePath,
    this.message,
    this.offline = false,
    super.key,
  });

  final VoidCallback onRetry;
  final VoidCallback onContinuePath;

  /// Message ciblé (profil à compléter…) ; sinon le message par défaut.
  final String? message;
  final bool offline;

  static const arenaKey = ValueKey('quiz-unavailable-arena');

  /// Préfixe des clés des modes (`quiz-unavailable-mode-training` …).
  static const modeChipKeyPrefix = 'quiz-unavailable-mode-';

  static const _arenaStart = Color(0xFF0369A1);
  static const _arenaEnd = Color(0xFF1D4ED8);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body =
        message ??
        (offline ? l10n.quizUnavailableOfflineBody : l10n.quizUnavailableBody);
    return CustomScrollView(
      slivers: [
        StickyTabSectionHeader(
          key: const ValueKey('quiz-sticky-header'),
          eyebrow: l10n.studentSpace,
          title: l10n.quizTitle,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            IntelliaSpacing.md,
            IntelliaSpacing.lg,
            132,
          ),
          sliver: SliverToBoxAdapter(
            child: Container(
              key: arenaKey,
              padding: const EdgeInsets.all(IntelliaSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(IntelliaRadii.large),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_arenaStart, _arenaEnd],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ExcludeSemantics(child: _TargetBadge()),
                      const SizedBox(width: IntelliaSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.quizEyebrow.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: IntelliaSpacing.xxs),
                            Semantics(
                              header: true,
                              liveRegion: true,
                              child: Text(
                                l10n.quizUnavailableTitle,
                                style: GoogleFonts.manrope(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: IntelliaSpacing.sm),
                  Text(
                    body,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.md),
                  Text(
                    l10n.quizUnavailableModesLabel,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.xs),
                  Wrap(
                    spacing: IntelliaSpacing.xs,
                    runSpacing: IntelliaSpacing.xs,
                    children: [
                      _ModeChip(
                        key: const ValueKey('${modeChipKeyPrefix}training'),
                        icon: Icons.school_rounded,
                        label: l10n.quizModeTraining,
                      ),
                      _ModeChip(
                        key: const ValueKey('${modeChipKeyPrefix}exam'),
                        icon: Icons.assignment_turned_in_rounded,
                        label: l10n.quizModeExam,
                      ),
                    ],
                  ),
                  const SizedBox(height: IntelliaSpacing.lg),
                  Wrap(
                    spacing: IntelliaSpacing.sm,
                    runSpacing: IntelliaSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _arenaEnd,
                        ),
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(l10n.refreshLabel),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        onPressed: onContinuePath,
                        child: Text(l10n.continueWithFlow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: IntelliaSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cible à anneaux : le défi, sans animation ni lueur.
class _TargetBadge extends StatelessWidget {
  const _TargetBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(painter: _TargetPainter()),
    );
  }
}

class _TargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: 0.9);
    for (final fraction in [0.46, 0.30, 0.14]) {
      canvas.drawCircle(center, size.shortestSide * fraction, ring);
    }
    canvas.drawCircle(
      center,
      size.shortestSide * 0.05,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
