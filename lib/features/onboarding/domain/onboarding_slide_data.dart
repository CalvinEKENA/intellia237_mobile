import 'package:flutter/material.dart';

/// Données d'une slide d'onboarding.
class OnboardingSlideData {
  const OnboardingSlideData({
    required this.title,
    required this.description,
    required this.asset,
    this.icon = Icons.auto_awesome_rounded,
    this.accentColor = const Color(0xFF1451E1),
  });

  final String title;
  final String description;

  /// Chemin vers une image ou un fichier Lottie (placeholder supporté).
  final String asset;

  /// Icône affichée dans le cercle héroïque.
  final IconData icon;

  /// Couleur d'accent de la slide.
  final Color accentColor;
}
