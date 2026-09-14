import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/system/intellia_system_bars.dart';

void main() {
  group('IntelliaSystemBarPolicy', () {
    test('dark-surface routes get light status-bar icons', () {
      for (final location in [
        AppRoutes.onboarding,
        AppRoutes.learnHub,
        AppRoutes.quizPlay('q1'),
        AppRoutes.quizResult,
        AppRoutes.aiCompanion,
      ]) {
        expect(
          IntelliaSystemBarPolicy.toneForLocation(location),
          SystemSurfaceTone.dark,
          reason: location,
        );
      }
    });

    test('ordinary light screens get dark status-bar icons', () {
      for (final location in [
        AppRoutes.studentHome,
        AppRoutes.parentHome,
        AppRoutes.adminHome,
        AppRoutes.flow,
        AppRoutes.settings,
      ]) {
        expect(
          IntelliaSystemBarPolicy.toneForLocation(location),
          SystemSurfaceTone.light,
          reason: location,
        );
      }
    });

    test('no tone ever hides the status bar; both keep readable contrast', () {
      for (final tone in SystemSurfaceTone.values) {
        final style = IntelliaSystemBarPolicy.styleFor(tone);
        // Barre d'état transparente (bord-à-bord) mais JAMAIS masquée, avec une
        // brillance d'icônes définie → heure/réseau/batterie toujours lisibles.
        expect(style.statusBarColor, Colors.transparent);
        expect(style.statusBarIconBrightness, isNotNull);
      }
      // Le contraste des icônes s'inverse entre surfaces claires et sombres.
      expect(
        IntelliaSystemBarPolicy.styleFor(
          SystemSurfaceTone.light,
        ).statusBarIconBrightness,
        Brightness.dark,
      );
      expect(
        IntelliaSystemBarPolicy.styleFor(
          SystemSurfaceTone.dark,
        ).statusBarIconBrightness,
        Brightness.light,
      );
    });
  });
}
