import 'package:flutter/material.dart';

/// Identifie le visuel animé associé à chaque slide.
///
/// Chaque valeur correspond fidèlement à une scène de l'onboarding de la
/// Web App INTELLIA237 (cartes en éventail, factorisation, chat, compagnons).
enum OnboardingVisual { cards, math, chat, companions }

/// Données d'une slide d'onboarding (reconstruction fidèle de la Web App).
class OnboardingSlideData {
  const OnboardingSlideData({
    required this.id,
    required this.title,
    required this.description,
    required this.visual,
    required this.accentColor,
  });

  /// Identifiant stable (aligné sur la Web App : learn / math / english / companion).
  final String id;

  /// Titre de la slide (narration — verbatim Web).
  final String title;

  /// Sous-titre / description (narration — verbatim Web).
  final String description;

  /// Le visuel animé à afficher.
  final OnboardingVisual visual;

  /// Couleur d'accent qui pilote le halo ambiant et la barre de progression.
  final Color accentColor;
}
