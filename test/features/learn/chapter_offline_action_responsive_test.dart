import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/app_theme.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/learn/presentation/chapter_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final localeCase
      in const <({String title, String subtitle, String action})>[
        (
          title: 'Étudier sans réseau',
          subtitle: 'Prépare les 10 leçons de ce chapitre sur cet appareil.',
          action: 'Préparer',
        ),
        (
          title: 'Study without an internet connection',
          subtitle: 'Prepare all 10 lessons in this chapter for offline study.',
          action: 'Prepare offline',
        ),
      ]) {
    testWidgets(
      'offline chapter action remains editorial for ${localeCase.title}',
      (tester) async {
        for (final width in const [
          320.0,
          360.0,
          375.0,
          390.0,
          412.0,
          480.0,
          768.0,
        ]) {
          for (final scale in const [1.0, 1.3, 1.5, 2.0]) {
            tester.view.physicalSize = Size(width, 700);
            tester.view.devicePixelRatio = 1;

            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 700),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: Scaffold(
                    body: TabSurface(
                      palette: const TabPalette(
                        TabPresentationMode.embeddedLight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ChapterOfflineActionCard(
                            saved: false,
                            busy: false,
                            title: localeCase.title,
                            subtitle: localeCase.subtitle,
                            actionLabel: localeCase.action,
                            actionEnabled: true,
                            onAction: () {},
                            onRemove: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 250));

            final title = find.byKey(const ValueKey('offline-chapter-title'));
            final subtitle = find.byKey(
              const ValueKey('offline-chapter-subtitle'),
            );
            final action = find.byKey(const ValueKey('offline-chapter-action'));
            final card = find.byKey(const ValueKey('offline-chapter-card'));

            expect(title, findsOneWidget);
            expect(subtitle, findsOneWidget);
            expect(action, findsOneWidget);
            expect(
              tester.getSize(title).width,
              greaterThan(200),
              reason: 'title width at $width px / text scale $scale',
            );
            expect(
              tester.getSize(subtitle).width,
              greaterThan(200),
              reason: 'subtitle width at $width px / text scale $scale',
            );
            expect(
              tester.getSize(card).height,
              lessThan(scale <= 1.5 ? 500 : 650),
              reason: 'card height at $width px / text scale $scale',
            );
            final actionRect = tester.getRect(action);
            expect(actionRect.left, greaterThanOrEqualTo(0));
            expect(actionRect.right, lessThanOrEqualTo(width));
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  }

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearAllTestValues();
  });
}
