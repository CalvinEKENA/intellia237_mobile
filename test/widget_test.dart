import 'package:edunova/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders app shell after bootstrap', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EduNovaApp()));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(Scaffold), findsWidgets);
  });
}
