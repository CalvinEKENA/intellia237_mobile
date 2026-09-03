import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/system/intellia_system_bars.dart';

void main() {
  test('major light and dark route families use readable system icons', () {
    const darkRoutes = <String>[
      AppRoutes.onboarding,
      AppRoutes.learnHub,
      '${AppRoutes.quizHub}/play/quiz-1',
      AppRoutes.quizResult,
      AppRoutes.aiCompanion,
    ];
    const lightRoutes = <String>[
      AppRoutes.phoneAuth,
      AppRoutes.studentRegistration,
      AppRoutes.parentRegistration,
      AppRoutes.studentHome,
      AppRoutes.editProfile,
      AppRoutes.settings,
    ];

    for (final route in darkRoutes) {
      expect(
        IntelliaSystemBarPolicy.toneForLocation(route),
        SystemSurfaceTone.dark,
      );
      expect(
        IntelliaSystemBarPolicy.styleFor(
          SystemSurfaceTone.dark,
        ).statusBarIconBrightness,
        Brightness.light,
      );
    }
    for (final route in lightRoutes) {
      expect(
        IntelliaSystemBarPolicy.toneForLocation(route),
        SystemSurfaceTone.light,
      );
      expect(
        IntelliaSystemBarPolicy.styleFor(
          SystemSurfaceTone.light,
        ).statusBarIconBrightness,
        Brightness.dark,
      );
    }
  });
}
