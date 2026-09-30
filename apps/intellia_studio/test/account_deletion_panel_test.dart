import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia_studio/features/audit/presentation/account_deletion_requests_panel.dart';

void main() {
  testWidgets(
    'deletion requests needing a human come first, without personal data',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountDeletionRequestsProvider.overrideWith(
              (ref) async => const [
                AccountDeletionRequestView(
                  uid: 'stu-stuck',
                  role: 'student',
                  status: 'needs_attention',
                  dueAt: null,
                  attempts: 5,
                  lastErrorCode: 'auth/internal-error',
                ),
                AccountDeletionRequestView(
                  uid: 'parent-due',
                  role: 'parent',
                  status: 'scheduled',
                  dueAt: '2026-09-28T10:00:00.000Z',
                  attempts: 0,
                  lastErrorCode: null,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AccountDeletionRequestsPanel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Demandes de suppression de compte'), findsOneWidget);
      expect(find.text('INTERVENTION REQUISE'), findsOneWidget);
      expect(find.text('PROGRAMMÉE'), findsOneWidget);
      expect(find.textContaining('auth/internal-error'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('stu-stuck')).dy,
        lessThan(tester.getTopLeft(find.text('parent-due')).dy),
      );
    },
  );

  test('every server status has a readable label', () {
    for (final status in [
      'scheduled',
      'cancelled',
      'processing',
      'failed',
      'needs_attention',
      'completed',
    ]) {
      expect(accountDeletionStatusLabel(status), isNot(status.toUpperCase()));
    }
  });
}
