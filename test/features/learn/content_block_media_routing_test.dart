import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/data/educational_media_service.dart';
import 'package:intellia237/features/admin/domain/educational_media.dart';
import 'package:intellia237/features/learn/domain/content_block.dart';
import 'package:intellia237/features/learn/presentation/widgets/audio_overview_player.dart';
import 'package:intellia237/features/learn/presentation/widgets/content_block_view.dart';
import 'package:intellia237/features/learn/presentation/widgets/lesson_pdf_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubMediaProvider implements EducationalMediaProvider {
  @override
  Future<String> resolveUrl(String storagePath) async =>
      'https://x/$storagePath';
  @override
  Future<MediaUploadResult> upload({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async => throw UnimplementedError();
  @override
  Future<void> delete(String storagePath) async {}
}

class _FakeEngine implements AudioEngine {
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Future<void> load(String url) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> dispose() async {}
}

Future<void> _pump(WidgetTester tester, ContentBlock block) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        educationalMediaProviderProvider.overrideWithValue(
          _StubMediaProvider(),
        ),
        audioEngineProvider.overrideWithValue(_FakeEngine()),
      ],
      child: MaterialApp(
        home: Scaffold(body: ContentBlockView(block: block)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('an audio block renders the real player, not a placeholder', (
    tester,
  ) async {
    await _pump(
      tester,
      const MediaBlock(
        id: 'm1',
        order: 0,
        mediaType: MediaType.audio,
        storagePath: 'assets/audio.mp3',
        caption: 'Capsule',
      ),
    );
    expect(find.byType(AudioOverviewPlayer), findsOneWidget);
  });

  testWidgets('a pdf block renders the secure PDF view', (tester) async {
    await _pump(
      tester,
      const MediaBlock(
        id: 'm2',
        order: 0,
        mediaType: MediaType.pdf,
        storagePath: 'assets/doc.pdf',
        caption: 'Fiche',
      ),
    );
    expect(find.byType(LessonPdfView), findsOneWidget);
    expect(find.byKey(const ValueKey('lesson-pdf-open')), findsOneWidget);
  });
}
