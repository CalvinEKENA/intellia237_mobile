import 'package:edunova/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('creates light and dark app themes with page transitions', (
    _,
  ) async {
    late final ThemeData lightTheme;
    late final ThemeData darkTheme;

    expect(() => lightTheme = AppTheme.light, returnsNormally);
    expect(() => darkTheme = AppTheme.dark, returnsNormally);

    expect(lightTheme.brightness, Brightness.light);
    expect(darkTheme.brightness, Brightness.dark);
    expect(lightTheme.pageTransitionsTheme, isA<PageTransitionsTheme>());
    expect(darkTheme.pageTransitionsTheme, isA<PageTransitionsTheme>());
    expect(
      lightTheme.pageTransitionsTheme.builders,
      containsPair(TargetPlatform.iOS, isA<PageTransitionsBuilder>()),
    );
    expect(
      lightTheme.pageTransitionsTheme.builders,
      containsPair(TargetPlatform.android, isA<PageTransitionsBuilder>()),
    );
  });
}
