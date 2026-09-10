import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the faces the product actually ships.
///
/// The authentication and onboarding surfaces are laid out with a condensed
/// display face. Measuring them against the test fallback font describes a
/// different design: titles wrap where they never would on a device, and a
/// primary action can appear to fall below the fold when it does not.
Future<void> loadIntelliaFonts() async {
  for (final family in const {
    'BarlowCondensed': [
      'BarlowCondensed-ExtraBold.ttf',
      'BarlowCondensed-Black.ttf',
    ],
    'CampaignBody': [
      'Manrope-400.ttf',
      'Manrope-600.ttf',
      'Manrope-700.ttf',
      'Manrope-800.ttf',
    ],
  }.entries) {
    final loader = FontLoader(family.key);
    for (final asset in family.value) {
      loader.addFont(rootBundle.load('assets/fonts/$asset'));
    }
    await loader.load();
  }
}
