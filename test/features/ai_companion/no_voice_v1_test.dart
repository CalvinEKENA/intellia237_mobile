import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/ai_companion/presentation/widgets/companion_composer.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// V1 sans voix (décision propriétaire, réduction des coûts) : ni micro, ni
/// dictée, ni lecture à voix haute, ni permission audio.
void main() {
  testWidgets('the composer writes and sends, never listens', (tester) async {
    final controller = TextEditingController();
    var sent = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: CompanionComposer(
            controller: controller,
            onSubmit: () => sent++,
            enabled: true,
            companionName: 'Kira',
            accentColor: Colors.indigo,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
    expect(find.byIcon(Icons.mic_rounded), findsNothing);
    expect(find.text('Parler'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('companion-send')));
    expect(sent, 0, reason: 'nothing to send yet');
    await tester.enterText(find.byType(TextField), 'Explique-moi Thalès');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('companion-send')));
    expect(sent, 1);
  });

  test('no voice dependency, permission or string ships in V1', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final dependency in ['speech_to_text', 'flutter_tts', 'record:']) {
      expect(pubspec, isNot(contains(dependency)), reason: dependency);
    }
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    for (final entry in [
      'RECORD_AUDIO',
      'MODIFY_AUDIO_SETTINGS',
      'android.speech.RecognitionService',
      'TTS_SERVICE',
    ]) {
      expect(manifest, isNot(contains(entry)), reason: entry);
    }
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, isNot(contains('NSMicrophoneUsageDescription')));
    expect(plist, isNot(contains('NSSpeechRecognitionUsageDescription')));
    final arb = File('lib/l10n/app_fr.arb').readAsStringSync();
    for (final key in [
      '"companionSpeak"',
      '"companionListen"',
      '"companionMicRationale"',
      '"companionDictationFailed"',
    ]) {
      expect(arb, isNot(contains(key)), reason: key);
    }
  });
}
