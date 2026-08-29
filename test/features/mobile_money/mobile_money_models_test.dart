import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/mobile_money/domain/mobile_money_models.dart';

void main() {
  test('parses an offer projected by the authenticated callable', () {
    final overview = MobileMoneyOverview.fromMap({
      'availability': 'available',
      'offer': {
        'id': 'school-a',
        'establishmentId': 'school-a',
        'title': 'Accès famille',
        'description': 'Accès aux services pédagogiques',
        'amountXaf': 5000,
        'durationDays': 30,
        'operators': [
          {
            'code': 'operator-a',
            'label': 'Opérateur A',
            'recipientPhone': '+237600000000',
          },
        ],
      },
      'recentRequests': [
        {
          'requestId': 'request-a',
          'offerTitle': 'Accès famille',
          'amountXaf': 5000,
          'operatorLabel': 'Opérateur A',
          'status': 'pending',
          'referenceHint': '••••1234',
          'submittedAt': '2026-07-16T12:00:00.000Z',
        },
      ],
    });

    expect(overview.availability, MobileMoneyAvailability.available);
    expect(overview.offer?.amountXaf, 5000);
    expect(overview.offer?.operators.single.code, 'operator-a');
    expect(
      overview.recentRequests.single.status,
      MobileMoneyPaymentStatus.pending,
    );
    expect(overview.recentRequests.single.referenceHint, '••••1234');
  });

  test(
    'uses an explicit unavailable state when server configuration is absent',
    () {
      final overview = MobileMoneyOverview.fromMap({
        'availability': 'not_configured',
        'offer': null,
        'recentRequests': <Object>[],
      });

      expect(overview.availability, MobileMoneyAvailability.notConfigured);
      expect(overview.offer, isNull);
      expect(overview.recentRequests, isEmpty);
    },
  );

  test('formats school-context prices in FCFA', () {
    expect(formatXaf(5000), '5 000 FCFA');
    expect(formatXaf(125000), '125 000 FCFA');
  });
}
