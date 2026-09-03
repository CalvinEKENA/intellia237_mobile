import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/router/app_routes.dart';

enum SystemSurfaceTone { light, dark }

abstract final class IntelliaSystemBarPolicy {
  static SystemSurfaceTone toneForLocation(String location) {
    if (location == AppRoutes.onboarding ||
        location == AppRoutes.learnHub ||
        location.startsWith('${AppRoutes.quizHub}/play/') ||
        location == AppRoutes.quizResult ||
        location.startsWith(AppRoutes.aiCompanion)) {
      return SystemSurfaceTone.dark;
    }
    return SystemSurfaceTone.light;
  }

  static SystemUiOverlayStyle styleFor(SystemSurfaceTone tone) {
    return switch (tone) {
      SystemSurfaceTone.light => const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFBF8F1),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Color(0xFFE4DED2),
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      SystemSurfaceTone.dark => const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF060E22),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Color(0xFF060E22),
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
    };
  }
}

class IntelliaSystemBars extends StatelessWidget {
  const IntelliaSystemBars({
    required this.child,
    required this.tone,
    super.key,
  });

  final Widget child;
  final SystemSurfaceTone tone;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: IntelliaSystemBarPolicy.styleFor(tone),
      sized: false,
      child: child,
    );
  }
}
