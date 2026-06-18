import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

/// Barre de progression segmentée (remplace les dots).
/// Affiche N segments : les complétés sont blancs à 60%,
/// le segment actif s'anime de gauche à droite en 6s,
/// les segments futurs sont blancs à 20%.
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    required this.totalSlides,
    required this.currentSlide,
    required this.progress,
    required this.accentColor,
    super.key,
  });

  final int totalSlides;
  final int currentSlide;
  final double progress; // 0.0 → 1.0 pour la slide courante
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSlides, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < totalSlides - 1 ? 4 : 0),
            child: _ProgressSegment(
              state: index < currentSlide
                  ? _SegmentState.completed
                  : index == currentSlide
                  ? _SegmentState.active
                  : _SegmentState.upcoming,
              progress: index == currentSlide ? progress : 1.0,
              accentColor: accentColor,
            ),
          ),
        );
      }),
    );
  }
}

enum _SegmentState { completed, active, upcoming }

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({
    required this.state,
    required this.progress,
    required this.accentColor,
  });

  final _SegmentState state;
  final double progress;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1.5),
        child: Stack(
          children: [
            // Track (fond)
            Container(
              color: Colors.white.withValues(
                alpha: state == _SegmentState.upcoming ? 0.20 : 0.35,
              ),
            ),
            // Remplissage
            if (state == _SegmentState.completed)
              Container(color: Colors.white.withValues(alpha: 0.65))
            else if (state == _SegmentState.active)
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
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

// Conservé pour compatibilité si d'autres fichiers l'importent encore.
@Deprecated('Utilisez OnboardingProgressBar à la place')
class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({
    required this.totalPages,
    required this.currentPage,
    super.key,
  });

  final int totalPages;
  final double currentPage;

  @override
  Widget build(BuildContext context) {
    return OnboardingProgressBar(
      totalSlides: totalPages,
      currentSlide: currentPage.round(),
      progress: currentPage - currentPage.floor(),
      accentColor: AppColors.brand,
    );
  }
}
