import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/app_theme.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/student_home/data/student_link_code_service.dart';
import 'package:intellia237/features/student_home/presentation/widgets/student_link_code_card.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

class _FakeLinkCodeService extends StudentLinkCodeService {
  @override
  Future<String> ensureLinkCode() async => 'ABCD2345';
}

const _viewport = Size(360, 1200);

Future<void> _pump(WidgetTester tester, {required double textScale}) async {
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentLinkCodeServiceProvider.overrideWithValue(
          _FakeLinkCodeService(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: _viewport,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: const Scaffold(
            body: TabSurface(
              palette: TabPalette(TabPresentationMode.embeddedLight),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(12),
                child: StudentLinkCodeCard(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  for (final scale in const [1.0, 1.5]) {
    testWidgets('Mon code parent affiche le code à 360px @${scale}x', (
      tester,
    ) async {
      await _pump(tester, textScale: scale);

      expect(find.text('Mon code parent'), findsOneWidget);
      expect(find.byKey(const ValueKey('student-link-code-value')), findsOneWidget);
      expect(find.text('ABCD2345'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
