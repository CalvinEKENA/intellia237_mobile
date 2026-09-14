import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/data/educational_media_service.dart';
import 'package:intellia237/features/admin/domain/educational_media.dart';
import 'package:intellia237/features/learn/presentation/widgets/lesson_pdf_view.dart';

class _StubMediaProvider implements EducationalMediaProvider {
  _StubMediaProvider({this.fail = false});
  final bool fail;
  int resolveCount = 0;

  @override
  Future<String> resolveUrl(String storagePath) async {
    resolveCount++;
    if (fail) throw Exception('offline');
    return 'https://signed.example/$storagePath?token=short-lived';
  }

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

Future<void> _pump(
  WidgetTester tester, {
  required EducationalMediaProvider provider,
  required Future<bool> Function(Uri) launcher,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [educationalMediaProviderProvider.overrideWithValue(provider)],
      child: MaterialApp(
        home: Scaffold(
          body: LessonPdfView(
            storagePath: 'assets/doc.pdf',
            caption: 'Fiche de révision',
            launcher: launcher,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('opens a freshly resolved signed URL (never a stored one)', (
    tester,
  ) async {
    final provider = _StubMediaProvider();
    Uri? launched;
    await _pump(
      tester,
      provider: provider,
      launcher: (uri) async {
        launched = uri;
        return true;
      },
    );

    expect(find.text('Fiche de révision'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lesson-pdf-open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(provider.resolveCount, 1);
    expect(launched.toString(), contains('token=short-lived'));
    expect(find.byKey(const ValueKey('lesson-pdf-error')), findsNothing);
  });

  testWidgets('shows an error and a retry when resolution fails', (
    tester,
  ) async {
    await _pump(
      tester,
      provider: _StubMediaProvider(fail: true),
      launcher: (uri) async => true,
    );
    await tester.tap(find.byKey(const ValueKey('lesson-pdf-open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('lesson-pdf-error')), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('a failed launch surfaces an explicit error', (tester) async {
    await _pump(
      tester,
      provider: _StubMediaProvider(),
      launcher: (uri) async => false,
    );
    await tester.tap(find.byKey(const ValueKey('lesson-pdf-open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('lesson-pdf-error')), findsOneWidget);
  });
}
