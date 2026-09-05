import 'package:flutter/material.dart';

/// Design tokens and styling constants for INTELLIA Campus.
///
/// Designed as a premium institutional pedagogical command center:
/// - White / ivory surfaces
/// - Graphite typography
/// - INTELLIA Blue as restrained accent
/// - Generous whitespace and quiet depth
abstract final class CampusTokens {
  // Surfaces
  static const Color campusBackground = Color(0xFFF7F9FC);
  static const Color campusSurface = Color(0xFFFFFFFF);
  static const Color campusSurfaceSubtle = Color(0xFFF1F5F9);
  static const Color campusSidebar = Color(
    0xFF0F172A,
  ); // Deep institutional slate
  static const Color campusSidebarItemHover = Color(0xFF1E293B);

  // Borders and Dividers
  static const Color campusDivider = Color(0xFFE2E8F0);
  static const Color campusBorderStrong = Color(0xFFCBD5E1);

  // Graphite Typography
  static const Color campusGraphite = Color(0xFF0F172A);
  static const Color campusGraphiteSecondary = Color(0xFF475569);
  static const Color campusGraphiteMuted = Color(0xFF94A3B8);

  // INTELLIA Blue Accents
  static const Color campusBlueAccent = Color(0xFF004080);
  static const Color campusBlueHover = Color(0xFF003366);
  static const Color campusBlueLight = Color(0xFFEBF3FC);

  // Status & Learning Evidence
  static const Color masterySolid = Color(0xFF0D9488); // Teal
  static const Color masteryWellUnderstood = Color(0xFF2563EB); // Blue
  static const Color masteryConstructing = Color(0xFFD97706); // Amber
  static const Color masteryInsufficient = Color(0xFF64748B); // Slate

  static const Color severityCritical = Color(0xFFDC2626);
  static const Color severityWarning = Color(0xFFD97706);
  static const Color severityInfo = Color(0xFF2563EB);

  // Shadows
  static const List<BoxShadow> subtleCardShadow = [
    BoxShadow(
      color: Color(0x0A000000), // Very light 4% shadow
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevatedDialogShadow = [
    BoxShadow(
      color: Color(0x14000000), // 8% shadow
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}
